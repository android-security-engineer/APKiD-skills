# apkid.py — 扫描引擎核心

<span class="badge badge-info">核心</span>
<span class="badge badge-info">Scanner</span>
<span class="badge badge-info">Options</span>

`apkid/apkid.py` 是整个工具的心脏。它定义了文件类型魔数表、扫描选项、以及 `Scanner` 类——三个接口最终都调到这里。

## 📋 文件内容一览

| 符号 | 类型 | 说明 |
|------|------|------|
| `SCANNABLE_FILE_MAGICS` | dict | 支持的文件类型 → 魔数集合 |
| `XZ_COMPRESSION_TYPE` | int | `95`，XZ 压缩类型码 |
| `ZIP_LFH_SIG_SIZE` 等 | int | ZIP Local File Header 尺寸常量 |
| `Options` | class | 扫描选项容器 |
| `Scanner` | class | 扫描器，扫描文件/目录/ZIP |

## 🗂️ SCANNABLE_FILE_MAGICS

```python
SCANNABLE_FILE_MAGICS: Dict[str, Set[bytes]] = {
    'zip': {b'PK\x03\x04', b'PK\x05\x06', b'PK\x07\x08'},
    'dex': {b'dex\n', b'dey\n'},
    'elf': {b'\x7fELF'},
    'res': {b'\x02\x00\x0c\x00'},
    'dll': {b'MZ\x90\x00'},
}
```

判定只读前 4 字节。详见 [文件类型识别](../guide/file-types)。

## ⚙️ Options 类

`Options` 是个纯数据容器，持有用户选项 + 已初始化的 `RulesManager` 和 `OutputFormatter`：

| 参数 | 默认 | 说明 |
|------|------|------|
| `timeout` | `10`（经典）/ `30`（AI） | YARA 单次匹配超时秒数 |
| `verbose` | `False` | 打印调试信息 |
| `json` | `False` | 经典输出用，是否 JSON |
| `output_dir` | `None` | 经典输出：写多文件目录（隐含 JSON） |
| `typing` | `"magic"` | 文件识别策略：`magic`/`filename`/`None` |
| `entry_max_scan_size` | `0` | ZIP 条目大小上限（0=不限） |
| `scan_depth` | `2` | 嵌套 ZIP 递归深度 |
| `recursive` | `False` | 目录扫描是否递归 |
| `include_types` | `False` | 是否输出 file_type finding |

构造时副作用：`self.rules_manager = RulesManager()`、`self.output = OutputFormatter(...)`——即 Options 一建好，规则管理器和格式化器也就绪了。

::: tip 经典 vs AI 的 Options
经典 CLI（`main.py`）直接 `Options(...)`，用它自带的 `OutputFormatter`。AI CLI/MCP 不直接用 Options，而是通过 [`common.make_scanner()`](./cli-common) 构造，并用 `AIOutputFormatter` 而非 `Options.output`。
:::

## 🔍 Scanner 类

### 公开方法

```python
scanner.scan(path)          # 文件 or 目录（自动分发）
scanner.scan_directory(dir)  # 目录
scanner.scan_file(path)      # 单文件 → 返回 Dict[str, List[Match]]
scanner.scan_file_obj(file, file_path)  # 已打开的文件对象
```

### scan_file

```python
def scan_file(self, file_path) -> Dict[str, List[yara.Match]]:
    results = []
    with open(file_path, 'rb') as f:
        try:
            results = self.scan_file_obj(f, file_path)
        except Exception as e:
            print(f"Exception scanning {file_path}: {traceback.format_exc()}")
    return results
```

注意：**异常被捕获并打印**，不向上抛——扫描一个文件出错不会中断批量扫描。AI CLI 在外层还有 try/except 兜底。

### scan_file_obj：核心逻辑

```python
def scan_file_obj(self, file, file_path='$FILE$'):
    results = {}
    if not self._should_scan(file, file_name):   # ① typing 判定
        return results
    matches = self.rules.match(data=file.read(), timeout=...)  # ② 外层匹配
    if matches:
        results[file_path] = matches
    if self._is_zipfile(file, file_name):        # ③ 是 ZIP → 解包
        with zipfile.ZipFile(file) as zf:
            zip_results = self._scan_zip(zf)
        for entry_name, entry_matches in zip_results.items():
            results[f'{file_path}!{entry_name}'] = entry_matches  # ④ ! 命名
    return results
```

### _scan_zip / _scan_zip_entry

遍历 ZIP 条目，逐个 `_scan_zip_entry`。详见 [扫描深度与递归](../guide/scan-depth)。要点：

- 跳过目录条目（`info.is_dir()`）。
- 读前 4 字节判定是否扫描；读全量匹配。
- 处理 XZ 压缩（`compress_type == 95`）的 NotImplementedError。
- 捕获 zip bomb（"Overlapped entries"/"possible zip bomb"）。
- 嵌套 ZIP 递归，`depth < scan_depth` 才继续。

### _type_file（静态）

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

被 `type` 命令/MCP 工具复用，单独判定类型而不跑 YARA。

### _is_zipfile

`filename` 模式看扩展名；`magic`/`none` 模式双重判定（魔数 + `zipfile.is_zipfile`），避免 ELF 被误判。

### _should_scan

`magic` 模式调 `_type_file`；`filename` 模式匹配 `classes*`/`AndroidManifest.xml`/`lib/`/`.so`/`.dex`/`.apk`/`.arsc`/`.dll`；`none` 模式恒返回 `True`。

### _yield_file_paths

目录扫描时，`recursive=True` 用 `os.walk`，否则只列顶层非目录文件。

## 🔗 与其它模块的关系

```
RulesManager.load() ──→ yara.Rules ──┐
                                     ▼
Options ──→ Scanner(rules, options)  │
                  │                   │
                  └─ rules.match() ◀──┘
```

`Scanner` 只依赖 `yara`（规则已加载好）和 `Options`。它 **不**直接依赖任何输出格式化器——返回原始 `Dict[str, List[Match]]`，由调用方选择 `OutputFormatter` 或 `AIOutputFormatter`。这是经典输出与 AI 输出能并存的关键。

## 📍 相关

- [common.make_scanner](./cli-common) — AI CLI/MCP 如何构造 Scanner。
- [扫描深度与递归](../guide/scan-depth) — `_scan_zip_entry` 详解。
- [工作原理](../guide/how-it-works) — 整体流程。
