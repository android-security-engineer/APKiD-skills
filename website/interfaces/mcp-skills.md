# skills — 自发现工具列表

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">FastMCP</span>
<span class="badge badge-info">元数据</span>
<span class="badge badge-warning">硬编码</span>

🧩 `skills` 工具返回 `apkid-mcp` 暴露的所有 MCP 工具列表。是让 AI 客户端"自发现能力"的工具——扫描前先调它，知道有哪些工具可用。

## 📋 工具签名

```
skills() → JSON 字符串
```

## 📑 参数表

| 参数 | 类型 | 默认 | 必填 | 说明 |
|------|------|------|:----:|------|
| （无） | — | — | — | `skills` 不接受任何参数 |

零参数工具，调用时什么都不传。

## 🔧 设计要点：硬编码列表

```python
def skills() -> str:
    tool_list = [
        {"name": "scan_file", "description": "Scan an APK, DEX, or ELF file for packer/signer/compiler/protector identifiers"},
        {"name": "batch_scan", "description": "Batch scan files in a directory"},
        {"name": "diff_files", "description": "Compare scan results between two files"},
        {"name": "type_file", "description": "Identify file type via magic bytes"},
        {"name": "info", "description": "Show APKiD version and rules info"},
        {"name": "list_tags", "description": "List all detection tags and descriptions"},
        {"name": "rules", "description": "Manage YARA rules (list or compile)"},
        {"name": "skills", "description": "List all available MCP tools"},
    ]
    return json.dumps({
        "error": False,
        "tools": sorted(tool_list, key=lambda s: s["name"]),
        "total": len(tool_list),
    }, ensure_ascii=False, indent=2)
```

关键点：

- **硬编码 8 个工具**：`tool_list` 是写死的列表，**不像 CLI `skills` 那样自省 `app.registered_commands`**。
- **`sorted(by name)`**：按工具名字母序排序后返回。
- **每项是 `{name, description}`**：`name` 是工具注册名（注意 `list_tags` 在列表里写下划线形式，但实际注册名是 `list-tags`，见下方提示），`description` 是简短说明。
- **`total` 是工具总数**：当前为 8。
- **不调 `make_scanner`**：纯静态列表查询，不需要 YARA、不需要 `rules.yarc`。

::: warning 为何硬编码而非自省
CLI 侧的 `skills` 命令自省 `app.registered_commands`——Typer 把已注册命令暴露成可查询的列表。但 MCP 这边，FastMCP 的工具注册是 **命令式** 的（`mcp.tool()(func)`），没有暴露"已注册工具列表"的简单反查 API。所以 `tools_info.skills()` 用硬编码列表代替自省。

