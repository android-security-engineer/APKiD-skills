# ELF 加固 (packers)

<span class="badge badge-pack">packer</span>
<span class="badge badge-info">ELF</span>
<span class="badge badge-info">44 条</span>

`elf/packers.yara` 检测原生层（`.so`）加固工具。重头戏是 **UPX 全版本指纹**——从 3.01 到 3.94，外加梆梆/SecNeo、爱加密、Joker 等魔改 UPX 变体，以及嵌入式/未识别版本等形态。

## 🎯 ELF 加固的形态

ELF 层加固分几类：

- **UPX 压缩**：标准 UPX 或被厂商改了 stub 标记的 UPX 变体。
- **厂商壳的 so 库**：360（`libjiagu`）、腾讯（`libshell`/`libxgVipSecurity`）、梆梆、通付盾等，壳代码跑在 so 里。
- **嵌入式 payload**：UPX 压缩的 ELF 被塞进另一个 ELF 或 APK（dropper/embedded）。

## 📋 规则清单

### UPX 系列（版本指纹 + 变体）

| 规则 | tag | 说明 |
|------|-----|------|
| `upx_elf_3_91` | packer | UPX 3.91（原版） |
| `upx_elf_3_92` | packer | UPX 3.92（原版，含 Android so 修复） |
| `upx_elf_3_93` | packer | UPX 3.93（原版） |
| `upx_elf_3_94` | packer | UPX 3.94（原版） |
| `upx_elf_3_01` | packer | UPX 3.01（原版） |
| `upx_elf_3_02` | packer | UPX 3.02（原版） |
| `upx_elf_3_03` | packer | UPX 3.03（原版） |
| `upx_elf_3_04` | packer | UPX 3.04（原版） |
| `upx_elf_3_07` | packer | UPX 3.07（原版） |
| `upx_elf_3_08` | packer | UPX 3.08（原版） |
| `upx_elf_3_09` | packer | UPX 3.09（原版） |
| `upx_sharedlib_unmodifed` | packer | 共享库 UPX（原版，`ET_DYN`） |
| `upx_elf_bangcle_secneo` | packer | 梆梆/SecNeo（把 `UPX!` 换成 `SEC!`） |
| `upx_elf_bangcle_secneo_newer` | packer | 新版梆梆/SecNeo（换成 `\x03\x02\x01\x00`） |
| `upx_elf_ijiami` | packer | 爱加密（把 `UPX!` 换成 `AJM!`） |
| `upx_elf_joker` | packer | Joker（换成 `ZHSH` 或 `TIW°`） |
| `upx_embedded_inside_elf` | packer, dropper | ELF 内嵌 UPX 压缩的 ELF |
| `upx_compressed_apk` | packer, embedded | APK 内嵌 UPX 压缩的 ELF |
| `upx_unknown_version_modified` | packer | UPX（未识别版本，已魔改） |
| `upx_unknown_version_unmodified` | packer | UPX（未识别版本，原版） |

### UPX private 积木（不输出）

| 规则 | 说明 |
|------|------|
| `upx_elf32_arm_stub` | 含 UPX ARM32 stub 字节序列 |
| `upx_stub` | 含 UPX stub（封装 `upx_elf32_arm_stub`） |
| `upx_unmodified` | 含原版 UPX stub（`UPX!` 在头尾且匹配 ARM stub） |
| `upx_unknown_version` | UPX（未知版本兜底，排除已知版本/变体） |

### 其它加固方案

