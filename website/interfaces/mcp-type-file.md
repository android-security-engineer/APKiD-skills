# type_file — 识别文件类型

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">FastMCP</span>
<span class="badge badge-file">file_type</span>
<span class="badge badge-warning">轻量</span>

🔢 `type_file` 只读文件前 4 字节魔数，判定它是不是 APK/DEX/ELF 等 Android 二进制。**不加载 YARA 规则**，开销极小（毫秒级），适合在扫描前快速探类型。

## 📋 工具签名

```
type_file(target) → JSON 字符串
```

## 📑 参数表

| 参数 | 类型 | 默认 | 必填 | 说明 |
|------|------|------|:----:|------|
| `target` | `str` | — | ✅ | 待识别的文件路径 |

`type_file` 是 8 个 MCP 工具里 **参数最少** 的——只有一个 `target`，没有任何扫描选项。因为它根本不扫描，只读魔数。

## 🔧 设计要点：唯一不调 `make_scanner`

```python
if not Path(target).exists():
    return json.dumps({"error": True, "message": f"File not found: {target}"})
with open(target, "rb") as f:
    detected = Scanner._type_file(f)
if detected is None:
    return json.dumps({"error": False, "file": target, "type": None, "message": "Unknown file type ..."})
return json.dumps({"error": False, "file": target, "type": detected,
                   "supported_types": sorted(SCANNABLE_FILE_MAGICS.keys())}, ...)
```

关键点：

- **不调 `make_scanner`**：这是 4 个扫描类工具里 **唯一** 不构造 Scanner 的。它直接调 `Scanner._type_file(f)`——一个 `@staticmethod`，只读 4 字节比对魔数集合。
- **不需要 `rules.yarc`**：因为不加载 YARA，所以即使 `rules.yarc` 缺失也能正常工作。这是它与 `scan_file`/`batch_scan`/`diff_files` 的重要区别——那三个工具没规则文件会失败。
- **`typing`/`scan_depth` 等参数无效**：类型识别只看魔数，不看文件名、不递归，所以这些参数不存在。
- **与 CLI `type` 完全一致**：识别逻辑、返回结构都对应 [`type`](./ai-cli-type) 命令。

魔数判定逻辑（[`Scanner._type_file`](../modules/core-apkid)）：

```python
@staticmethod
def _type_file(file: IO) -> Union[None, str]:
    magic = file.read(4)
    file.seek(0)
    for file_type, magics in SCANNABLE_FILE_MAGICS.items():
        if magic in magics:
            return file_type
    return None
```

支持的类型定义在 `SCANNABLE_FILE_MAGICS`，详见 [文件类型识别](../guide/file-types)。

## 📤 返回示例

### 识别成功

```json
{
  "error": false,
  "file": "/path/to/classes.dex",
  "type": "dex",
  "supported_types": ["dex", "dll", "elf", "res", "zip"]
}
```

`supported_types` 是当前 APKiD 能识别的所有类型（排序后），让客户端知道"还有哪些类型可识别"。

### 不识别（type 为 null）

```json
{
  "error": false,
  "file": "/path/to/random.bin",
  "type": null,
  "message": "Unknown file type — not a recognized Android binary format"
}
```

::: warning `type:null` 不是错误
注意 `error:false`——文件能读到、魔数也读了，只是不在支持列表里。这是合法的"无法识别"响应，**不是** 失败。客户端应据此跳过该文件，不调 `scan_file`。别把 `type:null` 当 error 处理。
:::

### 文件不存在

```json
{ "error": true, "message": "File not found: /path/to/missing.bin" }
```

## 🤖 在 Claude 里的使用

> 这个文件 /home/user/mystery.file 是什么类型？是 Android 二进制吗？

Claude 调 `type_file`，秒回：

> 它的魔数是 `dex\n`，是 DEX 文件（Dalvik 字节码）。可以进一步扫描。

如果 `type` 为 `null`：

> 这个文件不是 APKiD 支持的 Android 二进制格式（不是 APK/DEX/ELF/RES/DLL），扫描它没意义。

::: tip 推荐的"先探类型再扫描"流程
让 Claude 先调 `type_file`（毫秒级），确认 `type` 非 `null` 再调 `scan_file`（要加载 YARA，较慢）。对大批量文件尤其有用——先用 `type_file` 过滤掉非二进制，再只扫有效的。这比直接 `batch_scan` 一个 `*` 模式更高效，因为后者会对每个文件都尝试加载 YARA。
:::

## 🆚 与 CLI `type` 的差异

| 维度 | MCP `type_file` | AI CLI `type` |
|------|-----------------|---------------|
| `--output/-o` 写文件 | ❌ 无 | ✅ 有 |
| `--format/-f` | ❌ 无（恒 JSON） | ✅ `json`/`text` |
| 错误处理 | `return` 错误 JSON | `error_exit`（stderr + exit 1） |
| 识别逻辑 | 同（`Scanner._type_file`） | 同（`Scanner._type_file`） |
| 返回结构 | 同（`error`/`file`/`type`/`supported_types`） | 同 |

逻辑层面完全一致，差异仅在传输层和错误处理。

## 🔗 调用链

```
MCP client → FastMCP → type_file(target)
                          │
                          ├─ Path(target).exists()?  → 否: return {error:true,message}
                          │
                          └─ open(target,"rb")
                                 │
                                 └─ Scanner._type_file(f)   ← 不调 make_scanner！
                                      │
                                      ├─ 读 4 字节魔数
                                      │
                                      ├─ 命中? → return {error:false, file, type, supported_types}
                                      └─ 未命中? → return {error:false, file, type:null, message}
```

## 📍 相关

- [MCP 概览](./mcp) — 安装、配置、工具清单。
- [AI CLI · type](./ai-cli-type) — 对应的 CLI 命令。
- [文件类型识别](../guide/file-types) — `SCANNABLE_FILE_MAGICS` 与 `_type_file` 详解。
- [tools_scan.py](../modules/mcp-tools-scan) — 适配器源码详解。
- [core-apkid.py](../modules/core-apkid) — `Scanner._type_file` 定义处。
- [scan_file](./mcp-scan-file) — 探完类型后用它扫。
