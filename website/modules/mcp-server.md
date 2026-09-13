# mcp/server.py — FastMCP 服务器

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">FastMCP</span>

`apkid/mcp/server.py` 创建 FastMCP 实例并注册所有 MCP 工具。是 `apkid-mcp` 命令的根。

## 📋 文件内容

| 符号 | 类型 | 说明 |
|------|------|------|
| `MCP_SERVER_NAME` | str | `"apkid"` |
| `MCP_SERVER_INSTRUCTIONS` | str | 服务器说明（给客户端看） |
| `mcp` | `FastMCP` | 服务器实例 |
| `run()` | func | console script 入口 |

## 🧱 FastMCP 实例

```python
mcp = FastMCP(
    MCP_SERVER_NAME,                       # "apkid"
    instructions=MCP_SERVER_INSTRUCTIONS,
)
```

FastMCP 是 MCP Python SDK（`mcp>=1.0.0,<2.0.0`）的高层 API。它自动处理：
- **协议序列化**（JSON-RPC over stdio）
- **工具 schema 生成**（从函数类型注解 + docstring）
- **stdio 传输**

我们 **不**自己写任何 MCP 协议细节。

## 📜 MCP_SERVER_INSTRUCTIONS

```
APKiD MCP Server — Android APK/DEX/ELF identifier.
Use scan_file to detect packers, protectors, obfuscators, and compilers.
Use batch_scan for directories, diff_files to compare two files,
type_file for fast file-type identification.
Use info/list_tags/rules/skills for metadata and self-discovery.
```

客户端连接时拿到这段说明，知道有哪些工具、各自干什么。这是 MCP 协议的 `instructions` 字段。

## 🛠️ 工具注册

```python
# 扫描工具
mcp.tool(structured_output=False)(scan_file)
mcp.tool(structured_output=False)(batch_scan)
mcp.tool(structured_output=False)(diff_files)
mcp.tool(structured_output=False)(type_file)

# 信息工具
mcp.tool(structured_output=False)(info)
mcp.tool(name="list-tags", structured_output=False)(list_tags)   # 名字带连字符
mcp.tool(structured_output=False)(rules)
mcp.tool(structured_output=False)(skills)
```

### 为什么 `structured_output=False`

FastMCP 默认会把函数返回类型注解（如 `str`、`Dict[str, Any]`）转成 pydantic 模型再序列化。这对我们的 `str` 返回（JSON 字符串）会出问题——当前 SDK + pydantic v2 组合下会失败。所以统一 `structured_output=False`，让 FastMCP 把返回值当 **纯文本内容** 包装进 MCP 响应。

我们的工具函数自己 `json.dumps()` 返回 JSON 字符串，客户端拿到的是文本块里装着的 JSON——解析方负责 `JSON.parse`。

### 名字重映射

`list_tags` 函数 → 工具名 `list-tags`（连字符），与 CLI 的 `list-tags` 命令对齐。

## 🚪 run()

```python
def run():
    """Entry point for the apkid-mcp console script."""
    mcp.run()
```

`setup.py` 注册 `apkid-mcp=apkid.mcp:run`。`mcp.run()` 启动 stdio 传输，阻塞等待客户端请求。

## 📦 版本说明

源码注释强调：

> FastMCP 移除了 `version=` 构造参数（在我们 `mcp>=1.0.0,<2.0.0` 范围内）。服务器版本通过包本身（`apkid.__version__`）和 `info` 工具暴露——**不要**在这里重新加 `version=`。

所以版本信息靠 `info` 工具的 `version` 字段返回，不靠 FastMCP 构造参数。

## 🔗 工具清单

| 工具 | 函数 | 模块 |
|------|------|------|
| `scan_file` | `scan_file` | [tools_scan.py](./mcp-tools-scan) |
| `batch_scan` | `batch_scan` | [tools_scan.py](./mcp-tools-scan) |
| `diff_files` | `diff_files` | [tools_scan.py](./mcp-tools-scan) |
| `type_file` | `type_file` | [tools_scan.py](./mcp-tools-scan) |
| `info` | `info` | [tools_info.py](./mcp-tools-info) |
| `list-tags` | `list_tags` | [tools_info.py](./mcp-tools-info) |
| `rules` | `rules` | [tools_info.py](./mcp-tools-info) |
| `skills` | `skills` | [tools_info.py](./mcp-tools-info) |

与 CLI 命令 **一一对应**（`diff_files` vs `diff`、`batch_scan` vs `batch` 是命名差异）。

## 🧱 隔离原则

`apkid.mcp` 只 import `apkid.cli.common` 和 `apkid.ai_output`，**绝不反向依赖**。这让 MCP 是可选 extras：

```bash
pip install apkid[mcp]   # 才装 mcp SDK
```

不装 `mcp` 也能用 `apkid` / `apkid-ai-cli`。CI 的 `lint` job 不装 mcp 也能跑 `py_compile`。

## 📍 相关

- [MCP 概览](../interfaces/mcp) — 用户视角与客户端配置。
- [tools_scan.py](./mcp-tools-scan) — 扫描工具适配器。
- [tools_info.py](./mcp-tools-info) — 信息工具适配器。
- [架构概览](../guide/architecture) — MCP 隔离原则。
