# 类别：file_type 文件类型

<span class="badge badge-file">file_type</span>

`file_type` 类别标识 **文件本身是什么类型**——APK、DEX、ELF、DLL、RES、Dart。这类 finding **默认不输出**，需要 `--include-types` 才显示。

## 📋 规则分布

`file_type` tag 的规则在各类型的 `common.yara`：

| 规则 | 文件 | 检测 |
|------|------|------|
| `is_apk` | apk/common.yara | APK（ZIP 容器） |
| `is_dex` | dex/common.yara | DEX 字节码 |
| `is_elf` | elf/common.yara | ELF（原生库/可执行文件） |
| `is_dart` | elf/common.yara | Dart AOT 快照（ELF 容器） |
| `is_dll` | dll/common.yara | Windows PE DLL |
| `is_res` | res/common.yara | 二进制资源（resources.arsc） |

另有 private `is_signed_apk` / `is_unsigned_apk`（internal tag），不直接输出，被 APK 规则引用判断签名状态。

## 🎯 为什么默认不输出

`file_type` finding 的信息量低——用户通常已知文件是什么类型，关心的是"发现了什么保护/混淆"。所以 `_match_to_findings()` 默认跳过 `file_type` tag：

```python
for tag in match.tags:
    if tag == 'file_type' and not include_types:
        continue   # 默认跳过
```

要让它出现：

```bash
apkid-ai-cli scan app.apk --include-types
```

## 🔍 用途

`file_type` 规则主要作为 **其它规则的前置条件**：

```yara
rule bangcle : packer {
  condition:
    is_apk and $lib      ← is_apk 限定只在 APK 里匹配
}
```

这避免 packer 规则的字符串在 ELF/DLL 里误匹配。`is_dex`/`is_elf` 同理。

## 📊 finding 示例（--include-types 时）

```json
{
  "tag": "file_type::is_apk",
  "category": "file_type",
  "description": "Detects file type information",
  "source": "app.apk",
  "identifier": "is_apk",
  "confidence": "low"
}
```

## 🐞 yara_issue：诊断信号

`dex/common.yara` 还有 `yara_undetected_dex : yara_issue`——APKiD 自己用魔数认出是 dex，但 YARA 的 dex 模块却没认出时触发。这是个诊断信号，通常意味着 dex 结构被篡改或 YARA 模块版本旧。详见 [其它类别](./category-misc#yara_issue)。

## 📍 相关

- [文件类型识别](../guide/file-types) — 魔数判定（与 file_type 规则互补）。
- [type 命令](../interfaces/ai-cli-type) — 不加载 YARA 的快速类型判定。
- [检测类别](../guide/categories)
