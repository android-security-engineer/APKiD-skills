# AI CLI · list-tags — 检测类别清单

<span class="badge badge-info">AI CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-success">目录</span>

🏷️ `apkid-ai-cli list-tags` 列出 APKiD 所有检测类别（tag）及其描述。无参数，数据源是 `ai_output.RULE_DESCRIPTIONS` 字典——这是"APKiD 能检测什么"的权威清单。

## 🚀 一行用法

```bash
apkid-ai-cli list-tags
```

## 🖥️ 命令签名

```bash
apkid-ai-cli list-tags
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| — | — | — | **无参数** |

## 📤 输出示例

```bash
apkid-ai-cli list-tags
```

```json
{
  "tags": [
    { "tag": "abnormal", "description": "Detects abnormal or suspicious modifications" },
    { "tag": "anti_debug", "description": "Detects anti-debugging techniques" },
    { "tag": "anti_disassembly", "description": "Detects anti-disassembly techniques" },
    { "tag": "anti_hook", "description": "Detects anti-hooking techniques (anti-Frida, anti-Xposed)" },
    { "tag": "anti_root", "description": "Detects anti-root techniques" },
    { "tag": "anti_vm", "description": "Detects anti-VM/anti-emulator techniques" },
    { "tag": "anticheat", "description": "Detects anti-cheat SDKs" },
    { "tag": "compiler", "description": "Detects compiler or build tool fingerprints" },
    { "tag": "dropper", "description": "Detects dropper/loader behavior patterns" },
    { "tag": "embedded", "description": "Detects embedded payloads" },
    { "tag": "file_type", "description": "Detects file type information" },
    { "tag": "hook", "description": "Detects hooking frameworks (Xposed, Frida, etc.)" },
    { "tag": "internal", "description": "Detects internal/development artifacts" },
    { "tag": "manipulator", "description": "Detects APK manipulation tools" },
    { "tag": "obfuscator", "description": "Detects code obfuscation tools" },
    { "tag": "packer", "description": "Detects APK packing/obfuscation tools" },
    { "tag": "protector", "description": "Detects app protection/shielding SDKs" },
    { "tag": "root", "description": "Detects root detection or root-related libraries" },
    { "tag": "signer", "description": "Detects APK signing certificates and signers" },
    { "tag": "yara_issue", "description": "Detects YARA engine issues (e.g. DEX recognized by APKiD but not YARA module)" }
  ]
}
```

## 📋 全部 20 个类别

输出按 tag 名字典序排列。以下是按功能归类的解读：

### 反检测类（5 个）

| tag | 描述 | 说明 |
|-----|------|------|
| `anti_vm` | Detects anti-VM/anti-emulator techniques | 反虚拟机/模拟器，样本检测运行环境是否为沙箱 |
| `anti_debug` | Detects anti-debugging techniques | 反调试，如 ptrace 检测、调试端口检查 |
| `anti_disassembly` | Detects anti-disassembly techniques | 反汇编对抗，如混淆控制流欺骗反汇编器 |
| `anti_root` | Detects anti-root techniques | 反 root，检测设备是否 root |
| `anti_hook` | Detects anti-hooking techniques (anti-Frida, anti-Xposed) | 反 Hook，针对 Frida/Xposed 的检测 |

### 加固/混淆/保护类（4 个）

| tag | 描述 | 说明 |
|-----|------|------|
| `packer` | Detects APK packing/obfuscation tools | 加壳工具（360 加固、Bangcle 等） |
| `obfuscator` | Detects code obfuscation tools | 代码混淆器（OLLVM 等） |
| `protector` | Detects app protection/shielding SDKs | 应用保护/加固 SDK |
| `anticheat` | Detects anti-cheat SDKs | 反作弊 SDK（游戏向） |

### 构建与签名类（2 个）

| tag | 描述 | 说明 |
|-----|------|------|
| `signer` | Detects APK signing certificates and signers | APK 签名证书/签名者 |
| `compiler` | Detects compiler or build tool fingerprints | 编译器/构建工具指纹（dx、d8 等） |

### 行为与载荷类（3 个）

| tag | 描述 | 说明 |
|-----|------|------|
| `abnormal` | Detects abnormal or suspicious modifications | 异常/可疑修改 |
| `dropper` | Detects dropper/loader behavior patterns | Dropper/Loader 行为 |
| `embedded` | Detects embedded payloads | 内嵌载荷 |

### 工具与元信息类（2 个）

| tag | 描述 | 说明 |
|-----|------|------|
| `manipulator` | Detects APK manipulation tools | APK 篡改工具 |
| `file_type` | Detects file type information | 文件类型信息（默认 `--include-types=false` 时被过滤） |

### Hook/Root 相关与诊断（4 个）

| tag | 描述 | 说明 |
|-----|------|------|
| `internal` | Detects internal/development artifacts | 内部/开发遗留物 |
| `hook` | Detects hooking frameworks (Xposed, Frida, etc.) | Hook 框架本身（注意与 `anti_hook` 区分：一个是用了 Hook，一个是检测 Hook） |
| `root` | Detects root detection or root-related libraries | Root 检测或 root 相关库 |
| `yara_issue` | Detects YARA engine issues (e.g. DEX recognized by APKiD but not YARA module) | YARA 引擎问题，APKiD 识别为 DEX 但 YARA 模块没认出来的诊断标记 |

::: tip `file_type` 默认不出现
扫描结果的 `findings` 默认会过滤掉 `file_type` 类（除非 scan/batch 传 `--include-types`）。但 `list-tags` 始终列出它，因为它属于 `RULE_DESCRIPTIONS` 的权威范畴。
:::

## 🔍 数据来源

```python
from apkid.ai_output import RULE_DESCRIPTIONS

