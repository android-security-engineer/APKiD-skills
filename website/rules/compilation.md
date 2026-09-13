# 编译与发布

<span class="badge badge-info">rules.yarc</span>
<span class="badge badge-info">prep-release</span>

源 `.yara` 规则要编译成二进制 `rules.yarc` 才能高效加载。本文讲编译流程与发布约定。

## 🔄 编译流程

```
源 .yara（21 个）           RulesManager
     │                          │
     │  _collect_yara_files()   │  递归收集 *.yara
     ▼                          ▼
Dict[path, path]            compile() → yara.compile(filepaths=...)
     │                          │
     │                          ▼
     │                      yara.Rules 对象
     │                          │
     │                      save() → rules.save('rules.yarc')
     ▼                          ▼
apk/rules/rules.yarc   ←   gitignored，发布产物
     │
     │  load() → yara.load('rules.yarc')   运行时
     ▼
yara.Rules（毫秒级加载）
```

## 🛠️ 编译命令

### 方式一：prep-release.py（推荐）

```bash
python prep-release.py
```

仓库根目录的 `prep-release.py` 调 `RulesManager.compile()` + `.save()`，生成 `apkid/rules/rules.yarc`。它就是为"准备发布"设计的。

### 方式二：AI CLI

```bash
apkid-ai-cli rules compile
```

输出 `{compiled: true, rules_count: 365}`。背后同样是 `compile()` + `save()`。

### 方式三：直接 Python

```python
from apkid.rules import RulesManager
mgr = RulesManager()
mgr.compile()
count = mgr.save()
print(f"compiled {count} rules")
```

## ⏱️ 何时编译

| 时机 | 谁编译 |
|------|--------|
| 改了 `.yara` 源规则后 | 开发者（`prep-release.py`） |
| 打包发 PyPI 前 | `prep-release.py`（rules.yarc 随包分发） |
| CI 测试前 | GitHub Actions（`ci.yml` 的 "Compile YARA rules" 步） |
| 运行时 | **不编译**，只 `load()` |

::: warning clone 后必须编译
`rules.yarc` 是 **gitignored** 的，clone 仓库后不存在。第一次跑前必须 `python prep-release.py`，否则扫描报 `FileNotFoundError: rules.yarc`。PyPI 安装则已预编译。
:::

## 📦 发布到 PyPI

`prep-release.py` 名字即意图——它"准备发布"。发布流程大致：

1. 改 `apkid/__init__.py` 的 `__version__`。
2. 编辑规则（若有）。
3. `python prep-release.py` 编译规则。
4. `python setup.py sdist bdist_wheel` 打包（`rules.yarc` 因 `package_data` 被包含）。
5. `twine upload dist/*`。

`setup.py` 的 `package_data={'rules': package_files('apkid/rules/')}` 确保 `rules.yarc` 和源 `.yara` 都进包。

## 🧪 CI 中的编译

`.github/workflows/ci.yml` 的 test job：

```yaml
- name: Compile YARA rules
  run: python prep-release.py

- name: Run tests
  run: python -m pytest tests/ -q
```

所以 CI 跑测试前会自动编译规则。详见 [GitHub Actions](../deploy/github-actions)。

## 🔢 规则数验证

编译后用 `info` 确认：

```bash
apkid-ai-cli info
# { "version": "3.1.0", "rules_sha256": "...", "rules_count": 365 }
```

`rules_count` 是 `len(set(r.identifier for r in rules))`（去重）。如果为 0，说明 `rules.yarc` 没加载成功。

## 📏 规则哈希

`RulesManager.hash` 对所有源 `.yara` 算 SHA-256。每次扫描输出的 `rules_sha256` 反映用的是哪版规则。改一条规则 → 哈希变。用于结果溯源。

::: tip 哈希基于源文件
哈希算的是源 `.yara` 内容，不是 `rules.yarc`。所以即使忘了重新编译（`rules.yarc` 是旧的），`rules_sha256` 也会反映源规则的新内容——这能帮你发现"改了规则但没重编译"的不一致。
:::

## 📍 相关

- [rules.py](../modules/rules) — RulesManager 源码。
- [规则文件组织](./organization) — 源规则放哪。
- [编写 YARA 规则](./writing-rules) — 改规则后要编译。
- [GitHub Actions](../deploy/github-actions) — CI 自动编译。
