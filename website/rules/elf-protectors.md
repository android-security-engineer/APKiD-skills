# ELF 保护器 (protectors)

<span class="badge badge-protect">protector</span>
<span class="badge badge-info">ELF</span>
<span class="badge badge-info">33 条</span>
<span class="badge badge-anti">anti_root ×2</span>

`elf/protectors.yara` 检测原生层（`.so`）保护/加固 SDK，尤其是 RASP（运行时自保护）方案。注意有 **2 条规则的 tag 是 `anti_root`**（`ahnlab_v3_engine`、`rootbeer`），因为它们专做 Root 检测，是 protector 的子集。

## 🎯 ELF 保护器做什么

保护 SDK 的 so 库在 `Application.attachBaseContext` 里加载，做运行时防护：

- **反调试**：检测 ptrace、`/proc/self/status` 的 TracerPid。
- **反 Hook**：扫描 `/proc/self/maps` 找 Frida/Xposed。
- **反 Root**：检测 Magisk、SuperSU、su 二进制。
- **环境检测**：模拟器、虚拟机、多开。
- **代码完整性**：校验 dex/so 是否被篡改。
- **内联 syscall**：直接 `SVC 0` 绕过 libc hook。

## 📋 规则清单

| 规则 | tag | 说明 |
|------|-----|------|
| `whitecryption_elf` | protector | WhiteCryption（`scpClassInit`/`SCP_EmptyFunction` + ARM stub） |
| `whitecryption_elf_a` | protector | WhiteCryption（`whiteCryptionSecureKeyBox`/`libSecureKeyBoxJava.so`） |
| `ahnlab_v3_engine` | **anti_root** | AhnLab V3（`engmgr_startRootCheck`） |
| `appdome_elf` | protector | Appdome（`__start_adinit`/`__start_hook`/`__start_ipcent` 导出符号） |
| `appdome_elf_a` | protector | Appdome（变体，`hook/.hookname/adinit/.adi/ipcent/ipcsel/.rhash/.imtab` 节区） |
| `appdome_elf_b` | protector | Appdome（变体，`libloader.so` + `LIBLOADER_VERSION=` + 节区） |
| `metafortress` | protector | InsideSecure MetaFortress（`MetaFortress`/`METAFORIC`/JNI 符号） |
| `virbox_elf` | protector | Virbox（`Virbox Protector` 品牌） |
| `vkey_elf` | protector | Vkey V-OS（`libvosWrapperEx.so` + Frida/GDB/模拟器检测串 + JNI 符号） |
| `verimatrix_arm64` | protector | Verimatrix（ARM64，`BRK #0x3E8` ≥50 + `SVC 0` ≥50 + 无 `.text` 节区） |
| `verimatrix_arm64_a` | protector | Verimatrix（变体，`.mfrt` 节区 + SYS/DSB/ISB 缓存刷新 + 随机库名） |
| `verimatrix_arm64_b` | protector | Verimatrix（变体，DC/DSB/IC/ISB + mmap/munmap SVC + `JNI_OnLoad`） |
| `verimatrix_arm64_c` | protector | Verimatrix（变体，`.rodata` 模式 + 通用 opcode 序列） |
| `protectt` | protector | Protectt（`libprotectt-native-lib.so`/`libprotecttai.so`） |
| `googleIntegrityProtection` | protector | Google Play Integrity（`libpairipcore.so` + `ExecuteProgram`） |
| `ahope_appshield` | protector | Ahope AppShield（`libahope*.so`） |
| `appcamo` | protector | AppCamo（`appcamo`/`libalib.so`/`DexClassLoader`） |
| `appsealing` | protector | Appsealing（`libcovault-appsec.so`/`appsealing.dex`/`AppSealingApplication`） |
| `zimperium_zdefend` | protector | Zimperium zDefend（`libZDefend.so` + `zimperium` 出现 >10） |
| `zimperium_z9` | protector | Zimperium z9（`libz9.so` + `zimperium` >10） |
| `zimperium_zcloud` | protector | Zimperium zcloud（`libzcloud.so` + `zimperium` >10） |
| `msa_sdk` | protector | MSA 移动安全联盟（`libmsaoaidauth.so`/`libmsaoaidsec.so` + `mprotect`） |
| `nhn_appguard` | protector | NHN AppGuard（`appguard_header->Get*PayloadLength()` + AppGuard 类） |
| `easyprotector` | protector | EasyProtector（`libantitrace.so` + ptrace 自检日志） |
| `rootbeer` | **anti_root** | RootBeer（`Java_com_scottyab_rootbeer_..._checkForRoot` + `libtoolChecker.so`） |
| `build38` | protector | Build38（`libtak.so` + `Lcom/build38/tak/NativeResponse;`） |
| `dpt_shell` | protector | DPT Shell（`libdpt.so`/`bytehook_tag` + `.bitcode` 节区） |
| `free_rasp_dart` | protector | FreeRASP（Dart，`package:freerasp/...` + `TalsecException`） |
| `shield_sdk` | protector | Shield SDK（`libcashshieldabc-native-lib.so` + `NativeUtils` 类） |
| `bugsmirror` | protector | BugsMirror（`libdefender.so` + `.crypted` 节区） |
| `bshield` | protector | BShield（`Lio/bshield/callback/ShieldDataProtection;`） |
| `denuvo_elf` | protector | Denuvo 反篡改（`libvmpc.so`） |
| `bureau` | protector | Bureau（`libbureau-*/libsecure_keys/libndkdatacollector.so` + Root/Frida JNI） |

