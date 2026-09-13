# __init__.py — 版本信息

<span class="badge badge-info">元信息</span>

`apkid/__init__.py` 只放包的元数据，但被很多地方引用，是版本号的 **唯一真实来源**。

## 📋 内容

```python
__title__ = 'apkid'
__version__ = '3.1.0'
__author__ = 'Caleb Fenton & Tim Strazzere'
__license__ = 'GPL & Commercial'
__copyright__ = 'Copyright (C) 2026 RedNaga'
```

## 🔗 谁引用它

| 引用方 | 用哪个字段 |
|--------|-----------|
| `setup.py` | `__title__`、`__version__`、`__author__`、`__license__` |
| [`ai_output.py`](./ai-output) | `__version__`（写进输出，间接） |
| [`output.py`](./output) | `__version__`（经典输出 `apkid_version` 字段） |
| `cmd_info` / MCP `info` | `__version__`（`apkid-ai-cli info` 的 `version` 字段） |
| `main.py` | `__version__`（启动横幅 `[+] APKiD 3.1.0 :: ...`） |

## 📦 版本号约定

`3.1.0` 是语义化版本。改动类型：

- **patch**（`3.1.0` → `3.1.1`）：bug 修复、规则补充。
- **minor**（`3.1.0` → `3.2.0`）：新功能、新命令、新规则类别。
- **major**（`3.1.0` → `4.0.0`）：破坏性变更（如 `SCHEMA_VERSION` bump、命令重命名）。

`SCHEMA_VERSION`（AI 输出 schema）与 `__version__`（包版本）是 **独立**的——包版本每次发版都动，schema 版本只在输出结构破坏性变更时动。

## 📍 相关

- [AI 输出格式](../guide/output-format) — `schema_version` 与 `__version__` 的区别。
- [cmd_info.py](./cli-cmd-info) — `info` 命令暴露版本。
