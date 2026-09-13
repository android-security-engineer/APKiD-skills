# 工作原理

<span class="badge badge-info">原理</span>
<span class="badge badge-info">YARA</span>
<span class="badge badge-info">ZIP 递归</span>

APKiD 的核心是一条流水线：**判断文件类型 → 加载 YARA 规则 → 匹配指纹 →（若是 ZIP）解包递归 → 结构化输出**。本文拆解每一步。

## 🔧 核心依赖：yara-python-dex

APKiD 不用普通的 `yara-python`，而用 **[yara-python-dex](https://github.com/rednaga/yara-python-dex)**——一个带 DEX 模块的 YARA 分支。DEX 模块（`import "dex"`）让规则能直接访问 DEX 结构字段，例如：

```yara
import "dex"

rule dx_map_type_order {
  condition:
    dex.map_list.map_item[7].type == 0x2001  // TYPE_CODE_ITEM
    and dex.map_list.map_item[8].type == 0x1001  // TYPE_TYPE_LIST
}
```

正是有了这个模块，APKiD 才能通过 DEX 的 `map_list` 类型排列顺序来区分 `dx`、`r8`、`dexlib2` 等编译器——它们生成的 map 顺序各不相同。详见 [编译器指纹](../rules/dex-compilers)。

## 📂 文件类型识别：魔数判定

扫描的第一步是判断"这文件该不该扫"。`apkid.apkid.SCANNABLE_FILE_MAGICS` 定义了支持的文件类型及其魔数：

| 类型 | 魔数 | 说明 |
|------|------|------|
| `zip` | `PK\x03\x04` / `PK\x05\x06` / `PK\x07\x08` | APK/JAR/ZIP |
| `dex` | `dex\n` / `dey\n` | Dalvik 字节码 |
| `elf` | `\x7fELF` | 原生 so 库、可执行文件 |
| `res` | `\x02\x00\x0c\x00` | 二进制资源（如 `resources.arsc`） |
| `dll` | `MZ\x90\x00` | Windows PE DLL |

判定只读前 4 字节，开销极小。`Scanner._type_file()` 返回类型字符串或 `None`。

`Options.typing` 控制判定策略：

- `"magic"`（默认）：只扫描魔数匹配的文件。**性能与准确性的折中**——不浪费力气解压图片等无关条目。
- `"filename"`：按文件名扩展名判断（`.dex`、`.so`、`AndroidManifest.xml`、`lib/` 等）。更快但可能漏掉改名文件（如 `notmalware.gif` 实为 dex）。
- `None`：所有文件都喂给 YARA。最彻底但最慢，且容易踩到 zip bomb。

## 🔄 ZIP 递归扫描

APK 本质是 ZIP。`Scanner.scan_file_obj()` 的逻辑：

1. 读取整个文件，调 `self.rules.match()` 匹配外层规则。
2. 若判定为 ZIP，用 `zipfile.ZipFile` 打开，遍历条目。
3. 对每个条目 `_scan_zip_entry()`：
   - 读前 4 字节判断是否值得扫描（魔数判定）。
   - 读全量内容，匹配规则。
   - 若该条目本身又是 ZIP（嵌套），递归——**深度受 `Options.scan_depth` 限制**（默认 2）。
4. 命名约定：嵌套条目的结果键为 `外层!内层!...`，例如 `app.apk!classes.dex`。

### XZ 压缩支持

Python 标准库 `zipfile` 不支持 XZ 压缩（`compress_type == 95`），会抛 `NotImplementedError`。APKiD 在 `_scan_zip_entry()` 里手动处理：

```python
if info.compress_type == XZ_COMPRESSION_TYPE:
    # 手动解析 Local File Header，定位数据偏移
    raw_zip.seek(info.header_offset + ZIP_LFH_FIELDS_SIZE)
    filename_len = struct.unpack('<H', raw_zip.read(2))[0]
    extra_len = struct.unpack('<H', raw_zip.read(2))[0]
    data_offset = info.header_offset + ZIP_LFH_HEADER_SIZE + filename_len + extra_len
    raw_zip.seek(data_offset)
    decompressed_data = lzma.decompress(raw_zip.read(info.compress_size))
```

这让 APKiD 能扫到用 XZ 压缩的 dex/so 条目。

### ZIP 炸弹防护

`_scan_zip_entry()` 捕获 `BadZipFile` 中的 `"Overlapped entries"` 和 `"possible zip bomb"`，跳过该条目而非崩溃。配合 `scan_depth` 限制递归深度，防止恶意嵌套 ZIP 耗尽内存。

## 📜 规则加载：RulesManager

[`apkid.rules.RulesManager`](../modules/rules) 负责 YARA 规则的编译、保存、加载：

- **源规则**：`apkid/rules/` 下的 `.yara` 文件，按文件类型分子目录（`apk/`、`dex/`、`elf/`、`dll/`、`res/`）。
- **编译产物**：`rules.yarc`——编译后的二进制规则集，**gitignored**，由 `prep-release.py` 生成。
- **加载**：`yara.load(self.rules_path)`，比每次重新编译快得多。
- **哈希**：`RulesManager.hash` 对所有源规则文件算 SHA-256，作为规则集指纹，写进输出里供溯源。

```python
class RulesManager:
    def load(self) -> yara.Rules:
        self.rules = yara.load(self.rules_path)   # 加载 rules.yarc
        return self.rules

    def compile(self) -> yara.Rules:
        return yara.compile(filepaths=self._collect_yara_files())  # 编译源文件

    def save(self) -> int:
        self.rules.save(self.rules_path)   # 写出 rules.yarc
        return len(set(r.identifier for r in self.rules))
```

## 📤 输出格式化

扫描结果是 `Dict[str, List[yara.Match]]`（键是文件路径，值是 YARA 匹配列表）。两条输出路径：

- **经典输出** [`OutputFormatter`](../modules/output)：彩色终端表格或 JSON，键为文件名，值为 `{tags: [描述...]}`。
- **AI 输出** [`AIOutputFormatter`](../modules/ai-output)：把每个 `Match` 拆成带 `category`/`identifier`/`confidence`/`source` 的 finding，汇总成 `summary`。详见 [AI 输出格式](./output-format)。

### 置信度推断

`AIOutputFormatter._infer_confidence()` 根据命中来源推断可信度：

| 来源 | 置信度 | 含义 |
|------|--------|------|
| `*.dex` / 含 `.dex` | `high` | DEX 字节码级匹配，最可靠 |
| `*.so` / 含 `.so` | `medium` | 原生库符号/节区匹配 |
| `*.apk`/`.zip`/`.jar` | `low` | APK 层路径匹配，可能是壳的壳 |
| `*.elf` | `medium` | 直接 ELF 文件 |
| 其它 | `medium` | 未知来源默认中等 |

## 🧪 整体流程图

```
            ┌──────────────────────────────────────────┐
            │  apkid-ai-cli scan app.apk                │
            └──────────────────┬───────────────────────┘
                               ▼
            ┌──────────────────────────────────────────┐
            │  common.make_scanner()                    │
            │  ├─ RulesManager().load() → yara.Rules    │
            │  └─ Options(typing='magic', scan_depth=2) │
            └──────────────────┬───────────────────────┘
                               ▼
            ┌──────────────────────────────────────────┐
            │  Scanner.scan_file('app.apk')             │
            │  ├─ 读魔数 → 'zip'                         │
            │  ├─ rules.match(整个文件)                   │
            │  └─ 是 zip → _scan_zip()                  │
            └──────────────────┬───────────────────────┘
                               ▼
            ┌──────────────────────────────────────────┐
            │  遍历 ZIP 条目                              │
            │  ├─ classes.dex → rules.match → 命中 dx    │
            │  ├─ lib/arm64/libfoo.so → rules.match → OLLVM │
            │  └─ assets/libjiagu.so → 命中 jiagu_native │
            └──────────────────┬───────────────────────┘
                               ▼
            ┌──────────────────────────────────────────┐
            │  AIOutputFormatter.format()               │
            │  → {schema_version, findings[], summary}  │
            └──────────────────────────────────────────┘
```

## 📍 下一步

- [架构概览](./architecture) — 三种接口如何复用这套引擎。
- [扫描深度与递归](./scan-depth) — `scan_depth` 怎么调。
- [代码模块：apkid.py](../modules/core-apkid) — 引擎源码逐行讲解。
