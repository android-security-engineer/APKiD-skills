# DEX 保护器规则

<span class="badge badge-protect">protector</span>
<span class="badge badge-anti">anti_root</span>
<span class="badge badge-protect">31 条</span>

`apkid/rules/dex/protectors.yara` — 31 条规则。DEX 层保护器规则匹配 **保护 SDK 注入的 stub 类名、包路径、字符串字面量**，从字节码层确认 RASP（运行时应用自保护）SDK。其中有 3 条 tag 是 `anti_root`（反 root 检测）而非 `protector`。

## 🎯 检测原理

保护器 SDK 不重打包 dex，但会 **注入自己的类** 到 dex 里——如 `Lcom/whitecryption/jcp/generated/scp;`、`Lcom/build38/tak/TAK;`、`Lcom/scottyab/rootbeer/RootBeer;`。APKiD 扫描 `classes.dex` 的 string_pool，匹配这些类名字节序列。

## 📋 规则清单

### 🔐 商业保护 SDK（protector tag）

| 规则 | tag | 说明 |
|------|-----|------|
| `CNProtect_dex` | protector | CNProtect (anti-disassemble) — 注入代码段 + junk opcodes |
| `whitecryption_dex` | protector | WhiteCryption — `Lcom/whitecryption/jcp/generated/scp;` + `__scpClassInit` |
| `whitecryption_dex_a` | protector | WhiteCryption — `whitecryption.com` URL + Cryptanium 字符串 |
| `appdome_dex` | protector | Appdome — `Lruntime/loading/InjectedActivity;` 注入类 |
| `insidesecure` | protector | InsideSecure Verimatrix — `Lcom/insidesecure/core/` 前缀 |
| `free_rasp_dex` | protector | FreeRASP — 完整字符串解密 opcode 序列（hex2bytes + XOR） |
| `appiron` | protector | Secucen AppIron — `Lcom/barun/appiron/android/AppIron;` 等 |
| `ahope_appshield` | protector | Ahope AppShield — `Lcom/ahope/app_shields/BuildConfig;` 等 |
| `vguard` | protector | VGuard — `Lkr/co/sdk/vguard2/EdexJNI;` |
| `appdefence` | protector | ExTrus AppDefence — `Lnet/extrus/exafe/appdefence/module/.../DefenceApiImpl;` |
| `xiaomi_xsof_sdk` | protector | Xiaomi Security Open Service Client SDK — `com.xiaomi.security.xsof.` 前缀（>1 次） |
| `dpt_shell` | protector | DPT Shell — `Lcom/luoye/dpt` + `dpt-libs`/`libdpt.so` 字符串 |
| `nhn_appguard_dex` | protector | NHN AppGuard — `Lcom/nhn(cloud|ent)/appguard/` 包前缀 |
| `protectt_dex` | protector | Protectt — `Lai/protectt/app/security/R;` |
| `flutter_security_checker` | protector | Flutter Security Checker — `Lcom/pravera/flutter_security_checker/...Plugin;` |
| `build38` | protector | Build38 — `Lcom/build38/tak/TAK;` + `license.tak` |
| `shield_sdk` | protector | Shield SDK — `Lcom/shield/android/Shield;` 等 4 个类 |
| `bugsmirror` | protector | BugsMirror — `BugsMirrorDefender` 标签 + 多个类 |
| `bshield` | protector | BShield — `BSHIELD_DAT` 字符串 |
| `alibaba_sec` | protector | Alibaba Security SDK — `Lcom/ali/mobisecenhance/Init;` |
| `bureau` | protector | Bureau — `api.(stg.)?bureau.id` + `Lcom/bureau/devicefingerprint/BureauAPI;` |
| `yidun_dex` | protector | NetEase Yidun (DEX-level) — `Lcom/netease/nis/wrapper/Entry;` + `libnesec.so` |
| `tongfu_shield_dex` | protector | Tongfu Shield (DEX-level) — `Lcom/egis/shield/StubApplication;` + `libegis.so` |
| `nq_shield_dex` | protector | NQ Shield (DEX-level) — `Lcom/nq/shield/StubApplication;` + `libnqshield.so` |
| `venustech_dex` | protector | Venustech (DEX-level) — `Lcom/venustech/vempsdk/StubApp;` |
| `dexprotectx_dex` | protector | DexProtect X (DEX-level) — `Lcom/dexprotectx/StubApp;` / `Lcom/dexshell/StubApp;` |
| `eversafe_dex` | protector | Eversafe (DEX-level) — `Lcom/eversafe/StubApp;` + `EversafeApplication` |
| `appcamo_dex` | protector | AppCamo (DEX-level) — `Lcom/appcamo/StubApp;` + `CamoApplication` |

