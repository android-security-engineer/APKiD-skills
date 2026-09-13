# APK 加固规则

<span class="badge badge-pack">packer</span>
<span class="badge badge-pack">75 条</span>

`apkid/rules/apk/packers.yara` — 75 条规则，按厂商分组。这些规则匹配 APK 内 `lib/*/` 原生库文件名和 `assets/` 资产文件名，识别各路加固方案。这是 APKiD 检测量最大的单文件。

## 🎯 检测原理

加固方案的壳代码以 so 库形式存在，运行时由 `System.loadLibrary` 加载并解密真实 dex。这些 so 库和配套资产有固定命名约定，扫一遍 ZIP 条目名即可判定。所有规则形如 `is_apk and <lib/asset 字符串>`。

## 📋 规则清单（按厂商分组）

### 🛡️ 360 加固（Qihoo 360）

| 规则 | tag | 说明 |
|------|-----|------|
| `jiagu_360_v4` | packer | Qihoo 360 Jiagu v4 — `libjiagu(_art)?\.so` |
| `jiagu_360_v5` | packer | Qihoo 360 Jiagu v5 — `libjiagu(_so)?_64\.so`（arm64） |
| `jiagu_360_v6` | packer | Qihoo 360 Jiagu v6 (enhanced) — `libjiagu_v6.so` + `.dat` 资产 |
| `jiagu` | packer | Jiagu — `libjiagu.so` / `libjiagu_art.so`（含 `youAreFooled` 戏弄函数） |
| `jiagu_a` | packer | Jiagu (ApkToolPlus) — `assets/jiagu_data.bin` + `libapktoolplus_jiagu.so` |
| `qihoo360` | packer | Qihoo 360 — `libprotectClass.so`（排除 kiro） |

### 🛡️ 腾讯（Tencent）

| 规则 | tag | 说明 |
|------|-----|------|
| `tencent` | packer | Mobile Tencent Protect — `libshell.so` / `libmobisecy.so` / `/mix.dex` |
| `tencent_a` | packer | Mobile Tencent Protect — `libshell(a|x)-\d\.\d\.\d\.\d.so` 版本化路径 |
| `tencent_b` | packer | Tencent Security Enterprise Edition — `libshell-superv.*.\d{4}.so` + `dexMethod*.dat` |
| `tencent_legu` | packer | Tencent's Legu — `assets/0OO00l111l1l` + `tosversion` 等混淆名资产 |
| `tencent_legu_VMP` | packer | Tencent's Legu (VMP) — `libwsDataEncryption_AZAPP*.so` + `WSSEC[A-D].jar` |
| `tencent_legu_2024` | packer | Tencent Legu (2024+ version) — `tpatch_*.dat` 资产 |

### 🛡️ 梆梆（Bangcle）

| 规则 | tag | 说明 |
|------|-----|------|
| `bangcle` | packer | Bangcle — `libsecexe.so` / `libsecmain.so` / `container.dex` |
| `bangcle_secshell` | packer | Bangcle (SecShell) — `assets/secData0.jar` + `libSecShell.so` |
| `bangcle_secshell_vmp` | packer | Bangcle SecShell (VMP edition) — `libSecShellEx.so` |
| `bangcle_standard` | packer | Bangcle (standard edition) — 标准版 `libsecexe.so` |

### 🛡️ 爱加密（Ijiami）

| 规则 | tag | 说明 |
|------|-----|------|
| `ijiami` | packer | Ijiami — `assets/ijiami.dat` / `ijiami3.ajm` / `IJMDal.Data` |
| `ijiami_pro` | packer | Ijiami Pro (enterprise edition) — `libijmDataEncryption.so` + `IJMDal.Data` |

### 🛡️ 百度 / 阿里

| 规则 | tag | 说明 |
|------|-----|------|
| `baidu` | packer | Baidu — `libbaiduprotect.so` / `baiduprotect1.jar` |
| `alibaba` | packer | Alibaba — `libmobisec.so` |
| `alibaba_jiagu_v2` | packer | Alibaba Jiagu v2 (mobisecenhance) — `libmobisecy.so` 动态加载 |

### 🛡️ AppGuard（NHN/NProtect）

