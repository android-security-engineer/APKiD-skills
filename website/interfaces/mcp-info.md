# info — 版本与规则信息

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">FastMCP</span>
<span class="badge badge-info">元数据</span>

ℹ️ `info` 工具返回 APKiD 的版本号、规则文件的 SHA-256 哈希、规则数量。是让 MCP 客户端"了解当前实例能力"的只读元数据工具。

## 📋 工具签名

```
info() → JSON 字符串
```

## 📑 参数表

| 参数 | 类型 | 默认 | 必填 | 说明 |
|------|------|------|:----:|------|
| （无） | — | — | — | `info` 不接受任何参数 |

`info` 是 8 个 MCP 工具里 **参数最少** 的之一——零参数，调用时什么都不传。

## 🔧 设计要点

```python
def info() -> str:
    rules_mgr = RulesManager()
    rules_hash = rules_mgr.hash
    try:
        rules = rules_mgr.load()
        rules_count = len(set(r.identifier for r in rules))
    except Exception:
        rules_count = 0
    return json.dumps({
        "error": False, "version": __version__,
        "rules_sha256": rules_hash, "rules_count": rules_count,
    }, ensure_ascii=False, indent=2)
```

- **`rules_sha256` 来自 `RulesManager().hash`**：惰性计算的 `rules.yarc` SHA-256。同一个规则文件，哈希固定——可用它判断两个 MCP 实例是否加载了相同版本的规则。
- **`rules_count` 用 `set(r.identifier)` 去重**：因为 private 规则也可能被计入，用集合去重得到"唯一规则数"。
- **`load()` 失败时 `rules_count=0`**：如 `rules.yarc` 缺失或损坏，`load()` 抛异常被捕获，`rules_count` 设为 0，**不报错**。这是 `info` 的容错设计——即使规则没编译，也能返回版本号。
- **不调 `make_scanner`**：`info` 只读元数据，不构造扫描器。与 [`list_tags`](./mcp-list-tags)/[`rules`](./mcp-rules)/[`skills`](./mcp-skills) 一样属于信息类工具。
- **带 `indent=2`**：信息类工具用美观缩进（扫描类工具用紧凑格式），因为更可能被人类直接看。

## 📤 返回示例

### 正常

```json
{
  "error": false,
  "version": "3.0.5",
  "rules_sha256": "a1b2c3d4e5f6...（64 位十六进制）",
  "rules_count": 187
}
```

### 规则加载失败（rules.yarc 缺失）

```json
{
  "error": false,
  "version": "3.0.5",
  "rules_sha256": null,
  "rules_count": 0
}
```

::: warning `rules_count=0` 意味着扫描会失败
`info` 本身不报错（`error:false`），但 `rules_count=0` 是个危险信号——说明 `rules.yarc` 没编译或加载失败。此时调 `scan_file`/`batch_scan`/`diff_files` 会返回错误（因为 `make_scanner` 会尝试加载规则）。遇到这种情况，调 [`rules` 工具](./mcp-rules) 的 `action=compile` 重新编译，或检查安装。

源码安装后忘了跑 `python prep-release.py` 是最常见的诱因。详见 [MCP 概览 · 排错](./mcp#🐛-排错)。
:::

## 🤖 在 Claude 里的使用

> 这个 APKiD 实例是什么版本？有多少条规则？

Claude 调 `info`，拿到版本和规则数后报告：

> 当前是 APKiD 3.0.5，加载了 187 条 YARA 规则，规则哈希 a1b2c3…。

也可以让 Claude 自检：

> 先调 info 看看规则加载正常吗

如果 `rules_count=0`，Claude 会提示：

> 规则没加载成功（rules_count=0），扫描会失败。要我用 rules 工具重新编译吗？

## 🆚 与 CLI `info` 的差异

| 维度 | MCP `info` | AI CLI `info` |
|------|------------|---------------|
| 参数 | 无 | 无 |
| `--output/-o` | ❌ 无 | ✅ 有 |
| `--format/-f` | ❌ 无（恒 JSON） | ✅ `json`/`text` |
| 错误处理 | `return` 错误 JSON | `error_exit`（stderr + exit 1） |
| 返回字段 | 同（`version`/`rules_sha256`/`rules_count`） | 同 |

逻辑层面完全一致——两者都调 `RulesManager().hash` 和 `load()`。差异仅在传输层。

::: tip 为何 `info` 不报规则加载失败
`info` 的定位是"报告状态"，不是"验证可用性"。即使规则坏了，`info` 也能告诉你版本号和哈希（哈希可能为 null）。把"能不能用"的判断留给客户端——它看到 `rules_count=0` 自然知道要修。这种"永远成功返回"的设计让 `info` 成为安全的探测工具，不会因为环境问题而调用失败。
:::

## 🔗 调用链

```
MCP client → FastMCP → info()
                          │
                          ├─ RulesManager().hash    （惰性算 SHA-256）
                          │
                          ├─ RulesManager().load()  （加载 rules.yarc）
                          │     └─ len(set(r.identifier for r in rules))
                          │           └─ 失败? → rules_count=0
                          │
                          └─ return json.dumps({error:false, version, rules_sha256, rules_count})
```

## 📍 相关

- [MCP 概览](./mcp) — 安装、配置、工具清单。
- [AI CLI · info](./ai-cli-info) — 对应的 CLI 命令。
- [tools_info.py](../modules/mcp-tools-info) — 适配器源码详解。
- [rules 工具](./mcp-rules) — `rules_count=0` 时用它编译。
- [RulesManager](../modules/rules) — `hash`/`load` 的实现。
- [编译与发布](../rules/compilation) — `rules.yarc` 怎么来。
