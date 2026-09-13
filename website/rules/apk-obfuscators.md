# APK 混淆器规则

<span class="badge badge-obfus">obfuscator</span>
<span class="badge badge-obfus">5 条</span>

`apkid/rules/apk/obfuscators.yara` — 5 条规则。`obfuscator` 类别检测 **APK 层的混淆工具痕迹**——这些工具不加密 dex，而是通过注入资产文件、配置或原生库来混淆/加密资源与代码。APK 层的混淆规则数量少，因为大部分混淆发生在 DEX 字节码层（详见 [DEX 混淆器](./dex-obfuscators)）。

## 🎯 检测原理

APK 层混淆工具的特征是：在 `assets/` 或 `lib/` 下留下 **独特的资产文件名或配置文件**。规则匹配这些路径字符串。

## 📋 规则清单

| 规则 | tag | 说明 |
|------|-----|------|
| `arxan_guardit` | obfuscator | Arxan GuardIT — `guardit4j.fin` 配置文件（>1 个） |
| `gemalto_protector` | obfuscator | Gemalto — 多架构 `libmedl.so` |
| `androidrepublic` | obfuscator | AndroidRepublic — `assets/emt.androidrepublic/*.png` |
| `androidrepublic_vip` | obfuscator | AndroidRepublic VIP — `assets/androidrepublic.org/*.png`（正则） |
| `obfuscapk_libencryption` | obfuscator | Obfuscapk - LibEncryption plugin — `assets/lib.<arch>.<name>.so` 正则 |

## 🔍 规则源码示例

### `arxan_guardit` — 配置文件足迹

```yara
rule arxan_guardit : obfuscator {
  meta:
    description = "Arxan GuardIT"
    url         = "https://www.arxan.com"
    sample      = "0da79f5202b4c29c4ef43f769d5703a3d4ebfa65e49ea967abb49965d4ac3ba4"
    author      = "Eduardo Novella"

  strings:
    // guardit4j.fin -- in root of apk; contains GuardIT version
    $cfg = { 00 67 75 61 72 64 69 74 34 6A 2E 66 69 6E }
  condition:
    is_apk and #cfg > 1
}
```

`guardit4j.fin` 是 Arxan GuardIT 的版本配置文件，`#cfg > 1` 要求出现多次（根目录 + 可能的副本），降低误报。

### `obfuscapk_libencryption` — 架构正则

```yara
rule obfuscapk_libencryption : obfuscator {
  strings:
    $lib_arm = /assets\/lib\.arm(eabi|64)-v[0-9a-zA-Z]{2}\.[!-~]+\.so/
    $lib_x86 = /assets\/lib\.x86(_64)?\.[!-~]+\.so/
  condition:
    any of them and is_apk
}
```

Obfuscapk 的 LibEncryption 插件把加密后的 so 放在 `assets/lib.<arch>.<name>.so` 路径——用正则匹配架构前缀和任意库名。

## 📊 finding 示例

```json
{
  "tag": "obfuscator::arxan_guardit",
  "category": "obfuscator",
  "source": "app.apk!guardit4j.fin",
  "identifier": "arxan_guardit",
  "confidence": "low"
}
```

## 🧠 APK 层 vs DEX 层混淆

APK 层混淆规则只看"有没有这个资产文件"，而 DEX 层混淆规则（[`dex/obfuscators.yara`](./dex-obfuscators)，22 条）深入字节码看 **字段/方法名是否被 Unicode 混淆**、**是否有字符串加密的 opcode 序列**。DexGuard、StringFog、BlackObfuscator 这些主要在 DEX 层检测。

## 📍 相关

- [obfuscator 类别](./category-obfuscator) — 混淆概念与全文件类型分布
- [DEX 混淆器规则](./dex-obfuscators) — 字节码层混淆检测（22 条 + 2 private）
- [compiler 类别](./category-compiler) — 编译器 vs 混淆器
- [APK 规则总览](./apk-overview) — APK 层规则全貌
