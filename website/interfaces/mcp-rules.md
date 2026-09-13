# rules — 规则管理

<span class="badge badge-info">MCP</span>
<span class="badge badge-info">FastMCP</span>
<span class="badge badge-info">元数据</span>
<span class="badge badge-warning">有副作用</span>

📜 `rules` 工具管理 YARA 规则：列出所有规则源文件，或重新编译 `rules.yarc`。是 8 个 MCP 工具里 **唯一有副作用** 的工具（`compile` 会写文件）。

## 📋 工具签名

```
rules(action?) → JSON 字符串
```

## 📑 参数表

| 参数 | 类型 | 默认 | 必填 | 说明 |
|------|------|------|:----:|------|
| `action` | `str` | `"list"` | — | `list` 列出规则文件；`compile` 重新编译 `rules.yarc` |

::: tip MCP 版 action 有默认值
与 CLI `rules` 命令不同，MCP 版的 `action` **有默认值 `"list"`**——客户端可不传参数调用，默认列出规则。CLI 版则要求显式传 action（`apkid-ai-cli rules list`）。这是 MCP 与 CLI 的明显差异之一，详见 [tools_info.py](../modules/mcp-tools-info)。
:::

## 🔧 设计要点

```python
def rules(action: str = "list") -> str:
    rules_mgr = RulesManager()
    if action == "list":
        yara_files = rules_mgr._collect_yara_files()
        rule_list = sorted(yara_files.keys())
        return json.dumps({"error": False, "rules": rule_list, "count": len(rule_list)}, ...)
    elif action == "compile":
        rules_mgr.compile()
        count = rules_mgr.save()
        return json.dumps({"error": False, "compiled": True, "rules_count": count}, ...)
    else:
        return json.dumps({"error": True, "message": f"Unknown action '{action}'. Use 'list' or 'compile'."})
```

- **`action="list"`**：调 `RulesManager._collect_yara_files()` 收集所有 `.yara` 源文件，返回排序后的文件名列表 + 数量。只读，无副作用。
- **`action="compile"`**：调 `compile()` 解析全部源规则、`save()` 写出 `rules.yarc`。**有副作用**——会覆盖磁盘上的 `rules.yarc`。
- **未知 action**：返回错误 JSON，提示用 `list` 或 `compile`。
- **不调 `make_scanner`**：`rules` 是规则管理工具，不构造扫描器。但 `compile` 产出的 `rules.yarc` 会被 `make_scanner` 加载。
- **与 CLI `rules` 行为一致**：list/compile 逻辑相同，差异仅在 `action` 默认值和错误处理。

## 📤 返回示例

### list（默认）

```json
{
  "error": false,
  "rules": [
    "apk/packers.yara",
    "apk/protectors.yara",
    "dex/compilers.yara",
    "dex/packers.yara",
    "elf/anti_vm.yara",
    "elf/common.yara"
  ],
  "count": 6
}
```

`rules` 数组是 `.yara` 源文件的相对路径（相对于规则目录），按字母序排序。`count` 是文件数。

### compile

编译成功：

```json
{
  "error": false,
  "compiled": true,
  "rules_count": 187
}
```

`rules_count` 是编译后 `rules.yarc` 里的规则数（去重后的 identifier 数）。

编译失败（如规则语法错）：

```json
{
  "error": true,
  "message": "Syntax error in apk/packers.yara line 42: ...",
  "detail": "yara.SyntaxError"
}
```

### 未知 action

```json
{
  "error": true,
  "message": "Unknown action 'delete'. Use 'list' or 'compile'."
}
```

::: warning compile 是有副作用的工具
`compile` 会 **覆盖** 磁盘上的 `rules.yarc`。在生产环境调用前应确认：

- 是否真的需要重编译（修改了 `.yara` 源文件后才有必要）。
- 当前进程对 `rules.yarc` 所在目录有写权限。
- 编译失败不会损坏旧 `rules.yarc`？——实际上 `save()` 会覆盖，若编译中途失败可能留下半成品。建议在安全环境调用。

正常使用中，`rules.yarc` 由 `python prep-release.py` 在打包时编译好，运行时 **不需要** 调 `compile`。MCP 客户端一般只调 `list`。详见 [编译与发布](../rules/compilation)。
:::

## 🤖 在 Claude 里的使用

### 列出规则

> APKiD 都有哪些 YARA 规则文件？

Claude 调 `rules`（不传 action，默认 `list`），拿到文件列表：

> 共 6 个规则文件，覆盖 APK/DEX/ELF 三种类型的 packer、protector、compiler、anti_vm 等类别。

### 重新编译

> 我刚改了一个 YARA 规则，帮我重新编译

Claude 调 `rules`，`action="compile"`：

> 编译完成，新规则文件含 187 条规则。现在可以扫描了。

::: warning 让 Claude 谨慎调 compile
`compile` 有副作用，建议让 Claude 在调用前向你确认。可以提示词约束："未经我同意不要调 rules 的 compile action"。`list` 是只读的，可放心调用。
:::

## 🆚 与 CLI `rules` 的差异

| 维度 | MCP `rules` | AI CLI `rules` |
|------|-------------|----------------|
| `action` 默认值 | `"list"`（可省略） | 无默认（必填） |
| `--output/-o` | ❌ 无 | ✅ 有 |
| `--format/-f` | ❌ 无（恒 JSON） | ✅ `json`/`text` |
| 错误处理 | `return` 错误 JSON | `error_exit`（stderr + exit 1） |
| list/compile 行为 | 同 | 同 |

::: tip 为何 MCP 版 action 有默认值
MCP 客户端（如 Claude）调用工具时，如果某个参数有默认值，客户端可以省略它——这对 AI 更友好（少传一个参数）。而 CLI 必须显式写 `rules list`，因为 typer 子命令约定。这种"默认值差异"是 MCP 适配器有意的调整，详见 [tools_info.py 源码文档](../modules/mcp-tools-info#📜-rules)。
:::

## 🔗 调用链

### list

```
MCP client → FastMCP → rules(action="list")  （或不传，默认 list）
                          │
                          └─ RulesManager._collect_yara_files()
                                 │
                                 └─ sorted(keys) → ["apk/packers.yara", ...]
                                        │
                                        └─ return {error:false, rules:[...], count:N}
```

### compile

```
MCP client → FastMCP → rules(action="compile")
                          │
                          └─ RulesManager
                                 ├─ compile()  → 解析全部 .yara，构建 yara.Rules
                                 │     └─ 语法错? → return {error:true, message, detail}
                                 │
                                 └─ save()     → 写 rules.yarc，返回规则数
                                        │
                                        └─ return {error:false, compiled:true, rules_count:N}
```

## 📍 相关

- [MCP 概览](./mcp) — 安装、配置、工具清单。
- [AI CLI · rules](./ai-cli-rules) — 对应的 CLI 命令。
- [编译与发布](../rules/compilation) — `rules.yarc` 的标准编译流程（`prep-release.py`）。
- [tools_info.py](../modules/mcp-tools-info) — 适配器源码详解。
- [RulesManager](../modules/rules) — `compile`/`save`/`_collect_yara_files` 实现。
- [info 工具](./mcp-info) — `rules_count=0` 时用它确认规则状态。
- [规则系统概览](../rules/overview) — YARA 规则如何组织。
