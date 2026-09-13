# 安装指南

<span class="badge badge-info">安装</span>
<span class="badge badge-info">依赖</span>

APKiD 的核心依赖是 `yara-python-dex`（带 DEX 模块的 YARA 分支），它需要 `libyara`。下面按平台说明。

## 📋 系统要求

- **Python** ≥ 3.9（CI 测试覆盖 3.9 / 3.10 / 3.11 / 3.12）
- **libyara-dev**（系统库，编译 `yara-python-dex` 时需要）
- 可选：`mcp` SDK（仅 MCP 服务器需要）

## 🐧 Linux（Debian/Ubuntu）

```bash
# 1. 系统依赖
sudo apt-get update
sudo apt-get install -y libyara-dev

# 2. 安装 APKiD
pip install apkid
```

## 🍎 macOS

```bash
# 1. 用 Homebrew 装 libyara
brew install yara

# 2. 安装 APKiD
pip install apkid
```

::: tip 编译 yara-python-dex 失败？
macOS 上若 `pip install` 报 `yara.h not found`，设置环境变量让编译器找到 brew 安装的头文件：

```bash
export CFLAGS="-I$(brew --prefix yara)/include"
export LDFLAGS="-L$(brew --prefix yara)/lib"
pip install yara-python-dex
```
:::

## 🪟 Windows

Windows 上 `yara-python-dex` 通常提供预编译 wheel，多数情况下直接：

```powershell
pip install apkid
```

即可。若没有匹配的 wheel 需要源码编译，则需 Visual Studio Build Tools。

## 🐳 Docker（跨平台最省心）

```bash
git clone https://github.com/rednaga/APKiD
cd APKiD
docker build . -t rednaga:apkid
```

详见 [Docker 运行](./docker)。

## 🔧 可选 extras

`setup.py` 定义了三个可选依赖组：

| extras | 安装命令 | 用途 |
|--------|---------|------|
| `dev` | `pip install -e ".[dev]"` | 开发：mypy、pypandoc、twine |
| `test` | `pip install -e ".[test]"` | 测试：pytest、factory_boy、mock 等 |
| `mcp` | `pip install apkid[mcp]` | MCP 服务器：`mcp>=1.0.0,<2.0.0` |

全装（开发环境）：

```bash
pip install -e ".[dev,test,mcp]"
```

## 🛠️ 从源码安装（开发）

```bash
git clone https://github.com/rednaga/APKiD
cd APKiD

# 安装系统依赖（Linux）
sudo apt-get install -y libyara-dev

# 安装 Python 依赖（含 dev/test/mcp）
pip install -e ".[dev,test,mcp]"

# 编译 YARA 规则（生成 rules.yarc）
python prep-release.py
```

::: warning 别忘了 prep-release.py
源码仓库里 `rules.yarc` 是 **gitignored** 的。clone 后必须运行 `python prep-release.py` 编译规则，否则扫描会因找不到 `rules.yarc` 而报错。PyPI 包则已预编译好。
:::

详见 [开发环境](./development)。

## ✅ 验证安装

```bash
# 看版本和规则信息
apkid-ai-cli info
```

应输出类似：

```json
{
  "version": "3.1.0",
  "rules_sha256": "abc123...(规则集指纹)",
  "rules_count": 365
}
```

`rules_count` 应为 365 左右（随版本变化）。如果 `rules_count` 是 0，说明 `rules.yarc` 没加载成功，回到上一步检查。

## 📍 下一步

- [快速开始](./quickstart) — 跑第一次扫描。
- [Docker 运行](./docker) — 容器化部署。
- [开发环境](./development) — 改代码、加规则。
