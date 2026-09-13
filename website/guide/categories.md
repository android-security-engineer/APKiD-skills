# 检测类别

<span class="badge badge-pack">packer</span>
<span class="badge badge-protect">protector</span>
<span class="badge badge-obfus">obfuscator</span>
<span class="badge badge-compiler">compiler</span>
<span class="badge badge-anti">anti_*</span>

APKiD 把检测结果归类到若干 **category**。每个 finding 的 `category` 字段来自 YARA 规则的 tag，描述由 `RULE_DESCRIPTIONS` 字典提供。本文是所有类别的速查表。

## 📚 类别一览

定义在 [`apkid/ai_output.py` 的 `RULE_DESCRIPTIONS`](../modules/ai-output)：

| 类别 | 图标 | 描述 |
|------|:---:|------|
| `packer` | 🛡️ | APK 加固/打包工具 |
| `protector` | 🏰 | 应用保护/加固 SDK（RASP 等） |
| `obfuscator` | 🧩 | 代码混淆工具 |
| `compiler` | 🔧 | 编译器或构建工具指纹 |
| `anticheat` | 🎮 | 反作弊 SDK |
| `signer` | ✍️ | APK 签名证书与签名者 |
| `anti_vm` | 🖥️ | 反虚拟机/反模拟器 |
| `anti_debug` | 🐛 | 反调试 |
| `anti_disassembly` | 📐 | 反汇编 |
| `anti_root` | 🌱 | 反 Root |
| `anti_hook` | 🪝 | 反 Hook（反 Frida、反 Xposed） |
| `abnormal` | ⚠️ | 异常或可疑修改 |
| `dropper` | 📦 | 释放器/加载器行为 |
| `embedded` | 🎁 | 内嵌载荷 |
| `manipulator` | ✂️ | APK 篡改工具 |
| `hook` | 🪝 | Hook 框架（Xposed、Frida） |
| `root` | 🌱 | Root 检测或 Root 相关库 |
| `file_type` | 📄 | 文件类型信息 |
| `internal` | 🔒 | 内部/开发构件（private 规则） |
| `yara_issue` | 🐞 | YARA 引擎问题 |

## 🏷️ 类别如何确定

每条 YARA 规则带一个或多个 tag：

```yara
rule jiagu_360_v5 : packer        // tag = packer
rule upx_embedded_inside_elf : packer dropper   // 两个 tag
```

`AIOutputFormatter._categorize_tag()` 把 tag 映射到 category——遍历 `RULE_DESCRIPTIONS` 的 key，看哪个 key 是 tag 的子串：

```python
def _categorize_tag(self, tag: str) -> str:
    tag_lower = tag.lower()
    for category in RULE_DESCRIPTIONS:
        if category in tag_lower:
            return category
    return "abnormal"   # 兜底
```

所以一条 `packer` tag 的规则 → `category: "packer"`，描述取 `RULE_DESCRIPTIONS["packer"]`。

## 📊 各类别的检测规模

| 类别 | 规则数（约） | 主要文件类型 |
|------|:---:|------|
| `packer` | 150+ | APK、DEX、ELF |
| `protector` | 90+ | APK、DEX、ELF、RES |
| `obfuscator` | 75+ | APK、DEX、ELF、DLL、RES |
| `compiler` | 15 | DEX |
| `anti_vm` | 29+ | DEX、ELF |
| `anti_disassembly` | 4 | DEX |
| `anti_root` | 5 | DEX、ELF |
| `abnormal` | 3 | DEX |
| `dropper` | 2+ | DEX、ELF |
| `manipulator` | 3 | APK、DEX |
| `file_type` | 6 | 全部 |

（精确数字见 [规则系统概览](../rules/overview)，按文件类型细分见 [检测规则](../rules/overview) 各子页。）

## 🚫 特殊类别说明

### `internal`

带 `internal` tag 的是 **private 规则**——不直接作为结果输出，仅被其它规则作为条件引用。例如 `dx_map_type_order`、`r8_marker` 这些结构指纹，是 `dx`、`r8` 规则的"积木"。

```yara
private rule r8_marker : internal { ... }

rule r8 : compiler {
  condition:
    r8_marker and (r8_map_type_order or ambiguous_tiny_dex_map_type_order)
}
```

### `file_type`

`is_apk`、`is_dex`、`is_elf`、`is_res`、`is_dll`、`is_dart` 等规则带 `file_type` tag。**默认不输出**——除非加 `--include-types`。因为这些只是"这文件是什么类型"，通常不是用户关心的"发现了什么保护"。

```bash
apkid-ai-cli scan app.apk --include-types   # 才会包含 file_type finding
```

### `yara_issue`

`yara_undetected_dex` 规则：当 APKiD 自己用魔数认出是 dex，但 YARA 的 dex 模块却没认出时触发。通常意味着这个 dex 被篡改了结构，或 YARA 模块版本旧。是个 **诊断信号** 而非恶意特征。

## 📋 列出所有类别

```bash
apkid-ai-cli list-tags
```

```json
{
  "tags": [
    { "tag": "anti_debug", "description": "Detects anti-debugging techniques" },
    { "tag": "anti_disassembly", "description": "Detects anti-disassembly techniques" },
    ...
  ]
}
```

## 📍 下一步

- 各类别详解：[packer](../rules/category-packer)、[protector](../rules/category-protector)、[obfuscator](../rules/category-obfuscator)、[compiler](../rules/category-compiler)、[anti_vm](../rules/category-anti-vm) 等。
- [AI 输出格式](./output-format) — finding 各字段含义。
- [代码模块：ai_output.py](../modules/ai-output) — `RULE_DESCRIPTIONS` 源码。
