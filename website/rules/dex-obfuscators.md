# DEX 混淆器规则

<span class="badge badge-obfus">obfuscator</span>
<span class="badge badge-obfus">22 + 2 private</span>

`apkid/rules/dex/obfuscators.yara` — 22 条公开 obfuscator 规则 + 2 条 private 积木。DEX 层混淆规则匹配 **Unicode 字段/方法名、字符串加密 opcode 序列、混淆工具注入的类名和包路径**。这是检测 DexGuard、StringFog、BlackObfuscator 等主流混淆器的主战场。

## 🎯 检测原理

DEX 混淆器留下两类足迹：
1. **命名特征**：字段/方法名被改成不可读 Unicode（如 `ᵔˎʻᐧـˏ`），或包名被改成 `Laaaaaa/xxxxxx/` 重复字母。
2. **opcode 序列**：字符串加密/解密的固定 opcode 模式（XOR、AES、`Cipher.doFinal` 等）。

APKiD 用 `dex` 模块的 `dex.field[i].name` / `dex.method[i].name` 读字段方法名，用字节序列匹配 opcode 模式。

## 📋 公开混淆器规则（22 条）

### 🛡️ DexGuard（4 条 + 关联）

| 规则 | tag | 说明 |
|------|-----|------|
| `dexguard_a` | obfuscator | DexGuard — 反射 opcode 序列 + `getClass`/`getDeclaredMethod`/`invoke` + data 尾 4 字节为 0 |
| `dexguard_b` | obfuscator | DexGuard — `Lo/[Aa][Uu][Xx];`/`Lo/[Cc][Oo][Nn];` Windows 保留名混淆类 |
| `dexguard_c` | obfuscator | DexGuard — `guardsquare/dexguard/runtime/` 包 + `TamperDetector`/`CertificateChecker` |
| `dexguard_d` | obfuscator | DexGuard — `Ldexguard/util/TamperDetection;` + Unicode 内部类 |

### 🛡️ 其它商业混淆器

| 规则 | tag | 说明 |
|------|-----|------|
| `dexprotector` | obfuscator | DexProtector — 反射 method opcode + `getClass`/`getDeclaredMethod`/`invoke` |
| `bitwise_antiskid` | obfuscator | Bitwise AntiSkid — `AntiSkid courtesy of Bitwise` 署名字符串 |
| `arxan` | obfuscator | Arxan — `L(a{6}|b{6}|...)/[a-z]{6}/` 重复字母包名 + 7 种方法 opcode 模式 |
| `arxan_multidex` | obfuscator | Arxan (multidex) — 同 arxan 特征但方法数 < 6（排除 arxan） |
| `arxan_b` | obfuscator | Arxan — `move-result` + and/xor/or 反混淆 opcode 序列 |
| `arxan_c` | obfuscator | Arxan — `Lcom/arxan/guardit` 包前缀（排除其它 arxan 变体） |
| `allatori_demo` | obfuscator | Allatori demo — `ALLATORIxDEMO` 字符串（demo 版水印） |
| `aamo_str_enc` | obfuscator | AAMO — `getStorageEncryption`/`convertToString` + Cipher 加密 opcode |
| `appsuit_a` | obfuscator | AppSuit — `AppSuit`/`APPSUIT` 标签 + `Lcom/stealien/const;` 类 |
| `appsuit_b` | obfuscator | AppSuit — `Lcom/stealien/appsuit/` 包前缀 |
| `gemalto_sdk` | obfuscator | Gemalto — `Lcom/gemalto/(idp/mobile|medl|ezio/mobile/sdk)/` 包前缀 |
| `kiwi_amazon` | obfuscator | Kiwi encrypter — `Kiwi__Version__Obfuscator` + `KiwiVersionEncrypter.java` |

### 🛡️ 开源/国产混淆器

| 规则 | tag | 说明 |
|------|-----|------|
| `unreadable_field_names` | obfuscator | unreadable field names — Unicode 字段名（排除 dexguard） |
| `unreadable_method_names` | obfuscator | unreadable method names — Unicode 方法名（排除 dexguard） |
| `apkencryptor` | obfuscator | ApkEncryptor — `Lcn/beingyi/sub/utils/Native` + Unicode 字段方法名 |
| `blackobfuscator` | obfuscator | BlackObfuscator — `String.hashCode()` + sparse-switch 控制流混淆 opcode |
| `mtprotector_dex` | obfuscator | MT Protector — `Lbin/mt/annotations/MTProtector;` 类名 |
| `stringfog` | obfuscator | StringFog — `Lcom/github/megatronking/stringfog/IStringFog;` 接口类 |