## 🔍 检测原理要点

### 导出符号与字符串指纹（最常见）

多数保护 SDK 有特征 so 库名、JNI 符号或品牌字符串。如 `vkey_elf` 匹配 `libvosWrapperEx.so` + V-OS 固件版本串 + Frida/GDB/模拟器检测串 + `Java_vkey_android_vos_VosWrapper_*` JNI 符号，要求四类各命中至少一条。

### 节区名指纹

部分 SDK 自定义节区存放壳代码。Appdome 用 `hook/.hookname/adinit/.adi/ipcent/ipcsel/.rhash/.imtab`，DPT Shell 用 `.bitcode`，BugsMirror 用 `.crypted`，Verimatrix 用 `.mfrt`，Trusteer（packer）用 `.tsotext/.tsodata`。YARA 的 `elf.sections[i].name` 让节区名成为可靠指纹。

### 内联 syscall 指纹

Verimatrix、Zimperium zShield 等高强度保护直接用 `SVC 0` 绕过 libc hook。规则用 opcode 计数识别：

```yara
rule verimatrix_arm64 : protector {
  strings:
    $brk_0_3e8 = { 00 7D 20 D4 }   // BRK #0x3E8
    $svc_0     = { 01 00 00 D4 }   // SVC 0
  condition:
    elf.machine == elf.EM_AARCH64
    and #svc_0 >= 50               // 至少 50 条内联 syscall
    and #brk_0_3e8 >= 50           // 反调试断点 ≥50
    and ... no .text section       // 代码节被改名
}
```

`zimperium_zshield_a` 要求 `#svc > 50`，`dexguard_native_arm64` 要求 `#svc >= 6`——计数阈值是区分保护壳与普通 libc 调用的关键。

### 缓存刷新指纹

ARM64 的 `DC CVAU` / `IC IVAU` / `DSB ISH` / `ISB` 序列是运行时代码修改（自修改、JIT 解密）的标志，Verimatrix 与 zShield 都用这条指纹。

### Dart AOT 专属

`free_rasp_dart` 的 condition 是 `is_dart`（而非 `is_elf`），只对 Flutter 的 `libapp.so` 触发——靠 `package:freerasp/src/...` Dart 路径串识别。

## 📊 finding 示例

```json
{
  "tag": "protector::verimatrix_arm64",
  "category": "protector",
  "source": "app.apk!lib/arm64-v8a/libvkey.so",
  "identifier": "verimatrix_arm64",
  "confidence": "medium"
}
```

`ahnlab_v3_engine` 和 `rootbeer` 输出的 `category` 是 `anti_root`（不是 `protector`），因为它们的 YARA tag 是 `anti_root`。

## 📍 相关

- [protector 类别](./category-protector) — 概念与跨文件类型分布
- [anti_root 类别](./category-anti-root) — `ahnlab_v3_engine`/`rootbeer` 的归类
- [ELF 规则总览](./elf-overview) · [ELF 加固](./elf-packers) · [ELF 混淆器](./elf-obfuscators)
- [文件类型识别（指南）](../guide/file-types)
