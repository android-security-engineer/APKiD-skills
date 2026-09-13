# cli/cmd_skills.py — skills 命令

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-success">自省</span>

🧭 `apkid-ai-cli skills` 自发现机制——自省 `app.registered_commands`，列出所有已注册命令及其描述。是 AI agent 探索"我能用哪些命令"的入口。

## 📋 文件内容一览

| 符号 | 类型 | 说明 |
|------|------|------|
| `skills()` | func | typer 命令回调，列出所有已注册命令 |

模块仅导出 `skills` 函数，由 `app.py` 注册为 `skills` 命令。

## 🖥️ 命令签名

```bash
apkid-ai-cli skills
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| — | — | — | **无参数** |

## 🔧 源码要点

```python
from apkid.cli.app import app

def skills():
    """List all available CLI skills (commands) and their descriptions."""
    skill_list = []
    for command in app.registered_commands:
        name = command.name or command.callback.__name__
        help_text = command.help or ""
        if command.callback and command.callback.__doc__:
            help_text = command.callback.__doc__.strip()
        skill_list.append(
            {
                "name": name,
                "description": help_text,
            }
        )
    result = {
        "error": False,
        "skills": sorted(skill_list, key=lambda s: s["name"]),
        "total": len(skill_list),
    }
    typer.echo(json.dumps(result, ensure_ascii=False, indent=2))
```

要点：

- **数据源是 `app.registered_commands`**：直接自省 Typer app 自己——这保证 skills 列出的就是 **当前进程实际可用的命令**，不会与真实注册表脱节。
- **`command.name or command.callback.__name__`**：优先用注册时显式给的 `name`（如 `list-tags`、`type`），否则回退到函数名。这正确反映了 [app.py](./cli-app) 的名字重映射。
- **描述优先级**：`command.callback.__doc__`（函数 docstring）优先于 `command.help`。注册时若没传 `help=`，typer 会把 docstring 赋给 `command.help`，所以两者常一致；显式 `__doc__` 检查是为了拿原始 docstring。
- **`sorted(..., key=lambda s: s["name"])`**：按命令名字典序输出，结果稳定。
- **`total`**：命令总数，便于 AI 快速核对。
- **自发现的代价**：因为 skills 遍历的是 `app.registered_commands`，**加新命令必须在 [app.py](./cli-app) 的 `_register_commands()` 里注册**，否则 skills 看不到它。这是新增命令流程的关键约束。
- **直接 `typer.echo`**：不走 `output_result`/`AIOutputFormatter`/`make_scanner`——纯元数据查询。
- **无 try/except**：函数几乎不可能失败。

## 🔗 调用链

```
skills() → apkid.cli.app.app.registered_commands
         → 遍历取 name + docstring
         → sorted by name
         → typer.echo({error:false, skills:[{name,description}], total})
```

## 🤝 与其它模块的关系

- **依赖 [app.py](./cli-app)**：`from apkid.cli.app import app`——这是 skills 的**唯一**数据源。app.py 注册了什么，skills 就列出什么。
- **不依赖 [common.py](./cli-common)**：不调任何 common 函数。
- **被 [app.py](./cli-app) 注册**：`app.command()(cmd_skills.skills)`——skills 自己也在注册表里，会列出自己。
- **新增命令的"可见性闸门"**：写完 `cmd_xxx.py` 后必须在 `app.py._register_commands()` 加 `app.command()(cmd_xxx.xxx)`，否则 skills 命令不会列出它。参见 [添加新命令流程](../guide/development)。
- **MCP 对应**：MCP 侧没有完全对应的"列工具"命令（MCP 通过 `tools/list` 协议自带），但 skills 的定位类似——让调用方发现可用能力。

## 📍 相关

- [AI CLI · skills](../interfaces/ai-cli-skills) — 用户视角用法与示例。
- [app.py](./cli-app) — `registered_commands` 的来源与注册表。
- [添加新命令](../guide/development) — 为什么必须注册才能被 skills 列出。
- [cmd_info.py](./cli-cmd-info) — 另一个元数据查询命令。
