# ELF 混淆器 (obfuscators)

<span class="badge badge-obfus">obfuscator</span>
<span class="badge badge-info">ELF</span>
<span class="badge badge-info">46 条</span>

`elf/obfuscators.yara` 检测原生层（`.so`）代码混淆工具。重头戏是 **OLLVM 全版本指纹**——从 3.4 到 9.x，覆盖字符串加密（strenc）、控制流平坦化（CFF）、虚假控制流（BCF），以及 Hikari、Armariris、TLL、LSPosed 等衍生分支。注意 `epona` 虽在此文件中，但它的 tag 是 `protector`。

## 🎯 原生混淆的手段

- **字符串加密**：OLLVM 的 `.datadiv_decodeXXXX` 函数运行时 XOR 解密字符串。
- **控制流平坦化（CFF）**：把线性流程拆成 switch 分发，靠状态变量跳转。
- **虚假控制流（BCF）**：插入永真/永假的不透明谓词，分支到死代码。
- **指令替换**：用等价但复杂的指令序列。
- **Prolog breakage**：Arxan/DexGuard 打断函数序言，靠 `BR X8` 间接跳转。

## 📋 规则清单

### OLLVM 版本指纹系列

| 规则 | tag | 说明 |
|------|-----|------|
| `ollvm_v3_4` | obfuscator | Obfuscator-LLVM 3.4 |
| `ollvm_v3_5` | obfuscator | Obfuscator-LLVM 3.5 |
| `ollvm_v3_6_1` | obfuscator | Obfuscator-LLVM 3.6.1 |
| `ollvm_v4_0` | obfuscator | Obfuscator-LLVM 4.0 |
| `ollvm_v5_0_strenc` | obfuscator | OLLVM 5.0（字符串加密） |
| `ollvm_v6_0` | obfuscator | OLLVM 6.0 |
| `ollvm_v6_0_strenc` | obfuscator | OLLVM 6.0（字符串加密） |
| `ollvm_v8` | obfuscator | OLLVM 8.x |
| `ollvm_v8_strenc` | obfuscator | OLLVM 8.x（字符串加密） |
| `ollvm_v9` | obfuscator | OLLVM 9.x |
| `ollvm_v9_a` | obfuscator | OLLVM 9.x（o2e 分支） |
| `ollvm_v9_strenc` | obfuscator | OLLVM 9.x（字符串加密） |

### OLLVM 衍生分支与通用规则

| 规则 | tag | 说明 |
|------|-----|------|
| `ollvm_tll` | obfuscator | OLLVM TLL（字符串加密，yazhiwang/ollvm-tll） |
| `ollvm_tll_a` | obfuscator | OLLVM TLL（变体，git URL 指纹） |
| `ollvm_armariris` | obfuscator | Armariris OLLVM（字符串加密，GoSSIP-SJTU） |
| `ollvm_strenc` | obfuscator | OLLVM 未知版本（字符串加密兜底） |
| `ollvm_v_regex` | obfuscator | OLLVM（clang 版本串正则） |
| `ollvm` | obfuscator | OLLVM 未知版本（兜底，`Obfuscator-LLVM `/`Obfuscator-clang `） |
| `ollvm_lsposed` | obfuscator | LSPosed OLLVM（`decrypt.XXXXXXXX` 导出 ≥5） |

### OLLVM 代码级指纹（不依赖 .comment 字符串）

| 规则 | tag | 说明 |
|------|-----|------|
| `ollvm_cff_arm32` | obfuscator | OLLVM 控制流平坦化（ARM32，CMP+BEQ 分发链） |
| `ollvm_cff_arm64` | obfuscator | OLLVM 控制流平坦化（ARM64） |
| `ollvm_bcf_arm64` | obfuscator | OLLVM 虚假控制流（ARM64，CBNZ/CMP 不透明谓词） |
| `ollvm_string_encryption_arm64` | obfuscator | OLLVM 字符串加密（ARM64，`datadiv_decode`/XOR 解密模式） |
| `hikari2_dexprotector` | obfuscator | Hikari 2.0（DexProtector 变体，`decrypt.` + LLVM 15） |

### 其它混淆器

