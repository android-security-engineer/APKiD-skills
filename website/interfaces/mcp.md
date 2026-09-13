# MCP 概览

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">FastMCP</span>

`apkid-mcp` 把 APKiD 暴露为 [Model Context Protocol](https://modelcontextprotocol.io) 服务器。MCP 客户端（Claude Desktop、Cursor 等）可直接调用扫描工具，无需切终端。

## 🔌 安装与启动

```bash
pip install apkid[mcp]
apkid-mcp    # stdio 传输，阻塞等待客户端
```

`mcp` 是可选 extras（`mcp>=1.0.0,<2.0.0`）。不装也能用 `apkid`/`apkid-ai-cli`。

## ⚙️ 客户端配置

### Claude Desktop

编辑配置文件（macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`）：

```json
{
  "mcpServers": {
    "apkid": {
      "command": "apkid-mcp"
    }
  }
}
```

### Cursor / 其它 MCP 客户端

按客户端文档配置 stdio 类 MCP 服务器，命令填 `apkid-mcp`，无参数。

### Docker

```bash
docker run --rm -i rednaga:apkid apkid-mcp
```

`-i` 保持 stdin 打开（stdio 传输需要）。

## 📋 工具清单

| 工具 | 作用 | 文档 |
|------|------|------|
| `scan_file` | 扫描单文件 | [→](./mcp-scan-file) |
| `batch_scan` | 批量扫描目录 | [→](./mcp-batch-scan) |
| `diff_files` | 对比两文件 | [→](./mcp-diff-files) |
| `type_file` | 识别文件类型 | [→](./mcp-type-file) |
| `info` | 版本 + 规则信息 | [→](./mcp-info) |
| `list_tags` | 所有检测类别 | [→](./mcp-list-tags) |
| `rules` | 规则管理 | [→](./mcp-rules) |
| `skills` | 自发现工具列表 | [→](./mcp-skills) |

工具与 AI CLI 命令 **一一对应**，参数也基本一致。

## 🤖 在 Claude 里的使用

配置好后，你可以直接对 Claude 说：

> "帮我扫描 /path/to/app.apk，看看用了什么加固"

Claude 会自动调用 `scan_file` 工具，拿到 JSON 结果，然后用自然语言解读。它也能：

- 先调 `info` / `list_tags` / `skills` 了解能力。
- 调 `type_file` 探类型，再决定是否 `scan_file`。
- 调 `batch_scan` 批量分析后，用 `diff_files` 对比两个样本。
- 调 `rules list` 看有哪些规则文件。

## 📤 工具返回格式

所有工具返回 **JSON 字符串**（`structured_output=False`，FastMCP 包成文本内容响应）。客户端拿到的是文本块里的 JSON，需 `JSON.parse`。结构详见 [AI 输出格式](../guide/output-format)——与 AI CLI 完全一致。

## 🧱 设计要点

- **共享 `make_scanner()`**：MCP 工具与 AI CLI 走同一扫描代码，结果一致。
- **隔离**：`apkid.mcp` 只依赖 `apkid.cli.common` 和 `apkid.ai_output`，不反向依赖。
- **错误不退出**：工具失败时 `return` 错误 JSON（`{error:true,...}`），而非 `sys.exit`——MCP 工具不该让进程退出。
- **无进度条**：`batch_scan` 不像 CLI `batch` 那样显示进度（MCP 调用是请求-响应，不适合流式进度）。

## 📋 `skills` 工具的特殊性

MCP 的 `skills` 工具 **硬编码** 了 8 个工具列表（不像 CLI `skills` 自省 `registered_commands`）。所以新增 MCP 工具时，要在 `tools_info.skills()` 的列表里手动加一项。详见 [tools_info.py](../modules/mcp-tools-info)。

## 🐛 排错

| 现象 | 原因 |
|------|------|
| 客户端连不上 | `apkid-mcp` 不在 PATH，或没装 `[mcp]` extras |
| 工具调用报 `rules.yarc not found` | 源码安装没编译规则，跑 `python prep-release.py` |
| 扫描超时 | 调大 `timeout` 参数（默认 30 秒） |
| 大 APK 扫不完 | `scan_depth` 或 `entry_max_scan_size`（MCP 固定 0 不限） |

## 📍 相关

- 各工具详解（见上表）。
- [server.py](../modules/mcp-server) — FastMCP 服务器源码。
- [tools_scan.py](../modules/mcp-tools-scan) / [tools_info.py](../modules/mcp-tools-info) — 适配器。
- [三种接口对比](./overview) — 与 CLI 对比。
- [Docker 运行](../guide/docker) — 容器化 MCP。
