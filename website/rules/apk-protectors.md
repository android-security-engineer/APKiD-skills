# APK 保护器规则

<span class="badge badge-protect">protector</span>
<span class="badge badge-manip">manipulator</span>
<span class="badge badge-protect">20 条</span>

`apkid/rules/apk/protectors.yara` — 20 条规则。`protector` 类别检测 **RASP（运行时应用自保护）SDK**——不重打包 dex，而是注入 SDK 做反调试、反 Hook、环境检测、设备指纹等运行时保护。另有 1 条 `manipulator` 规则（资源混淆）。

## 🎯 protector vs packer

- **packer**：把 dex 加密打包，运行时解密还原，**结构变了**。
- **protector**：不重打包，注入 SDK 在运行时做保护，**结构没变**。

保护器 SDK 也会留 so 库和资产文件足迹，所以 APK 层能识别。详见 [protector 类别](./category-protector)。

## 📋 规则清单

### 🔐 商业保护 SDK

| 规则 | tag | 说明 |
|------|-----|------|
| `verimatrix` | protector | InsideSecure Verimatrix — `libmfjava.so` |
| `virbox_apk` | protector | Virbox — `libsandhook.so` + `libv++.so` |
| `vkey_apk` | protector | Vkey (V-OS App Protection) — `libvosWrapperEx.so` + `assets/kernel.bin` |
| `free_rasp_old` | protector | FreeRASP（旧版）— `libsecurity.so` + `libpolarssl.so` |
| `free_rasp_new` | protector | FreeRASP（新版）— 旧版特征 + `assets/talsec` |
| `ahnlab_v3_engine` | protector | Ahnlab V3 engine — `libEngineManager.so` + `assets/ahnlab/engine/` |
| `ahope_appshield` | protector | Ahope AppShield — `libahope*.so` |
| `vguard` | protector | VGuard — `libedex.so` + `assets/dexsky.*` |
| `appdefence` | protector | ExTrus AppDefence — `assets/appdefence_xml` |
| `dpt_shell` | protector | DPT Shell — `libdpt.so` + `assets/app_name` |
| `build38` | protector | Build38 — `libtak.so` + `license.tak` |
| `shield_sdk` | protector | Shield SDK — `libcashshieldabc-native-lib.so` |
| `bugsmirror` | protector | BugsMirror — `libdefender.so` + `bugsmirror_authenticator.xml` |
| `bshield` | protector | BShield — `assets/bshield.dat` |
| `denuvo_apk` | protector | Denuvo — `assets/tid` + `libvmpc.so` |
| `alibaba_sec` | protector | Alibaba Security SDK — `lib(alisecuritysdk|demolish|reverify1).so` |
| `bureau` | protector | Bureau — `libbureau-*.so` |
| `haiyun` | protector | Haiyun'an Security — `libitsec.so` + `assets/itse` |
| `oppo_protect` | protector | OPPO Protect SDK — `libOPPOProtect(2019)?.so` |

### 🎨 资源混淆（manipulator）

| 规则 | tag | 说明 |
|------|-----|------|
| `andres` | manipulator | Resources Confusion — `res/*.xml` 条目数 > 10（AndResGuard 资源混淆） |

注意 `andres` 的 tag 是 **`manipulator`** 不是 `protector`——它做的是资源路径混淆（缩短/打乱 `res/` 下的文件名以减小体积并干扰分析），不是运行时保护。详见 [manipulator 类别](./category-manipulator)。

## 🔍 规则源码示例

### `vkey_apk` — 多 lib + 多资产交叉确认

```yara
rule vkey_apk : protector {
  strings:
    $lib1 = /lib\/(...\)\/libvosWrapperEx\.so/
    $lib2 = /lib\/(...\)\/libvtap\.so/
    $lib3 = /lib\/(...\)\/libloadTA\.so/
    $lib4 = /lib\/(...\)\/libchecks\.so/
    $asseta1 = "assets/firmware"
    $asseta2 = "assets/kernel.bin"
    $asseta3 = "assets/signature"
    $assetb1 = "assets/vkeylicensepack"
    $assetb2 = "assets/vkwbc_ta.bin"
    $assetb3 = "assets/voscodesign.vky"
  condition:
    is_apk and 2 of ($lib*) and 1 of ($asseta*) and 1 of ($assetb*)
}
```

Vkey 要求 **2 个 lib + 1 个 firmware 资产 + 1 个 license 资产**——多维度交叉，误报概率极低。

### `andres` — 计数式匹配

```yara
rule andres : manipulator {
  strings:
    $res = /res\/[^\/]+\.xml/
  condition:
    is_apk and #res > 10
}
```

`#res > 10` 是 YARA 的字符串出现计数——AndResGuard 会把大量 `res/` 下的 xml 重命名成短路径，超过 10 个就判定。这是"行为特征"而非"文件名特征"。

## 📊 finding 示例

```json
{
  "tag": "protector::vkey_apk",
  "category": "protector",
  "source": "app.apk!lib/arm64-v8a/libvosWrapperEx.so",
  "identifier": "vkey_apk",
  "confidence": "low"
}
```

## 🧠 同名 SDK 在 DEX 层也有规则

许多保护 SDK 同时在 [`dex/protectors.yara`](./dex-protectors) 有 dex 层规则（如 `build38`、`shield_sdk`、`bshield`、`bureau`、`bugsmirror`、`alibaba_sec`、`vguard`、`appdefence`、`ahope_appshield`、`dpt_shell`、`ahnlab_v3_engine`）——APK 层看 so 库路径，DEX 层看注入的 stub 类名。两者互补。

## 📍 相关

- [protector 类别](./category-protector) — protector 概念与全文件类型分布
- [DEX 保护器规则](./dex-protectors) — dex 层 stub 类名检测（31 条）
- [manipulator 类别](./category-manipulator) — `andres` 的 tag 归属
- [APK 规则总览](./apk-overview) — APK 层规则全貌
- [anti-root 类别](./category-anti-root) — 部分保护器含反 root 检测