### 🚫 反 root 检测（anti_root tag）

注意这 3 条规则的 tag 是 **`anti_root`** 不是 `protector`——它们做的是 root 检测，属于保护 SDK 的一个子能力：

| 规则 | tag | 说明 |
|------|-----|------|
| `ahnlab_v3_engine` | anti_root | Ahnlab V3 Engine — `Lcom/ahnlab/enginesdk/` 类引用 > 10 次 |
| `flutterjailbreakdetection` | anti_root | Flutter Jailbreak Detection (RootBeer) — `Lappmire/be/flutterjailbreakdetection/...Plugin;` |
| `rootbeer` | anti_root | RootBeer — `Lcom/scottyab/rootbeer/RootBeer;` 类名 |

## 🔍 规则源码示例

### `appdome_dex` — 注入类名

```yara
rule appdome_dex : protector {
  strings:
    // Lruntime/loading/InjectedActivity;
    $loader = {
      00 22 4C 72 75 6E 74 69 6D 65 2F 6C 6F 61 64 69
      6E 67 2F 49 6E 6A 65 63 74 65 64 41 63 74 69 76
      69 74 79 3B 00
    }
  condition:
    is_dex and $loader
}
```

字节序列解码为 `Lruntime/loading/InjectedActivity;`——Appdome 给所有保护的 APK 注入这个 loader 类，类名不变（"InjectedActivity" 太明确），是绝佳指纹。

### `rootbeer` — 开源反 root 库

```yara
rule rootbeer : anti_root {
  strings:
    $class = { 00 20 4C 63 6F 6D 2F 73 63 6F 74 74 79 61 62 2F 72
               6F 6F 74 62 65 65 72 2F 52 6F 6F 74 42 65 65 72 3B 00 }
    // Lcom/scottyab/rootbeer/RootBeer;
  condition:
    is_dex and all of them
}
```

RootBeer 是 [开源反 root 库](https://github.com/scottyab/rootbeer)，许多应用直接集成。命中说明应用做了 root 检测（不一定是恶意，但值得注意）。

### `free_rasp_dex` — opcode 序列指纹

`free_rasp_dex` 匹配 FreeRASP 的字符串解密 opcode 序列：`String.length()` → 除以 2 → `charAt` → `Character.digit` → 左移 4 位 → XOR 解密。这种 opcode 级指纹抗混淆能力强。详见源码。

## 📊 finding 示例

```json
{
  "tag": "protector::appdome_dex",
  "category": "protector",
  "source": "app.apk!classes.dex",
  "identifier": "appdome_dex",
  "confidence": "high"
}
```

DEX 字节码级匹配 → 置信度 `high`。

## 🧠 同名 SDK 在 APK 层也有规则

许多保护 SDK 同时在 [`apk/protectors.yara`](./apk-protectors) 有 APK 层规则（如 `build38`、`shield_sdk`、`bshield`、`bureau`、`bugsmirror`、`alibaba_sec`、`vguard`、`appdefence`、`ahope_appshield`、`dpt_shell`、`ahnlab_v3_engine`、`appiron`）——APK 层看 so 库路径，DEX 层看注入类名。两者互补。

## 📍 相关

- [protector 类别](./category-protector) — protector 概念与全文件类型分布
- [anti-root 类别](./category-anti-root) — `ahnlab_v3_engine`/`flutterjailbreakdetection`/`rootbeer` 的 tag 归属
- [APK 保护器规则](./apk-protectors) — 同方案的 APK 层检测（20 条）
- [DEX 规则总览](./dex-overview) — DEX 层规则全貌
- [DEX 反虚拟机](./dex-anti-vm) — 另一类环境检测
