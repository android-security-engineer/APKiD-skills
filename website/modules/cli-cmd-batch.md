# cli/cmd_batch.py — batch 命令

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-warning">批量</span>

📦 `apkid-ai-cli batch` 批量扫描目录下的多个文件，用 rich Progress 显示进度条（走 stderr），结果聚合成单个 JSON 数组输出到 stdout。

## 📋 文件内容一览

| 符号 | 类型 | 说明 |
|------|------|------|
| `batch(...)` | func | typer 命令回调，批量扫描目录 |

模块仅导出 `batch` 函数，由 `app.py` 注册为 `batch` 命令。

## 🖥️ 命令签名

```bash
apkid-ai-cli batch <directory> [options]
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `directory` | `Path` | （必填） | 含待扫描文件的目录，`exists=True` |
| `--recursive`, `-r` | `bool` | `False` | 递归扫描子目录 |
| `--pattern`, `-p` | `str` | `*.apk` | 文件 glob 模式 |
| `--output`, `-o` | `Optional[Path]` | `None` | 写入文件而非 stdout |
| `--format`, `-f` | `OutputFormat` | `json` | 输出格式 |
| `--timeout`, `-t` | `int` | `30` | YARA 扫描超时（秒） |
| `--typing` | `TypingMethod` | `magic` | 文件识别方式 |
| `--scan-depth` | `int` | `2` | 嵌套 ZIP 归档最大递归深度 |
| `--entry-max-scan-size` | `int` | `0` | 单个 ZIP 条目最大扫描字节数（0=不限） |
| `--include-types` | `bool` | `False` | 结果含 `file_type` 检测 |
| `--verbose`, `-v` | `bool` | `False` | 调试日志 |

## 🔧 源码要点

### 文件收集

```python
if recursive:
    files = sorted(target_path.rglob(pattern))
else:
    files = sorted(target_path.glob(pattern))
```

`rglob`/`glob` 二选一，结果 `sorted` 保证输出顺序稳定。

### 空文件集合

```python
if not files:
    result = json.dumps(
        {
            "error": False,
            "scanned": 0,
            "results": [],
            "message": f"No files matching '{pattern}' found in {directory}",
        },
        ensure_ascii=False,
    )
    output_result(result, output)
    return
```

注意：**空集合不是错误**（`error: False`），带 `message` 提示原因。这是与异常路径（`error_exit`）的关键区别。

### 进度条（stderr）

```python
from apkid.cli.app import console as _console

with Progress(
    SpinnerColumn(),
    TextColumn("[progress.description]{task.description}"),
    console=_console,
) as progress:
    task = progress.add_task(f"Scanning {len(files)} files...", total=len(files))
    for f in files:
        results = scanner.scan_file(str(f))
        formatted = formatter.format_dict(results, str(f), include_types=include_types)
        all_results.append(formatted)
        progress.advance(task)
```

要点：

- **复用 `app.py` 的 `console`**：该 Console 是 `Console(stderr=True)`，进度条走 stderr，**不污染 stdout 的 JSON 结果**。这是 AI 可解析输出的关键。
- **用 `format_dict` 而非 `format`**：每个文件产出 **dict**（非字符串），便于后续聚合进 `results` 数组。`format` 会产出带 `schema_version` 的完整字符串，不适合聚合。
- **逐文件 `scan_file`**：复用同一个 `scanner` 实例，YARA 规则只加载一次。

### 聚合输出

```python
batch_output = json.dumps(
    {
        "error": False,
        "scanned": len(all_results),
        "results": all_results,
    },
    ensure_ascii=False,
    indent=2,
)
output_result(batch_output, output)
```

`scanned` 即结果数组长度，便于 AI 快速核对数量。

## 🔗 调用链

```
batch() → common.make_scanner() → AIOutputFormatter
        → Path.rglob/glob 收集文件
        → (空集合) → output_result({error:false,scanned:0,...}) 直出
        → (非空)   → Progress(stderr) 循环 scanner.scan_file + format_dict
                   → 聚合 → output_result({error:false,scanned:N,results:[...]})
异常 → common.error_exit()
```

## 🤝 与其它模块的关系

- **依赖 [common.py](./cli-common)**：`make_scanner`、`output_result`、`error_exit`、枚举。
- **依赖 [app.py](./cli-app)**：`from apkid.cli.app import console as _console`，复用 stderr Console 跑进度条。
- **依赖 [ai_output.py](./ai-output)**：`AIOutputFormatter.format_dict`（注意是 dict 版）。
- **与 [cmd_scan.py](./cli-cmd-scan) 对比**：scan 用 `format` 出字符串，batch 用 `format_dict` 出 dict 再聚合。
- **MCP 对应**：`mcp/tools_batch.py`（若存在）走同样 `make_scanner` + `format_dict` 路径。

## 📍 相关

- [AI CLI · batch](../interfaces/ai-cli-batch) — 用户视角用法与示例。
- [AI 输出格式](../guide/output-format) — 批量结果结构。
- [cmd_scan.py](./cli-cmd-scan) — 单文件扫描。
- [app.py](./cli-app) — `console` 的来源。
