# cli/common.py — 共享工具

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">make_scanner</span>
<span class="badge badge-info">共享</span>

`apkid/cli/common.py` 是 AI CLI 与 MCP 之间的 **公共桥梁**。它定义了构造 Scanner 的统一函数、输出写入、错误退出，以及两个枚举。所有 CLI 命令和 MCP 工具适配器都依赖它——这是"三接口共享逻辑"原则的物理体现。

## 📋 文件内容

| 符号 | 类型 | 说明 |
|------|------|------|
| `TypingMethod` | Enum | `magic`/`filename`/`none` |
| `OutputFormat` | Enum | `json`/`text` |
| `make_scanner(...)` | func | 构造 `Scanner`（核心） |
| `output_result(...)` | func | 写文件或 stdout |
| `error_exit(...)` | func | stderr 输出错误 JSON 并退出 |

## 📐 枚举

```python
class TypingMethod(str, Enum):
    magic = "magic"
    filename = "filename"
    none = "none"

class OutputFormat(str, Enum):
    json = "json"
    text = "text"
```

继承 `str, Enum` 让 typer 能直接当字符串选项用：`typer.Option(TypingMethod.magic, "--typing", ...)`。

## 🏗️ make_scanner()

```python
def make_scanner(timeout=30, typing="magic", scan_depth=2,
                 entry_max_scan_size=0, include_types=False) -> Scanner:
    rules_mgr = RulesManager()
    rules = rules_mgr.load()          # ← 加载 rules.yarc
    options = Options(
        timeout=timeout, json=True, typing=typing,
        scan_depth=scan_depth, entry_max_scan_size=entry_max_scan_size,
        include_types=include_types,
    )
    return Scanner(rules=rules, options=options)
```

**这是 AI CLI 和 MCP 共享扫描逻辑的关键**。两个接口都调它构造 Scanner，差别只在调用方如何把参数传进来（typer 参数 vs MCP schema 参数）。

注意：
- `json=True`：Options 内部会建 `OutputFormatter(json_output=True,...)`，但 AI CLI/MCP **不用** 这个 formatter——它们用 `AIOutputFormatter`。`Options` 里的 `output` 字段在这里是浪费的，但为兼容 `Options` 签名必须传。
- `entry_max_scan_size=0`：AI CLI/MCP 默认不限条目大小（经典 CLI 默认 100MB）。

## 📤 output_result()

```python
def output_result(formatted: str, output: Optional[Path] = None):
    if output:
        output.write_text(formatted, encoding="utf-8")
    else:
        typer.echo(formatted)
```

简单：有 `--output` 写文件，否则 stdout。各命令的 `--output/-o` 选项都走它。

## ⛔ error_exit()

```python
def error_exit(message: str, detail: str = "", code: int = 1):
    error_payload = json.dumps(
        {"error": True, "message": message, "detail": detail},
        ensure_ascii=False,
    )
    typer.echo(error_payload, err=True)   # ← stderr
    raise typer.Exit(code=code)
```

错误走 **stderr**，JSON 格式，与 [AI 输出格式](../guide/output-format#错误对象stderr) 一致。`detail` 通常传 `type(e).__name__`（异常类名）。

CLI 命令的典型错误处理：

```python
try:
    ...
except Exception as e:
    error_exit(str(e), type(e).__name__)
```

MCP 工具适配器 **不用** `error_exit`（因为它会 `raise typer.Exit`，MCP 不该退出进程）——MCP 直接 `return json.dumps({"error": True, ...})`。这是 CLI 与 MCP 适配器代码不同的少数地方之一。

## 🔗 谁用它

| 调用方 | 用什么 |
|--------|--------|
| 所有 `cmd_*.py` | `make_scanner`、`output_result`、`error_exit`、两个枚举 |
| `cmd_batch` | 还额外用 `app.py` 的 `console`（进度条） |
| `mcp/tools_scan.py` | `make_scanner`（构造 Scanner） |
| `mcp/tools_info.py` | 不用 common，只读元数据 |

## 📍 相关

- [架构概览](../guide/architecture) — common 在三层架构里的位置。
- [core-apkid.py](./core-apkid) — make_scanner 构造的 Scanner。
- [ai_output.py](./ai-output) — common 之后用的格式化器。
