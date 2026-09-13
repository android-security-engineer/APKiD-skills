# 类别：protector 保护器

<span class="badge badge-protect">protector</span>

`protector` 类别检测 **应用保护/加固 SDK**，尤其是 RASP（Runtime Application Self-Protection）方案。与 [packer](./category-packer) 不同，protector 通常不重打包 dex，而是注入 SDK 做运行时保护。

## 🎯 什么是保护 SDK

保护器（protector）做这些事：

- **反调试**：检测 ptrace、调试器附加。
- **反 Hook**：检测 Frida、Xposed、Substrate。
- **反 Root**：检测 Magisk、SuperSU。
- **环境检测**：模拟器、虚拟机、多开。
- **代码完整性**：校验 dex/so 是否被篡改。
- **运行时拦截**：在关键 API 上插桩，阻止恶意调用。

典型形态：APK 里塞入一个 so 库（如 `libAppGuard.so`），在 `Application.attachBaseContext` 里加载，hook 关键路径。

## 📋 规则分布

| 文件类型 | 文件 | 规则数 | 子文档 |
|---------|------|:---:|------|
| APK | `apk/protectors.yara` | 20 | [APK 保护器](./apk-protectors) |
| DEX | `dex/protectors.yara` | 31 | [DEX 保护器](./dex-protectors) |
| ELF | `elf/protectors.yara` | 33 | [ELF 保护器](./elf-protectors) |
| RES | `res/protectors.yara` | 1 | [RES 规则](./res-overview) |

## 🏢 主要保护 SDK

| SDK | 规则 | 说明 |
|-----|------|------|
| Verimatrix | `verimatrix`、`verimatrix_arm64`/`_a`~`_c` | 视频流保护出身 |
| Virbox | `virbox_apk`、`virbox_elf` | 深思维 |
| Vkey | `vkey_apk`、`vkey_elf` | |
| Appdome | `appdome_dex`、`appdome_elf`/`_a`/`_b` | 云端加固 |
| FreeRASP | `free_rasp_old`、`free_rasp_new`、`free_rasp_dex`、`free_rasp_dart` | 开源 RASP |
| AhnLab | `ahnlab_v3_engine` | 韩国 |
| Ahope | `ahope_appshield` | |
| MetaFortress | `metafortress` | ELF |
| WhiteCryption | `whitecryption_dex`/`_a`、`whitecryption_elf`/`_a` | 代码加密 |
| Zimperium | `zimperium_zdefend`、`z9`、`zcloud`、`zshield` | 移动安全厂商 |
| Denuvo | `denuvo_apk`、`denuvo_elf` | 游戏反篡改 |
| Google Integrity | `googleIntegrityProtection` | Play Integrity |
| MSA SDK | `msa_sdk` | 移动安全联盟 |
| RootBeer | `rootbeer`（dex/elf） | 反 Root 库（也归 anti_root） |
| 其它 | `vguard`、`appdefence`、`dpt_shell`、`build38`、`shield_sdk`、`bshield`、`alibaba_sec`、`bureau`、`haiyun`、`oppo_protect`、`bugsmirror`、`tongfu_shield`、`venustech`、`dexprotectx`、`eversafe`、`appcamo`、`easyprotector`、`protectt`、`nhn_appguard`... | |

完整清单见各子文档。

## 🔍 检测特征举例

保护 SDK 的 so 库通常有特征导出符号或字符串：

```yara
rule verimatrix : protector {
  strings:
    $sym = "Verimatrix"
    $lib = "libvkey.so"
  condition:
    is_apk and ($sym or $lib)
}
```

## 📊 finding 示例

```json
{
  "tag": "protector::verimatrix_arm64",
  "category": "protector",
  "description": "Detects app protection/shielding SDKs",
  "source": "app.apk!lib/arm64-v8a/libvkey.so",
  "identifier": "verimatrix_arm64",
  "confidence": "medium"
}
```

`source` 含 `.so` → ELF 匹配，置信度 `medium`。

## 🆚 packer vs protector

| 维度 | packer | protector |
|------|--------|-----------|
| 做什么 | 加密/重打包 dex | 注入 RASP SDK |
| 改结构 | 是（dex 变壳） | 否（dex 结构基本不变） |
| 关注点 | 还原真实代码 | 运行时防护 |
| 典型 | 360 加固、梆梆 | Verimatrix、Appdome |

两者常 **同时存在**：加固的 APK 往往也套保护 SDK。APKiD 会分别报告两类 finding。

## 🔗 与 anti_root 的关系

部分库（如 `rootbeer`、`ahnlab_v3_engine`、`flutterjailbreakdetection`）的 tag 是 `anti_root` 而非 `protector`——因为它们专做 Root 检测，是 protector 的子集。详见 [anti_root 类别](./category-anti-root)。

## 📍 相关

- [APK 保护器](./apk-protectors) · [DEX 保护器](./dex-protectors) · [ELF 保护器](./elf-protectors)
- [packer 类别](./category-packer) — 区别
- [anti_root 类别](./category-anti-root) — 子集
- [检测类别](../guide/categories)