## 📋 private 积木规则（2 条）

| 私有规则 | 说明 |
|---------|------|
| `short_unicode_field_names` | one or two character unicode field names — `dex.field[i].name` 匹配非 ASCII（3 个以上即触发） |
| `short_unicode_method_names` | one or two character unicode method names — `dex.method[i].name` 匹配非 ASCII |

这两个是 `unreadable_field_names`/`unreadable_method_names` 和 `dexguard_b`/`dexguard_d` 的共用积木。

## 🔍 规则源码示例

### `arxan` — 重复字母包名 + 方法 opcode 模式

```yara
rule arxan : obfuscator {
  strings:
    // L(a{6}|b{6}|...|z{6})/[a-z]{6}/  — 6 个相同字母开头的包名
    $pkg = /L(a{6}|b{6}|c{6}|...|z{6})\/[a-z]{6}/
    // 1 byte size + 1 byte ASCII + [7-26] non-ASCII bytes + 00
    $m1 = { 10 62 (6? | 75) [14] 00 }
    $m2 = { (0b | 0d) 62 d0 [15] 00 }
    // ... $m3 ~ $m7
  condition:
    is_dex and $pkg and 6 of ($m*)
}
```

Arxan 把包名混淆成 `Laaaaaa/xxxxxx/`（同一字母重复 6 次），方法名混淆成 1 字节 ASCII + 14 字节非 ASCII 的不可读串。YARA 不支持反向引用，所以用 `(a{6}|b{6}|...)` 枚举 26 种字母。

### `unreadable_field_names` — Unicode 字段名

```yara
private rule short_unicode_field_names : internal {
  condition:
    is_dex and
    for 3 i in (0..dex.header.field_ids_size) :
      (dex.field[i].name matches /[^\x00-\x7F]{1,4}/)
}

rule unreadable_field_names : obfuscator {
  condition:
    short_unicode_field_names
    and (not dexguard_a and not dexguard_b and not dexguard_c and not dexguard_d)
}
```

`for 3 i in (...)` 是 YARA 的量词——至少 3 个字段名含非 ASCII Unicode 即触发。但先排除 DexGuard（它也用 Unicode 名），避免误报。`unreadable_method_names` 同理对 `dex.method[i].name`。

### `blackobfuscator` — 控制流混淆

```yara
rule blackobfuscator : obfuscator {
  strings:
    // String.hashCode() ^ const ^ const 的 switch 分发
    $opcodes = {
      1A 00 ?? ??                      // const-string v0, "random_weird_string"
      6E 10 ?? (AC | 00) 00 00         // invoke-virtual {v0}, String.hashCode()I
      0A ??                            // move-result
      13 02 ?? ??                      // const/16
      (14 0? ?? ?? ?? ?? | B7 ??)      // const or xor-int/2addr
      (B7 ?? | D7 ?? ?? ??)            // xor-int/2addr or xor-int/lit16
    }
    // sparse-switch 控制流
    $switch = { 2C ?? ?? ?? ?? ?? 28 ?? 1A 00 ?? ?? 28 ?? ... }
  condition:
    is_dex and (#opcodes >= 2 and #switch >= 2)
}
```

BlackObfuscator 用 `String.hashCode() ^ 常量` 做 switch 分发，把线性代码打散成跳转表——典型的控制流混淆。`#opcodes >= 2` 要求至少 2 处这种模式。

## 📊 finding 示例

```json
{
  "tag": "obfuscator::dexguard_c",
  "category": "obfuscator",
  "source": "app.apk!classes.dex",
  "identifier": "dexguard_c",
  "confidence": "high"
}
```

## 🧠 混淆器 vs 编译器

- **编译器**：把源码编成 dex，留 map_list 顺序指纹（[compiler 类别](./category-compiler)）。
- **混淆器**：在已编译的 dex 上做混淆（改名、加密字符串、混淆控制流），留 Unicode 名/opcode 指纹。

一个 dex 可以同时有编译器和混淆器命中——如 `r8` 编译 + `dexguard_c` 混淆。

## 📍 相关

- [obfuscator 类别](./category-obfuscator) — 混淆概念与全文件类型分布
- [compiler 类别](./category-compiler) — 编译器 vs 混淆器
- [APK 混淆器规则](./apk-obfuscators) — APK 层混淆检测（5 条）
- [DEX 规则总览](./dex-overview) — DEX 层规则全貌
- [编写 YARA 规则](./writing-rules) — DEX 模块 field/method 访问
