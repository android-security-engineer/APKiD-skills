# ELF 规则总览

<span class="badge badge-info">ELF</span>
<span class="badge badge-pack">packer</span>
<span class="badge badge-protect">protector</span>
<span class="badge badge-obfus">obfuscator</span>

ELF 是 Android 原生层的主角——`lib/` 目录下的 `.so` 共享库与可执行文件都是 ELF。APKiD 的 ELF 规则通过匹配 so 库的导出符号、节区名、特征字符串与代码指纹，识别加固、保护、混淆与反分析技术。**UPX 全版本**与 **OLLVM 全版本**是 ELF 规则的重头戏。

## 🎯 为什么 ELF 这么重要

Android 应用的关键逻辑往往藏在原生库里：

- 加固方案的壳代码（`libjiagu.so`、`libshell.so`）跑在 ELF 层。
- OLLVM、Hikari 等原生混淆器只作用在 so 库。
- RASP 保护 SDK（Verimatrix、Appdome、MetaFortress）注入 so 库做运行时防护。
- Flutter 应用的 Dart AOT 快照（`libapp.so`）也是 ELF。

APKiD 递归扫描 APK 时会拆出每个 `.so` 单独跑 ELF 规则，从原生层角度还原应用的保护栈。

## 📂 子文件结构

ELF 规则位于 `apkid/rules/elf/`，共 5 个源文件、126 条规则：

| 文件 | 规则数 | 主类别 | 子文档 |
|------|:---:|------|------|
| `common.yara` | 2 | file_type | [ELF 通用](./elf-common) |
| `packers.yara` | 44 | packer | [ELF 加固](./elf-packers) |
| `protectors.yara` | 33 | protector | [ELF 保护器](./elf-protectors) |
| `obfuscators.yara` | 46 | obfuscator | [ELF 混淆器](./elf-obfuscators) |
| `anti-vm.yara` | 1 | anti_vm | [ELF 反虚拟机](./elf-anti-vm) |

`common.yara` 的 `is_elf` 是所有 ELF 规则的前置条件——只有先确认是 ELF，packer/protector/obfuscator 规则才会触发。`is_dart` 进一步识别 Dart AOT 快照，供 `free_rasp_dart` 等 Dart 专属规则使用。

## 🛡️ 三大重头戏

### UPX 全版本指纹（44 条加固）

UPX 是开源 ELF 压缩器，被大量加固方案魔改（梆梆/SecNeo 把 `UPX!` 换成 `SEC!`，爱加密换成 `AJM!`，Joker 换成 `ZHSH`）。APKiD 覆盖 3.01~3.94 全版本，并区分原版/魔改/嵌入式等形态。详见 [ELF 加固](./elf-packers)。

### OLLVM 全版本指纹（46 条混淆）

[Obfuscator-LLVM](https://github.com/obfuscator-llvm/obfuscator/wiki) 是原生混淆的事实标准，APKiD 覆盖 3.4~9.x 全版本，并区分字符串加密（`_strenc` 后缀）、控制流平坦化（`_cff_`）、虚假控制流（`_bcf_`），还覆盖 Hikari、Armariris、TLL、LSPosed 等衍生分支。详见 [ELF 混淆器](./elf-obfuscators)。

### 原生保护 SDK（33 条保护器）

Verimatrix、Appdome、MetaFortress、Virbox、Vkey、Denuvo、Zimperium 等保护 SDK 的壳代码跑在 so 库里，靠导出符号、节区名、内联 syscall 指纹识别。其中 `ahnlab_v3_engine` 与 `rootbeer` 两条规则的 tag 是 `anti_root`（专做 Root 检测）。详见 [ELF 保护器](./elf-protectors)。

## 📊 规则分布速览

```
ELF 规则 (126)
├── packers (44)     ████████████████████████  UPX 全版本 + 各厂商壳
├── obfuscators (46) █████████████████████████  OLLVM 全版本 + 衍生
├── protectors (33)  ██████████████████        RASP SDK
├── anti-vm (1)      █                         QEMU 熵检测
└── common (2)       █                         is_elf, is_dart
```

ELF 是 APKiD 规则数第二多的文件类型（仅次于 APK），且 obfuscator 规则数全文件类型第一——因为原生库混淆极其常见。

## 📊 finding 示例

```json
{
  "tag": "obfuscator::ollvm_v9",
  "category": "obfuscator",
  "source": "app.apk!lib/arm64-v8a/libfoo.so",
  "identifier": "ollvm_v9",
  "confidence": "medium",
  "version": "9"
}
```

`source` 含 `.so` → ELF 匹配。同一 so 库可能同时命中 packer（UPX）+ obfuscator（OLLVM）+ protector（RASP），APKiD 会分别报告。

## 📍 相关

- [ELF 加固 (packers)](./elf-packers) · [ELF 保护器 (protectors)](./elf-protectors) · [ELF 混淆器 (obfuscators)](./elf-obfuscators)
- [ELF 反虚拟机 (anti-vm)](./elf-anti-vm) · [ELF 通用 (common)](./elf-common)
- [文件类型识别（指南）](../guide/file-types) — ELF 在 APKiD 中的定位
- [规则文件组织](./organization) — 目录结构