| 规则 | tag | 说明 |
|------|-----|------|
| `appguard` | packer | AppGuard — `assets/appguard/` + `assets/classes.sox` |
| `appguard_a` | packer | AppGuard — `AppGuard0.jar` / `libAppGuard.so` |
| `appguard_b` | packer | AppGuard — `assets/appguard/`（排除主规则） |
| `appguard_c` | packer | AppGuard (TOAST-NHNent) — `classes.jet` / `libloader.so` / `agconfig` |
| `appguard_d` | packer | AppGuard — `libcompatible.so` |

### 🛡️ DexProtector

| 规则 | tag | 说明 |
|------|-----|------|
| `dexprotector` | packer | DexProtector v6.x.x — `dp.*.so.dat` + `classes.dex.dat` |
| `dexprotector_a` | packer | DexProtector（旧版）— `dp.arm-v7.art.kk.so` 等 ART/DVM 变体 |
| `dexprotector_b` | packer | DexProtector（新版）— `<pkg>.<arch>.so.dat` 正则 |
| `dexprotector_c` | packer | DexProtector — `dp.<arch>.so.<rand>.mp3` |
| `dexprotector_d` | packer | DexProtector — `<rand>.mp3` + `libdexprotector.so` / `libalice.so` |
| `dexpro_aide_a` | packer | DexProtector for AIDE — `dp-lib/dp.kotlin-v1.lua.mph` |
| `dexpro_aide_b` | packer | DexProtector for AIDE — `dexpro-build.properties` |

### 🛡️ 其它加固

| 规则 | tag | 说明 |
|------|-----|------|
| `dxshield` | packer | DxShield — `libdxbase.so` / `assets/DXINFO.XML` |
| `secneo_a` | packer | SecNeo.A — `libDexHelper.so` / `assets/classes0.jar`（兜底） |
| `secneo_b` | packer | SecNeo.B — `libdexjni.so` |
| `secneo_c` | packer | SecNeo.C — `libdatajar.so` |
| `apkprotect` | packer | APKProtect — `apkprotect.com/key.dat` / `libAPKProtect.so` |
| `apkprotect_a` | packer | APKProtect 6.x — `libapkprotect.so` + `apkprotect-build.properties` |
| `apkprotect_b` | packer | APKProtect 9.x — `assets/ap.res/` 资源目录 |
| `kiro` | packer | Kiro — `libkiroro.so` + `assets/sbox` |
| `qdbh_packer` | packer | qdbh packer — `assets/qdbh` |
| `unicom_loader` | packer | Unicom SDK Loader — `libdecrypt.jar` + `libunicomsdk.jar` |
| `liapp` | packer | LIAPP — `/LIAPPEgg` / `LIAPPClient.sc` / `assets/LIAPP.ini` |
| `app_fortify` | packer | App Fortify — `libNSaferOnly.so` |
| `nqshield` | packer | NQ Shield — `libnqshield.so` / `nqshell` |
| `naga` | packer | Naga — `lib(e|d|f|v)dog.so` / `libchaosvmp.so` / `libxloader.so` |
| `medusah` | packer | Medusah — `libmd.so` |
| `medusah_appsolid` | packer | Medusah (AppSolid) — `assets/high_resolution.png`（伪装图片） |
| `pangxie` | packer | PangXie — `libnsecure.so` |
| `kony` | packer | Kony — `libkonyjsvm.so` + `assets/js/startup.js` |
| `approov` | packer | Approov — `libapproov.so` + `assets/cbconfig.JSON` |
| `yidun` | packer | yidun — `libnesec.so` + `Lcom/netease/nis/wrapper/Entry` |
| `apkpacker` | packer | ApkPacker — `assets/ApkPacker/apkPackerConfiguration` |
| `chornclickers` | packer | ChornClickers — `libhdus.so` + `libwjus.so` |
| `appsuit_packer` | packer | AppSuit — `assets/appsuit/momo` + `libAppSuit.so` |
| `appsealing` | packer | AppSealing — `libcovault.so` + `assets/appsealing.dex` |
| `appsealing_a` | packer | AppSealing — `assets/AppSealing/*`（>3 个条目） |
| `secenh` | packer | Secenh — `assets/libsecenh.so` + `respatcher.jar` |
| `apkencryptor` | packer | ApkEncryptor — `src/<hash>` 目录 |
| `epicvm` | packer | Epic VM — `libEpic_Vm.so` |
| `appiron` | packer | Secucen AppIron — `libAppIron-jni_v*.so` + `assets/appiron/` |
| `eversafe` | packer | Eversafe — `libeversafe.so` + `assets/eversafe/eversafe_*.data` |
| `appcamo` | packer | AppCamo — `libalib.so` + `assets/<md5>/<md5>.png` |
| `aegis` | packer | Aegis - Android Republic Mods — `assets/aegis/aegis.mf` 等 |
| `kangapack` | packer | KangaPack — `libapksadfsalkwes.so`（原生解密壳） |
| `tongfu_shield` | packer | Tongfu shield — `libegis.so` + `assets/mode`/`virtual` |
| `zimperium_zshield_apk` | packer | Zimperium (zShield) — `lib<name>.so` + `assets/*/*.szip`/`0.odex` |
| `nesun_apk` | packer | Nesun — `libzprotect.so` |
| `gpresto_apk` | packer | G-Presto (anti-cheat) — `libATG_L.so` + `assets/ATG_E*.sec` |
| `kiwisec_apk` | packer | KiwiSec — `libkiwicrash.so` / `libkadp.so` 等 |
| `dingxiang_apk` | packer | DingXiang — `libsys_misc.so` + `assets/__param.data` |
| `manxi_sec` | packer | Manxi Security — `libmanxi.so` / `assets/mxsafe.*` |
| `dexprotectx` | packer | DexProtect X (DexShellx) — `libVMDexShellx.so` / `assets/DexShell.mp3` |
| `venustech` | packer | Venustech — `libven(Sec|ustech).so` |

