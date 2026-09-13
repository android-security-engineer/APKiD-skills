# 类别：packer 加固

<span class="badge badge-pack">packer</span>

`packer` 类别检测 **APK 加固/打包工具**。这些工具把原始 dex 加密、压缩或重打包，运行时由壳代码解密还原。是 APKiD 检测量最大的类别（150+ 规则）。

## 🎯 什么是加固

加固（packing）流程：

```
原始 dex → 加密/压缩 → 塞进 APK → 运行时壳代码解密 → 加载真实 dex
```

被加固的 APK 解压后 `classes.dex` 通常只是壳（一个 Application 类），真实代码藏在加密资产或 so 库里。APKiD 通过识别壳的特征文件名、so 符号、dex 结构来判定用了哪种加固。

## 📋 规则分布

`packer` tag 的规则按文件类型分布：

| 文件类型 | 文件 | 规则数 | 子文档 |
|---------|------|:---:|------|
| APK | `apk/packers.yara` | 75 | [APK 加固](./apk-packers) |
| DEX | `dex/packers.yara` | 29 | [DEX 加固](./dex-packers) |
| ELF | `elf/packers.yara` | 44 | [ELF 加固](./elf-packers) |

同一加固方案常在三类文件下都有规则（如 360 加固：`jiagu_360_v5`、`jiagu_360_dex`、`jiagu_native`），从不同角度确认。

## 🏢 主要厂商/工具

| 加固方案 | 代表规则 | 备注 |
|---------|---------|------|
| 360 加固 | `jiagu_360_v4`/`v5`/`v6`、`qihoo360`、`jiagu_native` | 国内主流 |
| 腾讯乐固 | `tencent_legu`、`tencent_legu_VMP`、`tencent_legu_2024` | 含 VMP 版 |
| 梆梆 | `bangcle`、`bangcle_secshell`、`bangcle_dex`、`bangcle_standard` | 多版本 |
| 爱加密 | `ijiami`、`ijiami_pro`、`ijiami_dex` | |
| 百度加固 | `baidu`、`baidu_jiagu_dex` | |
| 阿里 | `alibaba`、`alibaba_jiagu_v2`、`alibaba_jiagu_dex` | |
| AppGuard | `appguard`/`_a`/`_b`/`_c`/`_d`/`_dex`/`_elf` | |
| DexProtector | `dexprotector`/`_a`~`_d` | 跨 dex/elf |
| AppSealing | `appsealing`、`appsealing_core_2_10_10` | |
| UPX | `upx_elf_3_91`~`3_94`、`upx_unknown_version_*` | ELF，多版本 |
| 其它 | `naga`、`kony`、`approov`、`yidun`、`aegis`、`eversafe`... | |

完整清单见各子文档。

## 🔍 检测特征举例

### 路径/资产文件特征（APK 层）

```yara
// jiagu_360_v5：通过 assets 里的 so 库文件名识别
rule jiagu_360_v5 : packer {
  strings:
    $lib = "libjiagu.so"
    $lib64 = "libjiagu_art.so"
  condition:
    is_apk and ($lib or $lib64)
}
```

### so 库符号（ELF 层）

加固的壳代码在 so 库里，有特定导出符号或字符串。

### dex 结构特征（DEX 层）

```yara
// bangcle_dex：dex 层的梆梆特征
rule bangcle_dex : packer {
  condition:
    is_dex and $bangcle_marker
}
```

## 📊 finding 示例

```json
{
  "tag": "packer::jiagu_360_v5",
  "category": "packer",
  "description": "Detects APK packing/obfuscation tools",
  "source": "app.apk!assets/libjiagu.so",
  "identifier": "jiagu_360_v5",
  "confidence": "low"
}
```

`source` 带 `!assets/...` → APK 层路径匹配，置信度 `low`。若命中 `app.apk!classes.dex` 的 dex 层规则，置信度 `high`。

## 🆚 与 protector 的区别

- **packer**：把 dex 加密/打包，运行时解密还原。重打包，结构变了。
- **protector**：不重打包，而是注入 RASP SDK 做运行时保护（反调试、反 Hook、环境检测）。

两者常共存——加固的 APK 往往也套了保护 SDK。详见 [protector 类别](./category-protector)。

## 📍 相关

- [APK 加固规则](./apk-packers) · [DEX 加固](./dex-packers) · [ELF 加固](./elf-packers)
- [protector 类别](./category-protector) — 区别
- [检测类别](../guide/categories) — 全类别速查