| 规则 | tag | 说明 |
|------|-----|------|
| `promon` | packer | Promon Shield（`libshield.so`/随机库名 + `.ncu/.ncc/.ncd` 节区） |
| `promon_a` | packer | Promon Shield（变体，节区指纹） |
| `appsealing_core_2_10_10` | packer | AppSealing CORE 2.10.10 |
| `appsuit_packer_a` | packer | AppSuit（`libAppSuit.so` + `libUnpacker.so`） |
| `tencent_elf` | packer | 腾讯 MTP（`libshell.so` 依赖链） |
| `tencent_legu_VMP_elf` | packer | 腾讯乐固 VMP（`libxgVipSecurity.so`） |
| `tongfu_shield_elf` | packer | 通付盾（`libegis.so`/`assets/libegis.a`） |
| `crackproof` | packer | CrackProof（ARM32 `do_asm_syscall` 指纹） |
| `crackproof_a` | packer | CrackProof（ARM64 `init_proc` + syscall 指纹） |
| `jiagu_native` | packer | 360 加固原生层（`libjiagu` + `JIAGU_*` 常量） |
| `blackmod` | packer | BlackMod（`libbmt.so` + SVC 指纹） |
| `_5play_ru` | packer | 5play.ru（`libRMS.so` + openat SVC） |
| `liapp_elf` | packer | LIAPP（`libliapp.so`） |
| `eversafe_elf` | packer | Eversafe（`libeversafe.so`） |
| `aegis_elf` | packer | Aegis（`libaegis_e*.so`） |
| `appguard_elf` | packer | AppGuard（`libAppGuard.so` + INCA 类） |
| `appguard_elf_b` | packer | AppGuard（变体，`libcompatible.so`） |
| `dxshield_elf` | packer | DxShield（`libdxbase.so`） |
| `zimperium_zshield` | packer | Zimperium zShield（ARM64 SVC + 缓存刷新指纹） |
| `zimperium_zshield_a` | packer | Zimperium zShield（变体，内联 syscall ≥50） |
| `nesun_elf` | packer | Nesun（`.zprotect` 路径 + `libzprotect.so`） |
| `gpresto_elf` | packer | G-Presto 反作弊（`libATG_L.so` + Presto 类） |
| `kiwisec_elf` | packer | KiwiSec（`libKwProtectSDK.so` 等） |
| `tso_trusteer_sdk` | packer | IBM Trusteer SDK（`.tsotext/.tsodata` 节区） |

## 🔍 检测原理要点

### UPX 版本指纹

UPX 在压缩时把版权字符串写进 stub。APKiD 用 `"UPX 3.94 Copyright"` 这类字符串精确匹配版本，同时要求 stub 字节序列与 `UPX!` 标记在文件头尾出现（防误报）：

```yara
rule upx_elf_3_94 : packer {
  strings:
    $copyright = "UPX 3.94 Copyright"
  condition:
    upx_unmodified and $copyright   // upx_unmodified 要求 UPX! 在头尾 + ARM stub
}
```

### 魔改 UPX 识别

厂商常把 `UPX!` 标记替换成自家标识，但 stub 字节序列改不掉。规则靠 `upx_stub`（ARM stub）仍在 + 替换标记识别变体：

- 梆梆/SecNeo：`UPX!` → `SEC!`（旧）或 `{ 03 02 01 00 }`（新）
- 爱加密：`UPX!` → `AJM!`
- Joker：`UPX!` → `ZHSH` / `TIW°`

### 嵌入式 UPX（dropper）

`upx_embedded_inside_elf` 检测 ELF 内嵌另一个 UPX 压缩的 ELF——靠"文件开头有 ELF 魔数 `7F 45 4C 46`，且 256 字节之后又出现 ELF 魔数"识别，tag 同时带 `packer` 和 `dropper`。`upx_compressed_apk` 类似，但 payload 嵌在 APK 里，tag 带 `embedded`。

### so 库符号指纹

多数厂商壳靠特征 so 库名 + JNI 类名识别。如 `tencent_legu_VMP_elf` 匹配 `libxgVipSecurity.so`，`tongfu_shield_elf` 匹配 `libegis.so` + `com/payegis/FirstApplication`。

### 代码指纹（无字符串时）

`crackproof`、`zimperium_zshield` 等壳剥离了字符串，靠 ARM 指令序列指纹识别——如 `do_asm_syscall` 的 `SVC 0` + 寄存器布局，或 ARM64 内联 syscall 的 `MOV X8, #nr` + `SVC 0` + `CMN X0, #4` 模式。

## 📊 finding 示例

```json
{
  "tag": "packer::upx_elf_3_92",
  "category": "packer",
  "source": "app.apk!lib/armeabi-v7a/libfoo.so",
  "identifier": "upx_elf_3_92",
  "confidence": "medium",
  "version": "3.92"
}
```

`version: "3.92"` 由 `_extract_version()` 从规则名 `upx_elf_3_92` 提取。

## 📍 相关

- [packer 类别](./category-packer) — 加固概念与跨文件类型分布
- [dropper 类别](./category-dropper) — `upx_embedded_inside_elf` 的 dropper tag
- [ELF 规则总览](./elf-overview) · [ELF 保护器](./elf-protectors) · [ELF 混淆器](./elf-obfuscators)
- [文件类型识别（指南）](../guide/file-types)
