# 快速开始

<span class="badge badge-info">5 分钟上手</span>

本文用最短的路径让你跑通第一次扫描。

## 📦 安装

```bash
pip install apkid
```

::: tip 规则已预编译
PyPI 包内置编译好的 `rules.yarc`，装完即可用，无需自己编译。只有当你自己改了 `.yara` 源规则时才需要重编译（见[开发环境](./development)）。
:::

## 🚀 第一次扫描

```bash
# AI CLI：结构化 JSON 输出（推荐，AI 友好）
apkid-ai-cli scan /path/to/app.apk
```

输出示例（节选）：

```json
{
  "schema_version": "1.0.0",
  "error": false,
  "target": "/path/to/app.apk",
  "findings": [
    {
      "tag": "packer::jiagu_360_v5",
      "category": "packer",
      "description": "Detects APK packing/obfuscation tools",
      "source": "/path/to/app.apk!assets/libjiagu.so",
      "identifier": "jiagu_360_v5",
      "confidence": "low"
    },
    {
      "tag": "compiler::dx",
      "category": "compiler",
      "source": "/path/to/app.apk!classes.dex",
      "identifier": "dx",
      "confidence": "high"
    }
  ],
  "summary": {
    "total_findings": 2,
    "categories": { "packer": 1, "compiler": 1 }
  }
}
```

## 🎨 经典彩色输出

```bash
# 经典 CLI：终端彩色表格
apkid /path/to/app.apk
```

```
[+] APKiD 3.1.0 :: from RedNaga :: rednaga.io
[*] /path/to/app.apk!classes.dex
 |-> compiler : dx
[*] /path/to/app.apk!assets/libjiagu.so
 |-> packer : 360 Jiagu v5
```

## 🧰 常用操作

```bash
# 扫描整个目录（递归）
apkid-ai-cli batch /path/to/samples/ --recursive --pattern "*.apk"

# 对比两个版本，看新增/移除了哪些保护
apkid-ai-cli diff app-v1.apk app-v2.apk

# 只看文件类型（不加载 YARA，秒出）
apkid-ai-cli type /path/to/file

# 查看版本与规则信息
apkid-ai-cli info

# 列出所有检测类别
apkid-ai-cli list-tags

# 文本格式输出（更适合人读）
apkid-ai-cli scan app.apk --format text
```

## 🤖 用作 MCP 服务器

如果你在用支持 MCP 的客户端（如 Claude Desktop、Cursor）：

```bash
pip install apkid[mcp]
apkid-mcp   # stdio transport
```

在客户端的 MCP 配置里加上：

```json
{
  "mcpServers": {
    "apkid": {
      "command": "apkid-mcp"
    }
  }
}
```

之后 AI 就能直接调用 `scan_file`、`batch_scan` 等工具。详见 [MCP 概览](../interfaces/mcp)。

## 🐳 Docker

```bash
docker build . -t rednaga:apkid
docker run --rm -v /path/to/samples:/input:ro rednaga:apkid apkid-ai-cli scan /input/app.apk
```

详见 [Docker 运行](./docker)。

## ❓ 出错了？

| 现象 | 原因与解决 |
|------|-----------|
| `FileNotFoundError: rules.yarc` | 源码安装后没编译规则。运行 `python prep-release.py` |
| `yara.Error: ... dex module` | 没装 `yara-python-dex`，装了普通 `yara-python`。`pip install yara-python-dex` |
| 扫描结果为空 | 文件不是支持的格式，或 `--typing` 太严。试试 `--typing none` |
| 扫描很慢 | `--typing none` 会扫所有条目；改回 `magic` 并加 `--entry-max-scan-size` |

## 📍 下一步

- [安装指南](./installation) — 各平台详细安装。
- [AI CLI 概览](../interfaces/ai-cli) — 每个命令详解。
- [检测类别](./categories) — 理解输出的 `category` 字段。
