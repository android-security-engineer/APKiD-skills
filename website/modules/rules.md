# rules.py — YARA 规则管理

<span class="badge badge-info">RulesManager</span>
<span class="badge badge-info">YARA</span>

`apkid/rules.py` 定义 `RulesManager`——负责 YARA 规则的发现、编译、加载、哈希。它把"规则是数据"这件事封装干净。

## 📋 文件内容

只有一个类 `RulesManager`。

## 🧱 RulesManager

### 构造

```python
def __init__(self, rules_dir=None, rules_ext='.yara'):
    if not rules_dir:
        rules_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'rules')
    self.rules_dir = rules_dir                # apkid/rules/
    self.rules_path = os.path.join(rules_dir, 'rules.yarc')  # 编译产物路径
    self.rules_ext = '.yara'
    self.rules = None                         # 加载后的 yara.Rules
    self.rules_hash = None                    # SHA-256（惰性）
```

默认 `rules_dir` 是 `apkid/rules/`（相对本文件定位），可传入自定义目录（测试用）。

### load()

```python
def load(self) -> yara.Rules:
    self.rules = yara.load(self.rules_path)
    return self.rules
```

加载预编译的 `rules.yarc`。**运行时只调这个**，毫秒级。如果 `rules.yarc` 不存在会抛异常——所以源码安装后必须先 `prep-release.py`。

### _collect_yara_files()

```python
def _collect_yara_files(self) -> Dict[str, str]:
    files = {}
    for root, dirnames, filenames in os.walk(self.rules_dir):
        for filename in filenames:
            if not filename.lower().endswith(self.rules_ext):
                continue
            path = os.path.join(root, filename)
            files[path] = path
    return files
```

递归收集所有 `.yara` 源文件。返回 `Dict[路径, 路径]`（key=value，供 `yara.compile(filepaths=...)` 用）。`rules.yarc` 不以 `.yara` 结尾，自动被排除。

### compile()

```python
def compile(self) -> yara.Rules:
    yara_files = self._collect_yara_files()
    self.rules = yara.compile(filepaths=yara_files)
    return self.rules
```

把所有源 `.yara` 编译成 `yara.Rules`。**只在开发/打包时调**，较慢（要解析全部规则 + DEX 模块）。

### save()

```python
def save(self) -> int:
    self.rules.save(self.rules_path)
    return len(set(r.identifier for r in self.rules))   # 去重后的规则数
```

写出 `rules.yarc`，返回规则数（去重）。`prep-release.py` 和 `apkid-ai-cli rules compile` 都走 `compile()` + `save()`。

### hash（property）

```python
@property
def hash(self) -> str:
    if not self.rules_hash:
        h = hashlib.sha256()
        for file_path in self._collect_yara_files():
            with open(file_path, 'rb') as f:
                h.update(f.read())
        self.rules_hash = h.hexdigest()
    return self.rules_hash
```

对所有源 `.yara` 文件算 SHA-256（**按收集顺序**，非排序）。惰性计算，首次访问后缓存。

::: tip 哈希的含义
它反映的是 **源规则** 的内容指纹，不是 `rules.yarc` 的指纹。改一条规则 → 哈希变 → 每次扫描输出的 `rules_sha256` 变。可用于"这次扫描用的是哪版规则"溯源。
:::

注意：哈希基于 `os.walk` 的遍历顺序，跨平台可能不同（Linux 通常稳定，Windows 看文件系统）。所以它适合 **同一环境的版本对比**，不适合跨平台精确比对。

## 🔄 完整生命周期

```
开发                          运行
 │                             │
 ▼                             ▼
编辑 apkid/rules/*.yara     RulesManager()
 │                             │
 ▼                             ▼
.compile()  ← yara.compile   .load() ← yara.load('rules.yarc')
 │                             │
 ▼                             ▼
.save() → rules.yarc         self.rules（毫秒级）
 │                             │
 ▼                             ▼
gitignore，随包分发          Scanner 用它匹配
```

## 🔗 谁用它

- [`Options`](./core-apkid) 构造时 `self.rules_manager = RulesManager()`，但 `Options` 不主动 `load()`——由 Scanner 调用方决定。
- [`common.make_scanner()`](./cli-common)：`RulesManager().load()` 后传给 `Scanner`。
- `cmd_info` / MCP `info`：取 `.hash` 和 `.load()` 后的规则数。
- `cmd_rules` / MCP `rules`：`compile()` + `save()`。
- 经典 `main.py`：`options.rules_manager.load()`。

## 📍 相关

- [YARA 规则系统](../guide/yara-system) — 规则的全貌。
- [编译与发布](../rules/compilation) — `prep-release.py` 流程。
- [规则文件组织](../rules/organization) — `.yara` 怎么放。