> 私有规则 `secneo_base`（internal）是 SecNeo 三条规则的共用积木，匹配 `libDexHelper.so` / `assets/classes0.jar`，不单独输出。

## 🔍 规则源码示例

### `jiagu_360_v5` — 经典的版本化 so 路径

```yara
rule jiagu_360_v5 : packer {
  meta:
    description = "Qihoo 360 Jiagu v5"
    url         = "http://jiagu.360.cn/"
    author      = "APKiD-skills"

  strings:
    // v5 uses libjiagu_64.so and libjiagu_so_64.so for arm64
    $lib64 = /lib\/(arm64.*)\/libjiagu(_so)?_64\.so/
    $lib32 = /lib\/(armeabi.*)\/libjiagu(_so)?\.so/

  condition:
    is_apk and $lib64 and ($lib32 or $lib64) and not jiagu_a
}
```

要点：`not jiagu_a` 排除 ApkToolPlus 变体；同时要求 arm64 库存在，避免误报。

### `tencent_legu` — 混淆文件名资产

```yara
rule tencent_legu : packer {
  strings:
    $a = "assets/tosversion"
    $b = "assets/0OO00l111l1l"      // O/0/l 混淆命名
    $c = "assets/0OO00oo01l1l"
    $d = "assets/o0oooOO0ooOo.dat"
  condition:
    is_apk and $b and ($a or $c or $d)
    and not tencent and not tencent_a and not tencent_b
}
```

乐固用 `0OO00l111l1l` 这种 O/0/l 难辨的文件名做资产——人眼难读，但作为字符串特征反而独一无二。

## 📊 finding 示例

```json
{
  "tag": "packer::jiagu_360_v5",
  "category": "packer",
  "source": "app.apk!assets/libjiagu.so",
  "identifier": "jiagu_360_v5",
  "confidence": "low"
}
```

APK 层路径匹配 → 置信度 `low`。若同时在 `classes.dex` 命中 [`jiagu_360_dex`](./dex-packers)，置信度升 `high`。

## 🧠 版本变体规则

`jiagu_360_v4`/`v5`/`v6`、`tencent_legu_2024`、`bangcle_secshell_vmp`/`bangcle_standard`、`ijiami_pro`、`alibaba_jiagu_v2` 这些是 APKiD-skills 扩展的版本区分规则，在原通用规则（`jiagu`/`tencent_legu`/`bangcle`/`ijiami`/`alibaba`）基础上，用更细的 lib 命名约定区分版本/edition。它们都带 `and not <原规则>` 避免双命中。

## 📍 相关

- [packer 类别](./category-packer) — 加固概念与全文件类型分布
- [DEX 加固规则](./dex-packers) — 同方案的 dex 层特征（29 条）
- [APK 规则总览](./apk-overview) — APK 层规则全貌
- [ELF 加固](./elf-packers) — so 库符号层（44 条）
- [规则文件组织](./organization) — 命名约定
