# cli/app.py — Typer 应用入口

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">typer</span>

`apkid/cli/app.py` 创建 Typer 应用并注册所有 AI CLI 命令。是 `apkid-ai-cli` 命令的根。

## 📋 文件内容

| 符号 | 类型 | 说明 |
|------|------|------|
| `app` | `typer.Typer` | 主应用实例 |
| `console` | `rich.console.Console` | stderr 控制台（进度条用） |
| `_register_commands()` | func | 导入并注册所有命令模块 |
| `ai_cli()` | func | console script 入口 |

## 🧱 app 实例

```python
app = typer.Typer(
    name="apkid-ai-cli",
    help="APKiD AI-CLI: Android APK/DEX/ELF identifier — AI-native interface.",
    no_args_is_help=True,
    rich_markup_mode="rich",
)
```

- `no_args_is_help=True`：无参数时显示帮助（而非报错）。
- `rich_markup_mode="rich"`：help 文本支持 Rich 标记。
- `name` 即命令名。

## 🖥️ console

```python
console = Console(stderr=True)
```

一个 **stderr** Rich Console。被 `cmd_batch.py` 的进度条复用（`Progress(console=_console)`），让进度条走 stderr、不污染 stdout 的 JSON 结果。

## 📝 _register_commands()

```python
def _register_commands():
    from apkid.cli import cmd_scan, cmd_batch, cmd_tags, cmd_info, cmd_rules
    from apkid.cli import cmd_diff, cmd_type, cmd_skills

    app.command()(cmd_scan.scan)
    app.command()(cmd_batch.batch)
    app.command(name="list-tags")(cmd_tags.list_tags)   # 名字带连字符
    app.command()(cmd_info.info)
    app.command()(cmd_rules.rules)
    app.command()(cmd_diff.diff)
    app.command(name="type")(cmd_type.type_file)         # 避开关键字
    app.command()(cmd_skills.skills)

_register_commands()   # 模块加载时立即执行
```

要点：
- **延迟导入**：在函数内 import，避免模块加载时全量导入（启动更快，也避免循环依赖）。
- **名字重映射**：`list_tags` → `list-tags`（连字符更 CLI 化）；`type_file` → `type`（避开 Python 关键字 `type`）。
- 函数名即命令名（除非显式 `name=`）。

## 🚪 ai_cli()

```python
def ai_cli():
    """Entry point for apkid-ai-cli command."""
    app()
```

`setup.py` 注册 `apkid-ai-cli=apkid.cli:ai_cli`。`__init__.py` 把它 re-export，所以入口写 `apkid.cli:ai_cli`。

## 🔗 命令注册表

| 命令 | 函数 | 模块 |
|------|------|------|
| `scan` | `cmd_scan.scan` | [cmd_scan.py](./cli-cmd-scan) |
| `batch` | `cmd_batch.batch` | [cmd_batch.py](./cli-cmd-batch) |
| `diff` | `cmd_diff.diff` | [cmd_diff.py](./cli-cmd-diff) |
| `type` | `cmd_type.type_file` | [cmd_type.py](./cli-cmd-type) |
| `info` | `cmd_info.info` | [cmd_info.py](./cli-cmd-info) |
| `list-tags` | `cmd_tags.list_tags` | [cmd_tags.py](./cli-cmd-tags) |
| `rules` | `cmd_rules.rules` | [cmd_rules.py](./cli-cmd-rules) |
| `skills` | `cmd_skills.skills` | [cmd_skills.py](./cli-cmd-skills) |

`cmd_skills.skills` 会自省 `app.registered_commands` 列出所有命令——所以加新命令时 **必须在这里注册**，否则 `skills` 命令看不到它。

## 📍 相关

- [AI CLI 概览](../interfaces/ai-cli) — 用户视角的命令列表。
- [cmd_skills.py](./cli-cmd-skills) — 自发现机制。
- [CLI 添加新命令](../guide/development) — 如何加一条命令。
