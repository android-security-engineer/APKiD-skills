# AI CLI · rules — 规则管理

<span class="badge badge-info">AI CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-warning">规则</span>

🛠️ `apkid-ai-cli rules` 管理 YARA 规则：列出全部 `.yara` 源文件，或重新编译生成 `rules.yarc`。改了源规则后必须跑 `compile`，否则扫描用的还是旧编译产物。

## 🚀 一行用法

```bash
apkid-ai-cli rules list       # 列源文件
apkid-ai-cli rules compile    # 重新编译
```

## 🖥️ 命令签名

```bash
apkid-ai-cli rules <action>
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `action` | `str`（必填） | — | 动作：`list` 列出规则文件，`compile` 重新编译 `rules.yarc` |

`action` 是位置参数，取值仅 `list` 或 `compile`。传其它值会走 `error_exit` 报 `Unknown action`。

## 📤 list：列出源文件

```bash
apkid-ai-cli rules list
```

```json
{
  "rules": [
    "/abs/path/apkid/rules/compiler/d8.yara",
    "/abs/path/apkid/rules/compiler/dx.yara",
    "/abs/path/apkid/rules/packer/jiagu_360.yara",
    "/abs/path/apkid/rules/packer/bangcle.yara"
    // ...更多 .yara 文件
  ],
  "count": 42
}
```

字段说明：

| 字段 | 含义 |
|------|------|
| `rules` | 全部 `.yara` 源文件的**绝对路径**列表，按路径字典序排列 |
| `count` | 源文件数量 |

实现上调用 `RulesManager._collect_yara_files()`，它 `os.walk` 遍历 `apkid/rules/` 目录树，收集所有 `.yara` 扩展名文件。

::: tip list 列的是文件不是规则
`count` 是 `.yara` **文件**数，不是规则数。一个 `.yara` 文件里可能含多条规则。要看去重后的规则数用 `apkid-ai-cli info` 的 `rules_count`。
:::

## 📤 compile：重新编译

```bash
apkid-ai-cli rules compile
```

```json
{
  "compiled": true,
  "rules_count": 142
}
```

字段说明：

| 字段 | 含义 |
|------|------|
| `compiled` | `true` 表示编译并保存成功 |
| `rules_count` | 编译产出的规则数（去重后的 `identifier` 计数），与 `info` 的 `rules_count` 同源 |

实现链：

```python
rules_mgr.compile()   # yara.compile(filepaths=所有.yara文件) → 内存规则集
count = rules_mgr.save()   # 写入 rules.yarc，返回去重规则数
```

- `compile()` 把所有 `.yara` 源文件喂给 `yara.compile`，生成内存中的 `Rules` 对象。
- `save()` 把该对象序列化写到 `apkid/rules/rules.yarc`，并返回 `len(set(r.identifier for r in rules))`。
- 编译失败（如规则语法错误）会抛异常，被 `error_exit` 捕获，输出 `{"error": true, "message": "Compilation failed: ..."}` 到 stderr 并退出码 1。

::: warning rules.yarc 是 gitignored
`rules.yarc` 不进版本控制（二进制编译产物，随 yara-python 版本变化）。所以：
- 克隆仓库后首次使用前必须编译（或跑 `python prep-release.py`）。
- 改了任何 `.yara` 源规则后必须重新 `compile`，否则扫描用的还是旧 `rules.yarc`。
- CI 流水线里记得在扫描前先 `rules compile`。
:::

## 🧪 示例命令

```bash
# 列出所有源规则文件
apkid-ai-cli rules list

# 看有多少个源文件
apkid-ai-cli rules list | jq '.count'

# 重新编译（改了 .yara 后必做）
apkid-ai-cli rules compile

# 编译后核对规则数
apkid-ai-cli rules compile | jq '.rules_count'
apkid-ai-cli info | jq '.rules_count'   # 两者应一致

# 只看 packer 类的源规则文件
apkid-ai-cli rules list | jq '.rules[] | select(contains("/packer/"))'

# CI：编译并断言规则数达标
apkid-ai-cli rules compile | jq -e '.rules_count >= 100' >/dev/null || exit 1
```

::: tip 编译失败怎么排查
`compile` 报错时 `error.message` 会带 YARA 的语法错误信息（规则文件名+行号）。直接 `cat` 对应 `.yara` 文件定位语法问题。常见错误：未闭合的 `condition:`、字符串变量名拼错、`meta` 字段缺引号。
:::

::: warning 不编译会怎样
如果 `rules.yarc` 不存在，`scan`/`batch`/`diff` 调 `make_scanner()` → `yara.load()` 会抛异常，命令直接报错退出。`info` 的 `rules_count` 会是 0。所以"扫不出结果"时，先 `rules list` 确认源规则在、再 `rules compile` 生成 `rules.yarc`。
:::

## 🔄 完整工作流

```bash
# 1. 编辑源规则
$EDITOR apkid/rules/packer/newpacker.yara

# 2. 重新编译
apkid-ai-cli rules compile

# 3. 核对规则数变化
apkid-ai-cli info | jq '.rules_count'

# 4. 扫描验证
apkid-ai-cli scan samples/newpacker.apk | jq '.findings[] | select(.category=="packer")'
```

## 📍 相关

- [rules 命令源码](../modules/cli-cmd-rules) — `cmd_rules.py` 实现。
- [规则系统模块](../modules/rules) — `RulesManager` 的 `compile`/`save`/`_collect_yara_files`。
- [YARA 系统](../guide/yara-system) — 规则组织结构与扫描机制。
- [规则编译](../guide/yara-system) — `prep-release.py` 与 `rules.yarc` 的生命周期。
- [info 命令](./ai-cli-info) — 编译后查看规则数与哈希。
- [AI CLI 概览](./ai-cli) — 全部命令索引。
