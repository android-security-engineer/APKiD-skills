# APK common 规则

<span class="badge badge-file">file_type</span>
<span class="badge badge-info">internal</span>
<span class="badge badge-file">3 条</span>

`apkid/rules/apk/common.yara` — 3 条规则（1 条公开 + 2 条 private）。这是 APK 规则的 **前置条件层**：定义 `is_apk` 判定，以及签名状态判定，被所有其它 APK 规则引用。

## 🎯 is_apk 是所有 APK 规则的门

`packers.yara`、`protectors.yara`、`obfuscators.yara` 里每条规则都带 `is_apk and ...`。先确认"这是个 APK"，再匹配壳特征——避免在普通 ZIP 文件上误报。

## 📋 规则清单

| 规则 | tag | 可见性 | 说明 |
|------|-----|--------|------|
| `is_apk` | file_type | 公开 | APK（ZIP 头 `PK` at 0 + `AndroidManifest.xml` 出现 ≥ 2 次） |
| `is_signed_apk` | internal | private | 类似已签名、可能未损坏的 APK（META-INF 下有 .RSA/.DSA/.EC 或 APK Sig Block v2） |
| `is_unsigned_apk` | internal | private | 类似未签名的 APK（`is_apk and not is_signed_apk`） |

## 🔍 规则源码

### `is_apk` — ZIP 容器 + Manifest 双重确认

```yara
rule is_apk : file_type {
  meta:
    description = "APK"
  strings:
    $zip_head = "PK"
    $manifest = "AndroidManifest.xml"
  condition:
    $zip_head at 0 and $manifest and #manifest >= 2
}
```

要点：
- `$zip_head at 0`：文件开头必须是 `PK`（ZIP 本地文件头魔数）。
- `#manifest >= 2`：`AndroidManifest.xml` 至少出现 **2 次**——因为 APK 里既有原始 `AndroidManifest.xml` 条目，又被编译进 `resources.arsc`，所以会多次出现。单次可能是巧合，两次才稳。

### `is_signed_apk` — 签名状态判定

```yara
private rule is_signed_apk : internal {
  meta:
    description = "Resembles a signed APK that is likely not corrupt"
  strings:
    $meta_inf = "META-INF/"
    $ext_rsa = ".RSA"
    $ext_dsa = ".DSA"
    $ext_ec = ".EC"
    $apk_sig_block_footer = { 41 50 4B 20 53 69 67 20 42 6C 6F 63 6B 20 34 32 50 4B 01 02 }
  condition:
    is_apk and
    (
      for all of ($meta_inf*) : ($ext_rsa or $ext_dsa or $ext_ec in (@ + 9..@ + 9 + 100)) or
      $apk_sig_block_footer
    )
}
```

签名判定逻辑：
- **v1 签名**：`META-INF/` 下有 `.RSA`/`.DSA`/`.EC` 签名文件（`for all` 确保每个 META-INF 条目附近都有签名扩展名）。
- **v2/v3 签名**：APK Signing Block 的尾部 footer `APK Sig Block 42PK\x01\x02`（hex `41 50 4B 20 53 69 67...`）。

`is_unsigned_apk` 就是 `is_apk and not is_signed_apk`——签了名的优先，没匹配到签名特征的归为未签名。

## 📊 输出行为

`is_apk` 是 `file_type` tag，**默认不输出**（信息量低，用户已知是 APK）。需要 `--include-types` 才显示。`is_signed_apk`/`is_unsigned_apk` 是 `internal` tag，永远不直接输出，只被其它规则引用。详见 [file_type 类别](./category-file-type)。

## 🧠 为什么不用文件扩展名

APKiD 不看 `.apk` 扩展名——扩展名可随意改。只信字节：ZIP 魔数 + AndroidManifest.xml 的存在。这能识别改名为 `.zip`/`.jar`/无扩展名的 APK，也能排除改名为 `.apk` 的普通 ZIP。

## 📍 相关

- [file_type 类别](./category-file-type) — 为什么 file_type 默认不输出
- [APK 规则总览](./apk-overview) — APK 层规则全貌
- [组织方式](./organization) — common.yara 的角色
- [文件类型](../guide/file-types) — APK/DEX/ELF 概念
- [DEX common 规则](./dex-common) — 对照 `is_dex` 的写法
