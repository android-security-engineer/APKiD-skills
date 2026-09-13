# 架构概览

<span class="badge badge-info">架构</span>
<span class="badge badge-info">CLI</span>
<span class="badge badge-info">MCP</span>

APKiD-skills 的核心架构原则是：**三个接口共享同一套扫描逻辑，绝不重复实现**。

## 🏛️ 三层架构

```
┌─────────────────────────────────────────────────────────┐
│  接口层（三种入口，同一引擎）                              │
│                                                         │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │ 经典 CLI    │  │ AI CLI       │  │ MCP 服务器     │ │
│  │ apkid       │  │ apkid-ai-cli │  │ apkid-mcp      │ │
│  │ (argparse)  │  │ (typer+rich) │  │ (FastMCP)      │ │
│  └──────┬──────┘  └──────┬───────┘  └───────┬────────┘ │
└─────────┼────────────────┼──────────────────┼──────────┘
          │                │                  │
          │     经典入口独立   │ 共享             │ 共享
          ▼                ▼                  ▼
                     ┌─────────────┐
                     │ common      │   ← 公共桥梁
                     │ make_scanner│
                     │ output_result
                     │ error_exit  │
                     └──────┬──────┘
                            │
          ┌─────────────────┼──────────────────┐
          ▼                 ▼                  ▼
   ┌────────────┐  ┌──────────────────┐  ┌──────────────┐
   │ OutputFormatter │ │ AIOutputFormatter │ │ RulesManager │
   │ (经典彩色/JSON) │ │ (结构化 finding)  │ │ (YARA 加载)  │
   └────────────┘  └──────────────────┘  └──────────────┘
                            │
                            ▼
                   ┌────────────────┐
                   │  apkid.apkid   │   ← 扫描引擎
                   │  Scanner       │
                   │  Options       │
                   └───────┬────────┘
                           │
                           ▼
                   ┌────────────────────┐
                   │  YARA 引擎          │
                   │  yara-python-dex   │
                   │  + rules.yarc      │
                   └────────────────────┘
```

## 🔑 关键设计原则

### 1. CLI 与 MCP 共享 `make_scanner()`

[AI CLI](../modules/cli-common) 和 [MCP 服务器](../modules/mcp-server) 的每个命令/工具，都通过 `apkid.cli.common.make_scanner()` 创建 `Scanner`，再用 `AIOutputFormatter` 格式化输出。

```python
# apkid/cli/common.py
def make_scanner(timeout=30, typing="magic", scan_depth=2, ...):
    rules_mgr = RulesManager()
    rules = rules_mgr.load()          # 加载 rules.yarc
    options = Options(timeout=..., typing=..., scan_depth=..., ...)
    return Scanner(rules=rules, options=options)
```

这意味着 **AI CLI 和 MCP 永远返回一致的结果**——它们调的是同一份代码。修一个 bug，两边都修好。

### 2. MCP 模块是隔离的

`apkid.mcp` 只 import `apkid.cli.common` 和 `apkid.ai_output`，**绝不反向依赖**。这让 MCP 是个可选 extras（`pip install apkid[mcp]`），不装 `mcp` SDK 也能用 CLI。

### 3. 经典 CLI 保留独立路径

`apkid`（经典 CLI，`apkid.main:main`）走 `argparse` → `Options` → `Scanner` → `OutputFormatter`，不经过 `common.make_scanner()`。这是历史原因——经典 CLI 的 `OutputFormatter` 与 AI 的 `AIOutputFormatter` 输出风格不同，且经典 CLI 支持 `--output-dir` 写多文件。

### 4. 规则与代码分离

规则是数据（`.yara` 文件 → `rules.yarc`），代码是引擎。新增一个加固检测，通常 **只改规则、不改代码**：写一条 `.yara`，`prep-release.py` 重编译即可。

## 📦 包结构

```
apkid/
├── __init__.py          # 版本号、作者、许可
├── apkid.py             # ★ 扫描引擎核心：Scanner、Options、文件类型魔数
├── ai_output.py         # ★ AI 输出格式化 + RULE_DESCRIPTIONS 检测类别字典
├── output.py            # 经典输出格式化（彩色终端 / JSON）
├── main.py              # 经典 CLI 入口（argparse）
├── rules.py             # RulesManager：YARA 规则编译/加载/哈希
├── cli/                 # AI CLI（typer）
│   ├── app.py           # Typer 应用 + 命令注册
│   ├── common.py        # ★ make_scanner / output_result / error_exit
│   ├── __main__.py      # python -m 入口
│   ├── cmd_scan.py      # scan 命令
│   ├── cmd_batch.py     # batch 命令
│   ├── cmd_diff.py      # diff 命令
│   ├── cmd_type.py      # type 命令
│   ├── cmd_info.py      # info 命令
│   ├── cmd_tags.py      # list-tags 命令
│   ├── cmd_rules.py     # rules 命令
│   └── cmd_skills.py    # skills 命令
├── mcp/                 # MCP 服务器（FastMCP）
│   ├── server.py        # FastMCP 实例 + 工具注册
│   ├── tools_scan.py    # scan_file / batch_scan / diff_files / type_file
│   └── tools_info.py    # info / list_tags / rules / skills
└── rules/               # YARA 规则源文件（按文件类型分目录）
    ├── apk/  dex/  elf/  dll/  res/
    └── rules.yarc       # 编译产物（gitignored）
```

★ 标记的是最常被复用的核心文件。

## 🚪 三个入口点

`setup.py` 注册了三个 console script：

| 命令 | 入口函数 | 文件 |
|------|---------|------|
| `apkid` | `apkid.main:main` | `main.py` |
| `apkid-ai-cli` | `apkid.cli:ai_cli` | `cli/app.py` |
| `apkid-mcp` | `apkid.mcp:run` | `mcp/server.py` |

## 🔁 数据流对比

以"扫描一个 APK"为例，三个接口的路径：

**经典 CLI：**
```
apkid app.apk
  → main.py 解析 argparse
  → Options(rules_manager=RulesManager())
  → Scanner(rules, options).scan('app.apk')
  → OutputFormatter.write() → 彩色终端 / JSON
```

**AI CLI：**
```
apkid-ai-cli scan app.apk
  → cmd_scan.scan() 解析 typer 参数
  → common.make_scanner()   ← 共享
  → scanner.scan_file('app.apk')
  → AIOutputFormatter.format() → 结构化 JSON
```

**MCP：**
```
MCP client 调 scan_file 工具
  → mcp.tools_scan.scan_file(target, ...)
  → common.make_scanner()   ← 同一个
  → scanner.scan_file(target)
  → AIOutputFormatter.format_dict() → JSON 字符串
  → FastMCP 包装成 MCP 响应
```

AI CLI 与 MCP 的代码路径几乎逐行对应，只在参数来源（typer vs MCP schema）和返回形式（stdout vs MCP 响应）上不同。

## 📍 下一步

- [三种接口对比](../interfaces/overview) — 何时用哪个。
- [代码模块文档](../modules/core-apkid) — 逐文件深入。
- [检测规则总览](../rules/overview) — 规则如何组织。
