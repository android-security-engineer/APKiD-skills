# 类别：obfuscator 混淆器

<span class="badge badge-obfus">obfuscator</span>

`obfuscator` 类别检测 **代码混淆工具**。混淆不改变程序逻辑，但让逆向分析变难——重命名、加密字符串、控制流平坦化等。

## 🎯 混淆的常见手段

| 手段 | 效果 | 典型工具 |
|------|------|---------|
| 标识符重命名 | 类名/方法名变成 `a`、`b`、`OooO0OO` | ProGuard、DexGuard |
| 字符串加密 | 字符串不再明文，运行时解密 | StringFog、OLLVM strenc |
| 控制流平坦化（CFF） | 把线性流程拆成 switch 分发 | OLLVM |
| 虚假控制流（BCF） | 插入永真/永假的假分支 | OLLVM |
| 指令替换 | 用等价但复杂的指令序列 | OLLVM |
| 代码加密 | 整段代码运行时解密执行 | Arxan、DexGuard |

## 📋 规则分布

| 文件类型 | 文件 | 规则数 | 子文档 |
|---------|------|:---:|------|
| APK | `apk/obfuscators.yara` | 5 | [APK 混淆器](./apk-obfuscators) |
| DEX | `dex/obfuscators.yara` | 22 | [DEX 混淆器](./dex-obfuscators) |
| ELF | `elf/obfuscators.yara` | 46 | [ELF 混淆器](./elf-obfuscators) |
| DLL | `dll/obfuscators.yara` | 1 | [DLL 规则](./dll-overview) |
| RES | `res/obfuscators.yara` | 1 | [RES 规则](./res-overview) |

ELF 混淆规则最多——因为原生库混淆（尤其 OLLVM）极其常见。

## 🏢 主要混淆器

### OLLVM 家族（ELF，46 条）

[OLLVM](https://github.com/yag-ya/ollvm) 是最主流的原生混淆框架，APKiD 覆盖几乎所有版本：

| 规则 | 版本 |
|------|------|
| `ollvm_v3_4`/`v3_5`/`v3_6_1` | 3.x |
| `ollvm_v4_0` | 4.0 |
| `ollvm_v5_0_strenc`/`v6_0_strenc`/`v6_0` | 5/6.x |
| `ollvm_v8`/`v8_strenc`/`v9`/`v9_a`/`v9_strenc` | 8/9.x |
| `ollvm_strenc`/`ollvm_v_regex`/`ollvm` | 通用 |
| `ollvm_tll`/`tll_a`/`armariris`/`lsposed` | 衍生分支 |
| `ollvm_cff_arm32`/`cff_arm64`/`bcf_arm64`/`string_encryption_arm64` | 按技术分 |
| `ollvm_tll`/`hikari`/`hikari2_dexprotector` | 衍生 |

### DEX 混淆器（22 条）

| 工具 | 规则 |
|------|------|
| DexGuard | `dexguard_a`~`_d`、`dexguard_native`/`_a`/`_arm64` |
| DexProtector | `dexprotector` |
| Arxan | `arxan`/`_multidex`/`_b`/`_c`/`_arm32`/`_arm64` |
| StringFog | `stringfog` |
| Allatori | `allatori_demo` |
| BlackObfuscator | `blackobfuscator` |
| MTProtector | `mtprotector_dex` |
| AppSuit | `appsuit_a`/`_b` |
| 通用 | `unreadable_field_names`、`unreadable_method_names`、`bitwise_antiskid`、`apkencryptor`、`aamo_str_enc`、`gemalto_sdk`、`kiwi_amazon` |

## 🔍 检测特征举例

### OLLVM 字符串加密标记

```yara
rule ollvm_v9 : obfuscator {
  strings:
    // OLLVM v9 字符串解密函数的特征字节
    $strenc = { ... }
  condition:
    is_elf and $strenc
}
```

### DexGuard dex 层特征

```yara
rule dexguard_a : obfuscator {
  condition:
    is_dex and $dg_marker
}
```

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

注意 `version: "9"`——`_extract_version()` 从 `ollvm_v9` 提取了版本号。

## 🆚 obfuscator vs packer

混淆器 **不加密整个 dex**，只让代码难读；packer **加密整个 dex**，运行时解密。混淆的 dex 结构正常可反编译（只是难懂），加固的 dex 是壳需先脱壳。

## 📍 相关

- [ELF 混淆器](./elf-obfuscators) · [DEX 混淆器](./dex-obfuscators) · [APK 混淆器](./apk-obfuscators)
- [packer 类别](./category-packer) — 区别
- [compiler 类别](./category-compiler) — 编译器 vs 混淆器
- [检测类别](../guide/categories)