| 规则 | tag | 说明 |
|------|-----|------|
| `alipay` | obfuscator | Alipay 混淆器（`Alipay clang version`/`Alipay.Obfuscator.`） |
| `byteguard_0_9_3` | obfuscator | ByteGuard 0.9.3 |
| `byteguard_0_9_2` | obfuscator | ByteGuard 0.9.2 |
| `byteguard_unknown` | obfuscator | ByteGuard 未知版本 |
| `firehash` | obfuscator | Firehash（`.firehash` 节区 + ARM opcode） |
| `advobfuscator` | obfuscator | ADVobfuscator（`ObfuscatedAddress`/`MetaString` C++ 符号） |
| `arxan_arm32` | obfuscator | Arxan（ARM32，Prolog breakage ≥5） |
| `arxan_arm64` | obfuscator | Arxan（ARM64，`BR X8` 间接跳转 ≥3） |
| `dexguard_native` | obfuscator | DexGuard（`HookDetector` JNI 符号） |
| `dexguard_native_a` | obfuscator | DexGuard 9.x（`libdgrt.so` + `Java_o_`） |
| `dexguard_native_arm64` | obfuscator | DexGuard 9.x（ARM64，Frida 检测 + Prolog breakage + SVC ≥6） |
| `snapprotect` | obfuscator | SnapProtect（`snap.protect version` clang 串） |
| `safeengine` | obfuscator | Safeengine LLVM（`Safengine clang version`） |
| `dexprotector` | obfuscator | DexProtector（ELF 头 `DPLF` 魔数） |
| `dexprotector_a` | obfuscator | DexProtector（`DPLF` 段头） |
| `dexprotector_alice` | obfuscator | DexProtector Alice（`alice-core/*.cpp` 路径） |
| `androidrepublic` | obfuscator | AndroidRepublic（`libemtrepublicv3.so` + 标语） |
| `androidrepublic_vip` | obfuscator | AndroidRepublic VIP（`libandroidrepublic.so`） |
| `ay` | obfuscator | AY（adamyaxley/Obfuscate，`ay::obfuscated_data::decrypt`） |
| `octopus_codevo` | obfuscator | Octopus SDK Codevo（`octopus_obf::obfuscated_data`） |
| `epona` | **protector** | Quarks AppShield Epona（白盒密码学 LDRB 模式） |

::: warning epona 的 tag 是 protector
`epona` 虽然物理上位于 `obfuscators.yara` 文件中，但它的 YARA 声明是 `rule epona : protector`，所以输出 `category: "protector"` 而非 `obfuscator`。它检测的是 Quarks AppShield 的白盒密码学实现，属保护而非混淆。
:::

## 🔍 检测原理要点

### clang 版本串指纹（OLLVM 主线）

OLLVM 在编译时把 `Obfuscator-LLVM clang version X.Y.Z (based on Obfuscator-LLVM X.Y.Z)` 写进 `.comment` 节区。规则靠精确字符串或正则匹配版本：

```yara
rule ollvm_v3_4 : obfuscator {
  strings:
    $clang_version = "Obfuscator-clang version 3.4 "
    $based_on      = "(based on LLVM 3.4"
  condition:
    is_elf and all of them
}
```

### `.datadiv_decode` 字符串加密指纹

OLLVM 字符串加密会生成 `.datadiv_decodeXXXXXXXXXXXXXXXXXX` 函数（18~20 位数字），运行时 XOR 解密字符串。`_strenc` 后缀规则靠匹配这个符号识别字符串加密变体，并排除已知版本：

```yara
rule ollvm_v6_0_strenc : obfuscator {
  strings:
    $clang_version = "Obfuscator-LLVM clang version 6.0."
    $based_on      = "(based on Obfuscator-LLVM 6.0."
  condition:
    is_elf and all of them and
    for any i in (0..elf.symtab_entries): (
      elf.symtab[i].name matches /\.datadiv_decode[\d]{18,20}/
    )
}
```

### 代码级 CFF/BCF 指纹（.comment 被剥离时）

现代 OLLVM 分支常剥离 `.comment` 节区，版本串失效。APKiD 加了 `_cff_`/`_bcf_`/`_string_encryption_arm64` 规则，直接在 `.text` 里匹配指令模式：

- **CFF**：`MOV state` → `CMP` → `B.EQ/B.NE` 分发链，要求 `>3` 次重复。
- **BCF**：`CBZ/CBNZ` + 短分支到死代码 + `B back`，要求 `>8` 次重复。
- 这些规则都带一长串 `not ollvm_v3_4 and not ...` 排除已知版本，避免重复报告。

### Prolog breakage（Arxan/DexGuard）

Arxan 和 DexGuard 9.x 打断函数序言，用 `BR X8` 间接跳转到加密的基本块。规则靠 opcode 序列 + 计数阈值识别（如 `arxan_arm64` 要求 `#a > 3 or #b > 3`）。

### 自定义魔数（DexProtector）

`dexprotector` 靠 ELF 头偏移处的 `DPLF`（DexProtector Linkable Format）魔数识别，`dexprotector_a` 靠 PT_LOAD 段头的 `DPLF` 识别。

## 📊 finding 示例

```json
{
  "tag": "obfuscator::ollvm_v9_strenc",
  "category": "obfuscator",
  "source": "app.apk!lib/arm64-v8a/libfoo.so",
  "identifier": "ollvm_v9_strenc",
  "confidence": "medium"
}
```

OLLVM 规则的版本提取（如 `ollvm_v9` → `version: "9"`）由 `_extract_version()` 处理。

## 📍 相关

- [obfuscator 类别](./category-obfuscator) — 概念与跨文件类型分布
- [compiler 类别](./category-compiler) — 编译器 vs 混淆器（都靠 clang 版本串）
- [ELF 规则总览](./elf-overview) · [ELF 加固](./elf-packers) · [ELF 保护器](./elf-protectors)
- [文件类型识别（指南）](../guide/file-types)
