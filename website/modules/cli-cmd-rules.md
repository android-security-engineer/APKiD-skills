# cli/cmd_rules.py — rules 命令

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-warning">规则管理</span>

⚙️ `apkid-ai-cli rules <action>` 管理 YARA 规则：`list` 列出源文件，`compile` 重新编译为 `rules.yarc`。是规则开发与发布流程的入口。

## 📋 文件内容一览

| 符号 | 类型 | 说明 |
|------|------|------|
| `rules(action)` | func | typer 命令回调，管理 YARA 规则 |

模块仅导出 `rules` 函数，由 `app.py` 注册为 `rules` 命令。

## 🖥️ 命令签名

```bash
apkid-ai-cli rules <action>
apkid-ai-cli rules list
apkid-ai-cli rules compile
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `action` | `str` | （必填） | 动作：`list` 列源文件，`compile` 重编译 |

无选项，仅一个位置参数。`action` 是自由字符串（非枚举），未知值走 `error_exit`。

## 🔧 源码要点

### list 动作

```python
if action == "list":
    yara_files = rules_mgr._collect_yara_files()
    rule_list = sorted(yara_files.keys())
    typer.echo(
        json.dumps(
            {"rules": rule_list, "count": len(rule_list)},
            ensure_ascii=False,
            indent=2,
        )
    )
```

要点：

- **`_collect_yara_files()`**：RulesManager 的私有方法（下划线开头），扫描 `apkid/rules/` 目录收集 `.yara` 源文件，返回 `{文件名: 路径}` 字典。这里取 `keys()` 并排序。
- **输出文件名列表**：列的是 **源文件**（如 `compiler.yara`），不是单条规则——与 `list-tags`（列检测类别）区分。
- **`count`**：源文件数量。

### compile 动作

```python
elif action == "compile":
    try:
        rules_mgr.compile()
        count = rules_mgr.save()
        typer.echo(
            json.dumps(
                {"compiled": True, "rules_count": count},
                ensure_ascii=False,
                indent=2,
            )
        )
    except Exception as e:
        error_exit(f"Compilation failed: {e}", type(e).__name__)
```

要点：

- **两步**：`compile()` 把 `.yara` 源文件编译成内存中的 YARA Rules 对象；`save()` 序列化为 `rules.yarc` 并返回规则条数。
- **`rules_count`**：`save()` 返回值，是编译后的规则条数（不是源文件数）。
- **编译失败走 `error_exit`**：带 `Compilation failed:` 前缀，`detail` 是异常类名。YARA 语法错误会在这里暴露。
- **`rules.yarc` 是 gitignored**：编译产物不入库，所以发布前/装新环境时必须跑 `rules compile` 或 `prep-release.py`。

### 未知 action

```python
else:
    error_exit(f"Unknown action '{action}'. Use 'list' or 'compile'.")
```

`action` 是自由字符串，传 `list`/`compile` 以外的值会被拒绝，带使用提示。

## 🔗 调用链

```
rules("list")    → RulesManager._collect_yara_files() → sorted(keys) → typer.echo
rules("compile") → RulesManager.compile() → .save() → 写 rules.yarc → typer.echo
                 → (失败) → common.error_exit()
rules(其它)      → common.error_exit("Unknown action ...")
```

## 🤝 与其它模块的关系

- **依赖 [rules 模块](./rules)**：`RulesManager` 的 `_collect_yara_files`/`compile`/`save`。
- **依赖 [common.py](./cli-common)**：仅 `error_exit`（不调 `make_scanner`/`output_result`）。
- **被 [app.py](./cli-app) 注册**：`app.command()(cmd_rules.rules)`。
- **与 [cmd_info.py](./cli-cmd-info) 互补**：info 读规则元数据（哈希/数量），rules 写规则（重编译）或列源文件。
- **与 [cmd_tags.py](./cli-cmd-tags) 区分**：rules list 列源文件名，list-tags 列检测 tag。
- **与 `prep-release.py` 对应**：`rules compile` 等价于 `prep-release.py` 的编译步骤，但 `prep-release.py` 还做发布打包。

## 📍 相关

- [AI CLI · rules](../interfaces/ai-cli-rules) — 用户视角用法与示例。
- [RulesManager](./rules) — `compile`/`save`/`_collect_yara_files` 实现。
- [YARA 规则开发](../rules/writing-rules) — 如何写新规则。
- [cmd_info.py](./cli-cmd-info) — 规则元数据查询。
- [cmd_tags.py](./cli-cmd-tags) — 检测类别列表。