**后果**：新增一个 MCP 工具时，除了在 [`server.py`](../modules/mcp-server) 用 `mcp.tool()` 注册，还要在 `tools_info.skills()` 的 `tool_list` 里 **手动加一项**，否则 `skills` 工具不会列出它。这是与 CLI 侧（自省，自动包含新命令）的明显差异，开发时容易遗漏。详见 [tools_info.py 源码文档](../modules/mcp-tools-info#🧩-skills)。
:::

::: warning 列表里的 `list_tags` vs 注册名 `list-tags`
`skills` 返回的 `name` 字段里，`list_tags` 是 **下划线** 形式（因为硬编码列表里就这么写）。但实际 MCP 注册名是 `list-tags`（连字符，见 [server.py](../modules/mcp-server) 的 `mcp.tool(name="list-tags")`）。客户端若想调用它，应用注册名 `list-tags`。这是 `skills` 工具的一个已知小瑕疵——硬编码列表没区分函数名和注册名。
:::

## 📤 返回示例

```json
{
  "error": false,
  "tools": [
    { "name": "batch_scan", "description": "Batch scan files in a directory" },
    { "name": "diff_files", "description": "Compare scan results between two files" },
    { "name": "info", "description": "Show APKiD version and rules info" },
    { "name": "list_tags", "description": "List all detection tags and descriptions" },
    { "name": "rules", "description": "Manage YARA rules (list or compile)" },
    { "name": "scan_file", "description": "Scan an APK, DEX, or ELF file for packer/signer/compiler/protector identifiers" },
    { "name": "skills", "description": "List all available MCP tools" },
    { "name": "type_file", "description": "Identify file type via magic bytes" }
  ],
  "total": 8
}
```

8 个工具按名字字母序排列。注意 `skills` 自己也在列表里（自指）。

## 🤖 在 Claude 里的使用

> 这个 APKiD MCP 服务器都能做什么？列出所有工具

Claude 调 `skills`，拿到 8 个工具后整理：

> APKiD MCP 提供 8 个工具：
> - 扫描类：`scan_file`（单文件）、`batch_scan`（目录）、`diff_files`（对比）、`type_file`（类型识别）
> - 信息类：`info`（版本规则）、`list_tags`（检测类别）、`rules`（规则管理）、`skills`（本列表）
>
> 想扫描 APK 就用 `scan_file`，想批量就用 `batch_scan`……

::: tip skills 是 AI 自发现的入口
MCP 客户端首次连接时，FastMCP 会通过协议自动暴露工具 schema（Claude 已知有哪些工具可调）。但 `skills` 工具的价值在于：它把工具的 **人类可读描述** 集中返回，便于 AI 在对话里向用户解释能力，或在长上下文里重新回忆。配合 [`info`](./mcp-info) 和 [`list_tags`](./mcp-list-tags)，AI 能完整自描述整个实例。
:::

## 🆚 与 CLI `skills` 的差异

| 维度 | MCP `skills` | AI CLI `skills` |
|------|--------------|-----------------|
| 参数 | 无 | 无 |
| 数据来源 | **硬编码** `tool_list` | **自省** `app.registered_commands` |
| 新增工具后 | 需手动维护 `tool_list` | 自动包含 |
| `list_tags` 名称 | 写成 `list_tags`（下划线） | 命令名 `list-tags`（连字符） |
| `--output/-o` | ❌ 无 | ✅ 有 |
| `--format/-f` | ❌ 无（恒 JSON） | ✅ `json`/`text` |
| 错误处理 | `return` 错误 JSON | `error_exit`（stderr + exit 1） |

::: warning 加新 MCP 工具的检查清单
如果你在开发中给 `apkid-mcp` 加了新工具，记得三处同步：

1. 在 [`apkid/mcp/tools_*.py`](../modules/mcp-tools-scan) 写适配器函数。
2. 在 [`apkid/mcp/server.py`](../modules/mcp-server) 用 `mcp.tool(structured_output=False)(func)` 注册（若想改工具名，用 `mcp.tool(name="...")`）。
3. 在 [`apkid/mcp/tools_info.py`](../modules/mcp-tools-info) 的 `skills()` 函数 `tool_list` 里 **手动加一项**。

漏掉第 3 步，`skills` 工具不会列出新工具（但新工具仍可被调用，因为已注册）。这是硬编码设计的固有维护成本。
:::

## 🔗 调用链

```
MCP client → FastMCP → skills()
                          │
                          └─ 读取硬编码 tool_list（8 项）
                                 │
                                 ├─ sorted(by name)
                                 │
                                 └─ return {error:false, tools:[...], total:8}
```

无外部依赖——不读文件、不加载规则、不构造扫描器。是 8 个工具里最"纯"的一个。

## 📍 相关

- [MCP 概览](./mcp) — 安装、配置、工具清单（人类视角的总览）。
- [AI CLI · skills](./ai-cli-skills) — 对应的 CLI 命令（自省版）。
- [tools_info.py](../modules/mcp-tools-info) — 适配器源码详解。
- [server.py](../modules/mcp-server) — 工具注册处（命令式 `mcp.tool()`）。
- [info 工具](./mcp-info) — 配合 skills 做完整自描述。
- [list_tags 工具](./mcp-list-tags) — 配合 skills 解释检测维度。
