# 开发环境

<span class="badge badge-info">开发</span>
<span class="badge badge-info">贡献</span>

本文讲如何在本地搭建开发环境、修改代码与规则、运行测试。

## 🚀 一次性初始化

```bash
git clone https://github.com/rednaga/APKiD
cd APKiD

# 系统依赖（Linux）
sudo apt-get install -y libyara-dev

# Python 依赖（开发 + 测试 + MCP 全装）
pip install -e ".[dev,test,mcp]"

# 编译 YARA 规则 → 生成 rules.yarc
python prep-release.py
```

`prep-release.py` 做两件事：
1. 调 `RulesManager.compile()` 把所有 `.yara` 编译成 YARA 规则集。
2. 调 `.save()` 写到 `apkid/rules/rules.yarc`。

## 📝 修改 YARA 规则

规则源文件在 `apkid/rules/<filetype>/`，按文件类型分目录。详见 [规则文件组织](../rules/organization)。

改完规则后必须重编译：

```bash
# 方式一：直接跑 prep-release.py
python prep-release.py

# 方式二：用 AI CLI
apkid-ai-cli rules compile
```

::: warning rules.yarc 是 gitignored 的
`rules.yarc` 不进 git。clone 后和每次改规则后都要重编译。CI 会自动编译。发布到 PyPI 前，`prep-release.py` 也会被打包流程调用。
:::

## 🧪 运行测试

```bash
# 全部测试
pytest tests/ -q

# 跳过需要 mcp SDK 的测试
pytest tests/ -q --ignore=tests/test_mcp_server.py

# 只跑一致性检查（plugin ↔ skills ↔ CLI）
pytest tests/test_skills_package.py -q

# 带覆盖率
pytest tests/ --cov=apkid
```

::: tip 测试与 rules.yarc
`scan` 和 `batch` 相关测试会真正跑 YARA，依赖 `rules.yarc` 存在。先跑 `prep-release.py`。只测输出格式化或错误路径的测试不需要它。
:::

### 测试文件一览

| 文件 | 测什么 |
|------|--------|
| `test_scanner.py` | `Scanner` 的扫描、递归、ZIP 处理 |
| `test_rules.py` | `RulesManager` 编译/加载/哈希 |
| `test_ai_output.py` | `AIOutputFormatter` 各字段、置信度推断 |
| `test_mcp_server.py` | MCP 工具适配器（需 `mcp` SDK） |
| `test_skills_package.py` | plugin JS ↔ skills ↔ CLI 三者一致性 |
| `factories.py` | `factory_boy` 测试数据工厂 |
| `conftest.py` | pytest fixtures |

## 🧱 添加新功能：CLI 命令 + MCP 工具 + Skill

参考 `CLAUDE.md` 的"Adding a New Skill"清单：

1. 创建 `.claude/skills/apkid-<name>/SKILL.md`（含 YAML frontmatter：name、description、allowed-tools）
2. 在 `.claude/plugins/ai-apkid.js` 里登记该 skill
3. 创建 `apkid/cli/cmd_<name>.py`，写一个 typer 命令函数
4. 在 `apkid/cli/app.py` 的 `_register_commands()` 里注册
5. 若要 MCP：在 `apkid/mcp/tools_*.py` 加适配函数，在 `server.py` 用 `mcp.tool(...)` 注册
6. 在 `tests/` 加测试
7. 跑 `test_skills_package.py` 验证三者一致

## 🐍 添加新的检测类别

如果你加了一条带 **新 tag** 的 YARA 规则（比如 `: tpm_check`），要同步更新 [`apkid/ai_output.py` 的 `RULE_DESCRIPTIONS`](../modules/ai-output)：

```python
RULE_DESCRIPTIONS = {
    ...
    "tpm_check": "Detects TPM chip checks (new category)",
}
```

否则 `_categorize_tag()` 会把它归到默认的 `abnormal` 类别，描述显示为 "Unknown detection category"。

## 🔍 代码风格

- 类型注解：新代码用 `typing` 注解（CLI/MCP 模块都有）。
- 错误输出：CLI/MCP 错误统一走 `common.error_exit()`，输出 `{"error": true, "message": ..., "detail": ...}` 到 stderr。
- 输出 schema：所有 AI 输出带 `"schema_version": "1.0.0"`，破坏性变更要 bump。

## 🧹 提交前检查

CI（`.github/workflows/ci.yml`）会做这些检查，本地最好也跑：

```bash
# Python 语法检查（CI 列出的文件）
python -m py_compile apkid/ai_output.py
python -m py_compile apkid/cli/app.py
# ... 其余 cli 文件

# 插件 JS 校验
node -e "const p = require('./.claude/plugins/ai-apkid.js'); console.log(p.name, p.skills.length)"

# SKILL.md frontmatter 检查
for dir in .claude/skills/apkid-*/; do
  grep -q "^name:" "$dir/SKILL.md" && grep -q "^description:" "$dir/SKILL.md" \
    && echo "OK: $(basename $dir)"
done

# 规则编译
python prep-release.py

# 测试
pytest tests/ -q
```

## 📍 下一步

- [规则文件组织](../rules/organization) — 规则放哪、怎么命名。
- [编写 YARA 规则](../rules/writing-rules) — 怎么写一条新规则。
- [代码模块文档](../modules/core-apkid) — 改代码前先读懂它。
