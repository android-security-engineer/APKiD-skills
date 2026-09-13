# cli/cmd_scan.py — scan 命令

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-success">核心</span>

🔍 `apkid-ai-cli scan` 扫描单个 APK/DEX/ELF 文件，识别加壳、签名、编译器、保护器等标识。是 AI CLI 最常用、最基础的命令。

## 📋 文件内容一览

| 符号 | 类型 | 说明 |
|------|------|------|
| `scan(...)` | func | typer 命令回调，扫描单文件 |

模块仅导出一个 `scan` 函数。`app.py` 通过 `app.command()(cmd_scan.scan)` 注册为 `scan` 命令。

## 🖥️ 命令签名

```bash
apkid-ai-cli scan <target> [options]
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `target` | `Path` | （必填） | 待扫描的 APK/DEX/ELF 文件，`exists=True` 校验存在 |
| `--output`, `-o` | `Optional[Path]` | `None` | 写入文件而非 stdout |
| `--format`, `-f` | `OutputFormat` | `json` | 输出格式：`json`/`text` |
| `--timeout`, `-t` | `int` | `30` | YARA 扫描超时（秒） |
| `--typing` | `TypingMethod` | `magic` | 文件识别方式：`magic`/`filename`/`none` |
| `--scan-depth` | `int` | `2` | 嵌套 ZIP 归档最大递归深度 |
| `--entry-max-scan-size` | `int` | `0` | 单个 ZIP 条目最大扫描字节数（0=不限） |
| `--include-types` | `bool` | `False` | 结果中包含 `file_type` 检测 |
| `--verbose`, `-v` | `bool` | `False` | 向 stderr 输出调试日志 |

## 🔧 源码要点

整个函数体只有一条 `try/except`，调用链清晰：

```python
scanner = make_scanner(
    timeout=timeout,
    typing=typing.value,
    scan_depth=scan_depth,
    entry_max_scan_size=entry_max_scan_size,
    include_types=include_types,
)
results = scanner.scan_file(str(target))
formatter = AIOutputFormatter()
formatted = formatter.format(
    results, str(target), fmt=fmt.value, include_types=include_types
)
output_result(formatted, output)
```

要点：

- **`make_scanner` 是共享入口**：与 MCP `tools_scan.py` 走同一个构造器，确保 CLI 和 MCP 扫描行为完全一致。参见 [common.py](./cli-common)。
- **`typing.value` / `fmt.value`**：枚举继承 `str, Enum`，传给 `make_scanner`/`format` 时取 `.value` 拿到原始字符串。
- **`AIOutputFormatter.format`**（而非 `format_dict`）：scan 命令直接出最终字符串（带 `schema_version`），不像 batch/diff 还要聚合，所以用 `format`。
- **`entry_max_scan_size=0`**：AI CLI 默认不限条目大小（经典 CLI 默认 100MB）——这是 AI 与经典 CLI 的默认值差异之一。
- **`verbose` 未直接使用**：参数定义了但函数体未消费，仅为 CLI 接口一致性保留（实际调试日志由 `Options` 控制）。
- **异常统一走 `error_exit`**：

```python
except Exception as e:
    error_exit(str(e), type(e).__name__)
```

错误以 JSON 形式输出到 stderr，`detail` 传异常类名。参见 [error_exit](./cli-common#⛔-error_exit)。

## 🔗 调用链

```
scan() → common.make_scanner() → Scanner.scan_file()
      → AIOutputFormatter.format() → common.output_result()
                                    ↓
                                stdout / --output 文件
异常 → common.error_exit() → stderr JSON + typer.Exit(1)
```

## 🤝 与其它模块的关系

- **依赖 [common.py](./cli-common)**：`make_scanner`、`output_result`、`error_exit`、`TypingMethod`、`OutputFormat`。
- **依赖 [ai_output.py](./ai-output)**：`AIOutputFormatter`，最终输出格式由它决定。
- **被 [app.py](./cli-app) 注册**：`app.command()(cmd_scan.scan)`。
- **与 [cmd_batch.py](./cli-cmd-batch) 对比**：batch 是 scan 的目录版，但用 `format_dict` 聚合；scan 用 `format` 直接出字符串。
- **MCP 对应**：`mcp/tools_scan.py` 调同样的 `make_scanner` + `AIOutputFormatter`，差别仅在错误处理（MCP 不 `raise typer.Exit`）。

## 📍 相关

- [AI CLI · scan](../interfaces/ai-cli-scan) — 用户视角用法与示例。
- [AI 输出格式](../guide/output-format) — `format` 产出的 JSON 结构。
- [common.py](./cli-common) — 共享工具。
- [ai_output.py](./ai-output) — 格式化器与 `RULE_DESCRIPTIONS`。
- [cmd_batch.py](./cli-cmd-batch) — 批量扫描。
