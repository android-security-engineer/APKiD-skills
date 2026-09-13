# batch_scan — 批量扫描目录

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">FastMCP</span>
<span class="badge badge-success">批量</span>

📦 `batch_scan` 扫描一个目录下的多个文件，把每个文件的扫描结果聚合成一个批量响应。适合批量分类样本、统计加固分布。

## 📋 工具签名

```
batch_scan(directory, recursive?, pattern?, timeout?, typing?, scan_depth?, include_types?) → JSON 字符串
```

## 📑 参数表

| 参数 | 类型 | 默认 | 必填 | 说明 |
|------|------|------|:----:|------|
| `directory` | `str` | — | ✅ | 待扫描的目录路径 |
| `recursive` | `bool` | `False` | — | 是否递归子目录 |
| `pattern` | `str` | `"*.apk"` | — | 文件 glob 模式（如 `*.apk`、`*.dex`、`*.so`） |
| `timeout` | `int` | `30` | — | YARA 扫描超时（秒，每个文件独立计时） |
| `typing` | `str` | `"magic"` | — | 文件识别方式：`magic`/`filename`/`none` |
| `scan_depth` | `int` | `2` | — | 嵌套 ZIP 归档最大递归深度 |
| `include_types` | `bool` | `False` | — | 结果中是否包含 `file_type` 检测 |

::: tip `pattern` 与 `recursive` 的搭配
- `recursive=False, pattern="*.apk"`：只扫当前目录下的 APK。
- `recursive=True, pattern="*.apk"`：递归所有子目录的 APK。
- `pattern="*.so"`：扫 ELF 共享库（常用于批量分析 `lib/` 目录）。
- `pattern="*"`：扫所有文件（非 Android 二进制会被 `typing` 过滤）。
:::

## 🔧 设计要点

```python
dir_path = Path(directory)
if not dir_path.is_dir():
    return json.dumps({"error": True, "message": f"Directory not found: {directory}"})
scanner = make_scanner(...)
files = sorted(dir_path.rglob(pattern) if recursive else dir_path.glob(pattern))
if not files:
    return json.dumps({"error": False, "scanned": 0, "results": [], "message": ...})
all_results = [formatter.format_dict(scanner.scan_file(str(f)), str(f), ...) for f in files]
return json.dumps({"error": False, "scanned": len(all_results), "results": all_results}, ...)
```

- **目录不存在 → 错误 JSON**：与 `scan_file` 文件不存在的处理一致，`return` 而非 `exit`。
- **空结果 ≠ 错误**：目录存在但没有匹配文件时，返回 `error:false` + `scanned:0`，**不是** 错误。
- **`results` 每项是 `format_dict` 产物**：即 [`scan_file`](./mcp-scan-file) 单文件结果的结构（但不含顶层 `error`/`scanned` 字段）。
- **与 CLI 共享 `make_scanner`**：扫描逻辑与 [`batch`](./ai-cli-batch) 命令一致。

## 📤 返回示例

### 成功（有匹配文件）

```json
{
  "error": false,
  "scanned": 2,
  "results": [
    { "schema_version": "1.0.0", "error": false, "target": "/samples/a.apk", "findings": [...], "summary": {...}, "scanned_at": "..." },
    { "schema_version": "1.0.0", "error": false, "target": "/samples/b.apk", "findings": [...], "summary": {...}, "scanned_at": "..." }
  ]
}
```

### 空结果（无匹配文件）

```json
{
  "error": false,
  "scanned": 0,
  "results": [],
  "message": "No files matching '*.apk' found in /empty_dir"
}
```

### 目录不存在

```json
{ "error": true, "message": "Directory not found: /no/such/dir" }
```

::: warning 注意 `scanned:0` 不是失败
客户端判断成败只看 `error` 字段。`scanned:0` 是合法的成功响应——目录存在只是没有匹配文件。别把它当错误处理。
:::

## 🤖 在 Claude 里的使用

> 帮我批量扫描 /home/user/samples/ 下所有 APK，递归子目录

Claude 会调 `batch_scan`，参数 `directory="/home/user/samples/"`、`recursive=true`、`pattern="*.apk"`，拿到聚合 JSON 后做统计：

> 扫了 47 个 APK，其中 12 个用了 360 加固、8 个用了梆梆、3 个未加固……

也可以指定 `pattern`：

> 用 batch_scan 扫 /home/user/samples/ 的 *.so 文件，我想看原生库的保护情况

## 🆚 与 CLI `batch` 的差异

| 维度 | MCP `batch_scan` | AI CLI `batch` |
|------|------------------|----------------|
| 进度条 | ❌ **无** | ✅ 有（Rich 进度条） |
| `--output/-o` 写文件 | ❌ 无 | ✅ 有 |
| `--format/-f` | ❌ 无（恒 JSON） | ✅ `json`/`text` |
| `--verbose/-v` | ❌ 无 | ✅ 有 |
| 错误处理 | `return` 错误 JSON | `error_exit`（stderr + exit 1） |
| 扫描逻辑 | 同 `make_scanner` | 同 `make_scanner` |

::: warning 为何 MCP 没有进度条
MCP 调用是 **请求-响应** 模式：客户端发一个请求，等服务端返回一个响应。这种模式不适合流式进度——客户端拿不到中间状态。所以 `batch_scan` 是"扫完再一次性返回"，大目录会显得"卡住"。如果扫几百个文件，建议拆成多次小批量调用，或在 CLI 里跑。

反观 CLI `batch`，它直接在终端边扫边刷进度条，用户能实时看到当前文件。这是两种接口的本质差异，不是疏漏。详见 [MCP 概览 · 设计要点](./mcp#🧱-设计要点)。
:::

## 🔗 调用链

```
MCP client → FastMCP → batch_scan(directory, ...)
                          │
                          ├─ Path(directory).is_dir()?  → 否: return error JSON
                          │
                          └─ make_scanner()  ← 与 CLI 共享
                                 │
                                 ├─ rglob/glob 收集文件（sorted）
                                 │     └─ 空? → return {error:false,scanned:0,...}
                                 │
                                 └─ for f in files:
                                        scan_file(f) → format_dict() → 入 all_results
                                 │
                                 └─ return {error:false, scanned:N, results:all_results}
```

## 📍 相关

- [MCP 概览](./mcp) — 安装、配置、工具清单。
- [AI CLI · batch](./ai-cli-batch) — 对应的 CLI 命令。
- [scan_file](./mcp-scan-file) — `results` 每项的结构就是它。
- [tools_scan.py](../modules/mcp-tools-scan) — 适配器源码详解。
- [AI 输出格式 · 批量结果](../guide/output-format#📦-批量扫描结果batch) — `results` 数组结构。
- [扫描深度与递归](../guide/scan-depth) — `scan_depth` 参数详解。
