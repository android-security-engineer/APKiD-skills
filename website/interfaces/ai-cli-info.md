# AI CLI · info — 版本与规则信息

<span class="badge badge-info">AI CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-success">元数据</span>

ℹ️ `apkid-ai-cli info` 输出 APKiD 版本号、规则 SHA-256 哈希、规则数量。无参数，秒出。用于排查"我这台机器上的规则是不是最新的"、做结果溯源、或在 CI 里固定规则版本。

## 🚀 一行用法

```bash
apkid-ai-cli info
```

## 🖥️ 命令签名

```bash
apkid-ai-cli info
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| — | — | — | **无参数** |

## 📤 输出示例

```bash
apkid-ai-cli info
```

```json
{
  "version": "1.3.4",
  "rules_sha256": "a1b2c3d4e5f6...（64 位十六进制）",
  "rules_count": 142
}
```

字段说明：

| 字段 | 含义 |
|------|------|
| `version` | APKiD 包版本号，取自 `apkid.__version__` |
| `rules_sha256` | 所有 YARA 源文件（`.yara`）内容的 SHA-256 哈希，64 位十六进制字符串 |
| `rules_count` | 去重后的规则数量（`r.identifier` 去重计数） |

## 🔍 字段细节

### `rules_count` 怎么来

```python
rules_mgr = RulesManager()
rules = rules_mgr.load()                       # 加载 rules.yarc
rules_count = len(set(r.identifier for r in rules))   # 去重计数
```

- 先 `yara.load(rules.yarc)` 加载编译后的规则。
- 对所有规则的 `identifier`（即规则名）做 `set` 去重，再 `len`。
- 去重是因为同一规则名可能在不同 `.yara` 文件里出现，或 namespace 重复。

::: warning 规则加载失败时 rules_count = 0
`load()` 包在 `try/except` 里。如果 `rules.yarc` 不存在（比如没跑 `prep-release.py`）或损坏，会抛异常被吞掉，`rules_count` 回退为 `0`。看到 `rules_count: 0` 先检查是否编译过规则：

```bash
# rules.yarc 不存在 → rules_count=0
ls apkid/rules/rules.yarc 2>/dev/null || echo "未编译，跑 prep-release.py 或 apkid-ai-cli rules compile"
```
:::

### `rules_sha256` 的用途

```python
h = hashlib.sha256()
for file_path in self._collect_yara_files():
    with open(file_path, 'rb') as f:
        h.update(f.read())
self.rules_hash = h.hexdigest()
```

- 遍历 `apkid/rules/` 下所有 `.yara` 源文件，把每个文件内容喂进 SHA-256。
- 注意：**哈希的是源文件，不是 `rules.yarc`**。所以即便没编译，只要源规则在，`rules_sha256` 也能算出来。
- 用途：
  - **规则版本溯源**：两台机器 `rules_sha256` 一致 → 规则集完全相同，扫描结果可对比。
  - **CI 固定版本**：在流水线里断言 `rules_sha256 == 期望值`，规则被悄悄改动时 CI 失败。
  - **结果可复现**：扫描报告里带上 `rules_sha256`，他人能用相同规则集复现你的检测。

::: tip rules_sha256 不同于 rules.yarc 的哈希
`rules_sha256` 反映源规则内容；`rules.yarc` 是编译产物（gitignored），其字节哈希会随 yara-python 版本变化。所以跨环境对齐规则版本，看 `rules_sha256` 而非编译产物哈希。
:::

### `version`

取 `apkid/__init__.py` 的 `__version__`。用于确认安装的 APKiD 版本，配合 [list-tags](./ai-cli-list-tags) 判断当前版本支持哪些检测类别。

## 🧪 示例命令

```bash
# 看版本和规则数
apkid-ai-cli info

# CI 里固定规则版本
EXPECTED="a1b2c3d4..."
ACTUAL=$(apkid-ai-cli info | jq -r '.rules_sha256')
[ "$ACTUAL" = "$EXPECTED" ] || { echo "规则版本漂移！"; exit 1; }

# 两台机器对齐规则集
# 机器 A: apkid-ai-cli info | jq -r '.rules_sha256'
# 机器 B: apkid-ai-cli info | jq -r '.rules_sha256'
# 相同 → 扫描结果可比

# 排查"扫不出东西"
apkid-ai-cli info | jq '.rules_count'   # 0 说明规则没编译
```

::: tip 配合 rules compile
如果 `rules_count: 0`，运行 `apkid-ai-cli rules compile` 重新编译 `rules.yarc`，再 `info` 确认 `rules_count` 恢复正常。
:::

## 📍 相关

- [info 命令源码](../modules/cli-cmd-info) — `cmd_info.py` 实现。
- [规则系统](../modules/rules) — `RulesManager` 的 `hash`/`load` 方法。
- [rules 命令](./ai-cli-rules) — 重新编译规则。
- [list-tags 命令](./ai-cli-list-tags) — 规则能检测哪些类别。
- [AI CLI 概览](./ai-cli) — 全部命令索引。