for tag, desc in sorted(RULE_DESCRIPTIONS.items()):
    tags.append({"tag": tag, "description": desc})
```

- `RULE_DESCRIPTIONS` 是 `apkid/ai_output.py` 里的字典，key 是 tag 名，value 是描述。
- 这是**静态字典**，与 `rules.yarc` 是否编译无关——不调 `make_scanner`、不加载规则。
- 按字典序 `sorted` 输出，结果稳定。

::: warning 加新 YARA 规则带新 tag 必须登记
如果你新增一条 YARA 规则，其 tag 引入了一个 `RULE_DESCRIPTIONS` 里没有的新类别，**必须**在 `ai_output.py` 的 `RULE_DESCRIPTIONS` 字典里补上该类别描述。否则：
- `list-tags` 看不到这个新类别；
- scan/batch 输出的 finding 里 `description` 会回退成 `"Unknown detection category"`。

这是项目 [CLAUDE.md 约定](../guide/categories) 的硬性要求。
:::

## 🧪 示例命令

```bash
# 看全部类别
apkid-ai-cli list-tags

# 只看 tag 名
apkid-ai-cli list-tags | jq '.tags[].tag'

# 找出与"加固"相关的类别
apkid-ai-cli list-tags | jq '.tags[] | select(.description | test("pack|protect|obfus"; "i")) | .tag'

# 统计类别总数
apkid-ai-cli list-tags | jq '.tags | length'   # 20

# 给 AI 当能力清单
apkid-ai-cli list-tags | jq '.tags[] | "\(.tag): \(.description)"'
```

::: tip 与 rules list 区分
- `list-tags` 列的是**检测类别**（tag 名，如 `packer`、`compiler`）。
- `rules list` 列的是**YARA 源文件**（`.yara` 文件路径）。

一个是语义类别，一个是源文件，别混淆。
:::

## 📍 相关

- [检测类别](../guide/categories) — 各 tag 的含义详解与实战解读。
- [ai_output 模块](../modules/ai-output) — `RULE_DESCRIPTIONS` 字典定义处。
- [list-tags 源码](../modules/cli-cmd-tags) — `cmd_tags.py` 实现。
- [info 命令](./ai-cli-info) — 规则数量/哈希等元数据。
- [AI CLI 概览](./ai-cli) — 全部命令索引。
