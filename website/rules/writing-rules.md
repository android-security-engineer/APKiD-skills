# 编写 YARA 规则

<span class="badge badge-info">YARA</span>
<span class="badge badge-info">贡献</span>

本文教你怎么为 APKiD 写一条新的检测规则。

## 🧱 规则骨架

```yara
rule <name> : <tag>
{
  meta:
    description = "<人可读说明>"
    sample      = "<已知样本 SHA-256>"   // 可选

  strings:
    $a = "<特征字符串>"                  // ASCII
    $b = { 00 1? 65 6D }                // 十六进制（?是通配）
    $c = /regex/                        // 正则

  condition:
    is_<filetype> and $a and 2 of ($b,$c)
}
```

## 📝 四步加一条规则

### 1. 选对文件

按被检测特征出现在 **哪种文件类型** 里，放到对应目录。一个加固的特征字符串如果在 `assets/libjiagu.so`（ELF）里，就放 `elf/packers.yara`；如果在 `classes.dex` 里，放 `dex/packers.yara`；如果是 APK 顶层的路径特征，放 `apk/packers.yara`。详见 [规则文件组织](./organization)。

### 2. 写规则

```yara
// apk/packers.yara
rule mypacker_v1 : packer
{
  meta:
    description = "MyPacker v1"
    sample = "deadbeef..."

  strings:
    $lib = "libmypacker.so" wide ascii
    $marker = "MYPACKER_V1" ascii

  condition:
    is_apk and $lib and $marker
}
```

要点：
- **`is_apk` / `is_dex` / `is_elf` 前置条件**：限定只在该类文件里匹配，避免误报。这些是 `common.yara` 里的 file_type 规则。
- **tag** 必须是 [`RULE_DESCRIPTIONS`](../modules/ai-output) 里已有的类别。新类别要先加描述。
- **meta.description** 会进 finding 的 `rule_detail`，写清楚。
- **宽字符串**：DEX 里 Java 字符串常是 modified UTF-8，宽匹配用 `wide ascii`。

### 3. 用 DEX 模块做结构指纹（DEX 规则）

如果检测编译器/加固的 **结构特征**，用 `import "dex"`：

```yara
import "dex"
include "common.yara"

rule mycompiler : compiler
{
  condition:
    is_dex and dex.map_list.map_item[7].type == 0x2001
}
```

`include "common.yara"` 引入 `is_dex` 等。结构指纹比字符串更难伪造，是编译器识别的主力。详见 [DEX 编译器](./dex-compilers)。

### 4. 编译并测试

```bash
# 编译
python prep-release.py
# 或
apkid-ai-cli rules compile

# 用已知样本验证
apkid-ai-cli scan /path/to/known-sample.apk | grep mypacker
```

## 🧩 private 积木

复用的结构特征抽成 private 规则：

```yara
private rule mypacker_marker : internal
{
  strings:
    $m = "MYPACKER_SIG"
  condition:
    $m
}

rule mypacker_v1 : packer
{
  condition:
    is_apk and mypacker_marker and $lib
}
```

`private` + `: internal` tag 保证它不进结果输出。

## ⚠️ 避免误报

- **别用太短/太通用的字符串**（如 `"com/"`、`"android/"`）——几乎所有 APK 都有。
- **组合多个特征**：`$a and $b` 比单 `$a` 可靠。
- **加 file_type 前置**：`is_dex and ...` 避免跨类型误匹配。
- **用样本验证**：meta 里写 `sample` 哈希，方便回归。
- **版本细分用 private 否定**：`jack_4x` 用 `not jack_4_12` 排除更具体的子版本。

## 🏷️ 加新检测类别

如果规则用了全新 tag（如 `: tpm_check`）：

1. 在 [`apkid/ai_output.py` 的 `RULE_DESCRIPTIONS`](../modules/ai-output) 加：
   ```python
   "tpm_check": "Detects TPM chip checks",
   ```
2. 否则 `_categorize_tag()` 会把它归到 `abnormal`，描述显示 "Unknown detection category"。

## 🧪 测试

- 把已知样本放 `tests/`（注意许可证，别提交版权 APK）。
- 在规则 meta 里记 `sample` 哈希。
- 跑 `pytest tests/test_rules.py -q` 验证编译。
- 跑 `pytest tests/test_scanner.py -q` 验证扫描。

## ✅ 提交前检查清单

- [ ] 规则放在正确的 `<filetype>/<category>.yara`
- [ ] tag 是已有类别（新类别已加进 `RULE_DESCRIPTIONS`）
- [ ] 有 `meta.description`
- [ ] 有 `is_<filetype>` 前置条件
- [ ] 特征组合避免误报
- [ ] `python prep-release.py` 编译通过
- [ ] 用样本验证命中

## 📍 相关

- [规则文件组织](./organization) — 放哪里。
- [编译与发布](./compilation) — rules.yarc 怎么来。
- [apkid-rule-dev 技能](https://github.com/rednaga/APKiD) — 辅助开发规则的 skill。
- [YARA 规则系统（指南）](../guide/yara-system) — 概念。
