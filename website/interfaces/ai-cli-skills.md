# AI CLI · skills — 自发现命令清单

<span class="badge badge-info">AI CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-success">自省</span>

🧭 `apkid-ai-cli skills` 是自发现机制——自省 `app.registered_commands`，列出所有已注册命令及其描述。是 AI agent 探索"我能用哪些命令"的入口。

## 🚀 一行用法

```bash
apkid-ai-cli skills
```

## 🖥️ 命令签名

```bash
apkid-ai-cli skills
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| — | — | — | **无参数** |

## 📤 输出示例

```bash
apkid-ai-cli skills
```

```json
{
  "error": false,
  "skills": [
    { "name": "batch", "description": "Batch scan a directory of files" },
    { "name": "diff", "description": "Compare scan results between two files to find protection differences." },
    { "name": "info", "description": "Show version, rules hash, and rules count." },
    { "name": "list-tags", "description": "List all available detection tags and their descriptions." },
    { "name": "rules", "description": "Manage YARA rules: list source files or compile to rules.yarc." },
    { "name": "scan", "description": "Scan a single APK/DEX/ELF file for identifiers." },
    { "name": "skills", "description": "List all available CLI skills (commands) and their descriptions." },
    { "name": "type", "description": "Identify the type of a file (APK/DEX/ELF/etc.) via magic bytes." }
  ],
  "total": 8
}
```

字段说明：

| 字段 | 含义 |
|------|------|
| `error` | 恒为 `false`（函数几乎不可能失败） |
| `skills[]` | 已注册命令数组，按 `name` 字典序排列 |
| `skills[].name` | 命令名（注册时显式给的，如 `list-tags`、`type`；否则回退函数名） |
| `skills[].description` | 命令描述，优先取函数 docstring（`callback.__doc__`） |
| `total` | 命令总数 |

## 📋 8 个命令清单

skills 列出的就是 `app.py` 注册的全部命令：

| 命令 | 描述 | 用户文档 |
|------|------|----------|
| `batch` | 批量扫描目录 | [→](./ai-cli-batch) |
| `diff` | 对比两文件差异 | [→](./ai-cli-diff) |
| `info` | 版本与规则信息 | [→](./ai-cli-info) |
| `list-tags` | 检测类别清单 | [→](ai-cli-list-tags) |
| `rules` | 规则管理（list/compile） | [→](./ai-cli-rules) |
| `scan` | 扫描单文件 | [→](./ai-cli-scan) |
| `skills` | 自发现命令列表 | （本页） |
| `type` | 识别文件类型（不加载 YARA） | [→](./ai-cli-type) |

## 🔍 自发现机制

```python
from apkid.cli.app import app

for command in app.registered_commands:
    name = command.name or command.callback.__name__
    help_text = command.help or ""
    if command.callback and command.callback.__doc__:
        help_text = command.callback.__doc__.strip()
    skill_list.append({"name": name, "description": help_text})
```

要点：

- **数据源是 `app.registered_commands`**：直接自省 Typer app 自身，保证列出的就是当前进程实际可用的命令，不会与真实注册表脱节。
- **`command.name or callback.__name__`**：优先用注册时显式给的 `name`。`app.py` 里 `list-tags` 和 `type` 是显式重映射的（函数名是 `list_tags`/`type_file`，命令名是 `list-tags`/`type`）。
- **描述优先级**：`callback.__doc__`（docstring）优先于 `command.help`。注册时若没传 `help=`，typer 会把 docstring 赋给 `command.help`，显式查 `__doc__` 是为了拿原始 docstring。
- **`sorted(..., key=lambda s: s["name"])`**：按命令名字典序输出，结果稳定。
- **不调 `make_scanner`、不走 `output_result`/`AIOutputFormatter`**：纯元数据查询，直接 `typer.echo`。

::: warning 自发现的可见性闸门
因为 skills 遍历的是 `app.registered_commands`，**加新命令必须在 [app.py](../modules/cli-app) 的 `_register_commands()` 里注册**，否则 skills 看不到它。

新增命令的标准流程：
1. 写 `apkid/cli/cmd_xxx.py`，导出 `xxx()` 函数（带 docstring）。
2. 在 `app.py._register_commands()` 加 `app.command()(cmd_xxx.xxx)`。
3. （可选）显式重映射名：`app.command(name="xxx-cmd")(cmd_xxx.xxx)`。
4. 重新跑 `apkid-ai-cli skills` 确认新命令出现在列表里。

漏掉第 2 步，命令存在但 skills 不列——AI agent 也就发现不了它。
:::

## 🧪 示例命令

```bash
# 看全部命令
apkid-ai-cli skills

# 只看命令名
apkid-ai-cli skills | jq '.skills[].name'

# 找与"扫描"相关的命令
apkid-ai-cli skills | jq '.skills[] | select(.description | test("scan"; "i")) | .name'

# 命令总数
apkid-ai-cli skills | jq '.total'   # 8

# 给 AI 当工具清单
apkid-ai-cli skills | jq '.skills[] | "\(.name): \(.description)"'
```

::: tip 给 AI agent 当入口
AI agent 拿到 APKiD 后第一步可先跑 `skills`，据此决定用哪个命令完成用户任务。`description` 字段就是给 AI 读的"这个命令干啥"的提示。这也是项目把 docstring 写全的动机——docstring 越清晰，skills 自发现越有用。
:::

## 📍 相关

- [skills 命令源码](../modules/cli-cmd-skills) — `cmd_skills.py` 实现。
- [app 模块](../modules/cli-app) — `registered_commands` 的来源与注册表。
- [开发指南](../guide/development) — 新增命令必须注册才会被 skills 列出。
- [info 命令](./ai-cli-info) — 另一个元数据查询命令。
- [AI CLI 概览](./ai-cli) — 全部命令索引与通用参数。
