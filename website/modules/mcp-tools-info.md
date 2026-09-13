# mcp/tools_info.py — 信息工具适配器

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">元数据</span>

`apkid/mcp/tools_info.py` 把 4 个元数据/管理操作暴露为 MCP 工具。与 [tools_scan.py](./mcp-tools-scan) 不同，这些工具 **不调 `make_scanner`**——它们读的是版本、标签、规则文件等静态信息。

## 📋 文件内容

| 符号 | 类型 | 说明 |
|------|------|------|
| `info()` | func | 版本 + 规则哈希 + 规则数 |
| `list_tags()` | func | 所有检测类别 |
| `rules(action)` | func | 列出/编译规则 |
| `skills()` | func | 列出所有 MCP 工具 |

## ℹ️ info

```python
def info() -> str:
    rules_mgr = RulesManager()
    rules_hash = rules_mgr.hash
    try:
        rules = rules_mgr.load()
        rules_count = len(set(r.identifier for r in rules))
    except Exception:
        rules_count = 0
    return json.dumps({
        "error": False, "version": __version__,
        "rules_sha256": rules_hash, "rules_count": rules_count,
    }, ensure_ascii=False, indent=2)
```

与 CLI `info` 完全对应。`rules_count` 用 `set(r.identifier)` 去重——因为 private 规则也可能被计入。load 失败时 `rules_count=0`（如 `rules.yarc` 缺失），不报错。

返回带 `indent=2`（美观缩进），扫描类工具则用紧凑格式——信息类工具更可能被人类直接看。

## 🏷️ list_tags

```python
def list_tags() -> str:
    tags = [{"tag": tag, "description": desc}
            for tag, desc in sorted(RULE_DESCRIPTIONS.items())]
    return json.dumps({"error": False, "tags": tags}, ensure_ascii=False, indent=2)
```

遍历 `ai_output.RULE_DESCRIPTIONS`（sorted by key），输出所有检测类别。与 CLI `list-tags` 对应。这是让 AI 客户端"知道有哪些检测维度"的自发现工具。

## 📜 rules

```python
def rules(action: str = "list") -> str:
    rules_mgr = RulesManager()
    if action == "list":
        yara_files = rules_mgr._collect_yara_files()
        rule_list = sorted(yara_files.keys())
        return json.dumps({"error": False, "rules": rule_list, "count": len(rule_list)}, ...)
    elif action == "compile":
        rules_mgr.compile()
        count = rules_mgr.save()
        return json.dumps({"error": False, "compiled": True, "rules_count": count}, ...)
    else:
        return json.dumps({"error": True, "message": f"Unknown action '{action}'. Use 'list' or 'compile'."})
```

注意 `action` **有默认值 `"list"`**——MCP 客户端可不传参调用，默认列出规则。CLI 版 `rules` 命令则要求显式传 action。

`compile` 会写 `rules.yarc`——这是个 **有副作用** 的工具，调用前应确认环境。错误（如规则语法错）走 `return` 错误 JSON。

## 🧩 skills

```python
def skills() -> str:
    tool_list = [
        {"name": "scan_file", "description": "Scan an APK, DEX, or ELF file..."},
        {"name": "batch_scan", "description": "Batch scan files in a directory"},
        # ... 共 8 个工具
    ]
    return json.dumps({"error": False, "tools": sorted(...), "total": len(tool_list)}, ...)
```

**硬编码** 了 8 个工具的列表（而非像 CLI `skills` 那样自省 `app.registered_commands`）。因为 MCP 这边没有等价的"已注册工具列表"可自省——FastMCP 的工具注册是命令式的，没有暴露反向查询的简单 API。

::: warning 加新 MCP 工具要同步这里
新增一个 MCP 工具时，除了在 [server.py](./mcp-server) 注册，还要在 `tools_info.skills()` 的 `tool_list` 里手动加一项，否则 `skills` 工具不会列出它。这是与 CLI 侧（自省 `registered_commands`）的明显差异。
:::

## 🆚 与 CLI 信息命令的对比

| 工具/命令 | MCP（tools_info） | CLI（cmd_info/tags/rules/skills） |
|-----------|-------------------|-----------------------------------|
| `info` | `return` JSON | `typer.echo` JSON |
| `list_tags` | `return` JSON | `typer.echo` JSON |
| `rules` | `action` 默认 `"list"` | `action` 必填 |
| `skills` | **硬编码**列表 | **自省** `registered_commands` |
| 错误 | `return` 错误 JSON | `error_exit`（stderr + exit） |

## 🔗 调用链

```
MCP client → FastMCP → tools_info.info()
                          │
                          ├─ RulesManager().hash    （惰性算 SHA-256）
                          ├─ RulesManager().load()  （加载 rules.yarc）
                          │     └─ len(set(r.identifier))
                          └─ return json.dumps({...})
```

信息工具是 **只读的**（除 `rules compile`），适合 AI 客户端在扫描前先调 `info`/`list_tags`/`skills` 了解能力，再调 `scan_file`。

## 📍 相关

- [mcp/server.py](./mcp-server) — 注册这些工具。
- [tools_scan.py](./mcp-tools-scan) — 扫描类工具。
- [CLI 对应命令](./cli-cmd-info) — info/tags/rules/skills。
- [代码模块：ai_output.py](./ai-output) — `RULE_DESCRIPTIONS` 来源。
