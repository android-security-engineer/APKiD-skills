# DEX 加固规则

<span class="badge badge-pack">packer</span>
<span class="badge badge-pack">29 条</span>

`apkid/rules/dex/packers.yara` — 29 条规则。DEX 层加固规则匹配 **壳代码注入的 stub 类名、opcode 序列、libc 字符串引用**，从字节码层确认加固方案。比 APK 层路径匹配更可靠——厂商改名 so 库路径没用，壳注入的 stub 类名和 opcode 序列难改。

## 🎯 检测原理

加固方案运行时解密真实 dex 前，壳代码自己就是个 dex——里面有 stub Application 类（如 `Lcom/stub/StubApp;`）、解密用的 opcode 序列、libc 字符串引用。APKiD 扫描 APK 时会递归进 `classes.dex`，这些字节码特征都会被命中。

## 📋 规则清单

### 🛡️ 通用加固壳

| 规则 | tag | 说明 |
|------|-----|------|
| `pangxie_dex` | packer | PangXie — `Lcom/merry/wapper/WapperApplication;` 类名 |
| `medusah_dex` | packer | Medusah — `Lcom/seworks/medusah` 类名 |
| `medusah_appsolid_dex` | packer | Medusah (AppSolid) — `Lweb/apache/sax/app;` + `MainActivity` |
| `apkguard_dex` | packer | APKGuard — 完整 `attachBaseContext` opcode 序列（Base64 解 zip + DexClassLoader） |
| `cryptoshell_dex` | packer | CryptoShell — 类似 apkguard 的 opcode 序列（排除 apkguard_dex） |
| `jar_pack01` | packer | jar_pack01 — `.onCreate`/`.jar`/`/data/data` 字节串组合 |
| `gaoxor` | packer | GaoXor — `attachBaseContext` opcode + XOR 解密密钥序列 + `writedDexFile` |
| `appsealing_loader_1_2_2` | packer | AppSealing Loader v1.2.2 — `AppSealingLoader...v1.2.2` 正则 + 类名 |
| `tencent` | packer | Mobile Tencent Protect — `libshella/b/c.so` + `Lcom/tencent/StubShell/TxAppEntry;` |
| `crazy_dog_wrapper` | packer | Crazy Dog Wrapper — `libhdog.so` + `Lcom/vdog/VDogApplication;` |
| `jsonpacker` | packer | JsonPacker — 3 种 XOR 解密 algo + DexClassLoader newInstance opcode |
| `multidexpacker` | packer | MultidexPacker — multidex 反混淆 opcode + dex 解密写入 opcode |
| `appguard_dex` | packer | AppGuard — `Lcom/inca/security/IIIiiiiIii;` 混淆类名 + `JNISoxProxy` |
| `custom_multidex` | packer | Custom Multidex — AES Cipher 加密 opcode + Unicode 类名 |
| `custom_flutter` | packer | Custom Flutter — `attachBaseContext` + AES/ECB/PKCS5Padding 加密 opcode |
| `jiagu_k` | packer | Jiagu K — `Lvirbox/StubApp;` + `data_size+data_offset < file_size`（尾部藏数据） |

### 🛡️ 国内主流加固（DEX 层 stub 类名）

| 规则 | tag | 说明 |
|------|-----|------|
| `jiagu_360_dex` | packer | Qihoo 360 Jiagu (DEX-level) — `Lcom/stub/StubApp;` / `Lcom/qihoo/util/StubApp;` |
| `tencent_legu_dex` | packer | Tencent Legu (DEX-level) — `Lcom/tencent/StubShell/TxAppEntry;` / `Lcom/tencent/legu/StubApp;` |
| `bangcle_dex` | packer | Bangcle (DEX-level) — `Lcom/bangcle/ShellApplication;` / `Lcom/secneo/apkwrapper/...` |
| `ijiami_dex` | packer | Ijiami (DEX-level) — `Lcom/ijiami/ShellApp;` / `Lcom/ijiami/ijiamiSec;` |
| `alibaba_jiagu_dex` | packer | Alibaba Jiagu (DEX-level) — `Lcom/ali/mobisecenhance/StubApplication;` / WindVM |
| `tencent_mtp_dex` | packer | Mobile Tencent Protect (DEX-level) — `libshella.so` + `/mix.dex` + `StubShell/a` |
| `baidu_jiagu_dex` | packer | Baidu Jiagu (DEX-level) — `Lcom/baidu/protect/ProtectApplication;` / `Boot` |
| `secneo_dex` | packer | SecNeo (DEX-level) — `Lcom/secneo/core/Entry;` / `Hook` / `DataProvider` |

### 🛡️ 其它厂商（DEX 层）

| 规则 | tag | 说明 |
|------|-----|------|
| `nesun_dex` | packer | Nesun — `zVersion`/`zprotect` 字符串 + `Lcom/nesun/stub/ZAP;` |
| `gpresto_dex` | packer | G-Presto (anti-cheat) — `Lcom/bishopsoft/Presto/SDK/Presto;` + 代码段 |
| `dingxiang_dex` | packer | DingXiang — `StringEncryptUtils` 类 + `stub000`/`dsn0` 字符串 + hash 类 |
| `kiwisec_dex` | packer | KiwiSec — `Lcom/kiwisec/crash/CrashUtils;` / `StubApplication` |
| `manxi_sec` | packer | Manxi Security — `Lcom/manxi/shell/Helper;` / `MXApplication` |

## 🔍 规则源码示例

### `jiagu_360_dex` — stub 类名字节序列

```yara
rule jiagu_360_dex : packer {
  strings:
    // Lcom/stub/StubApp; — classic 360 jiagu stub Application class
    $stub_app = {
      00 12 4C 63 6F 6D 2F 73 74 75 62 2F 53 74 75 62
      41 70 70 3B 00
    }
    // Lcom/qihoo/util/StubApp; — alternate 360 stub path
    $qihoo_stub = { ... }
    // Lcom/stub/StubXXXXApp; — newer versions with random suffix
    $stub_random = { 00 1E 4C 63 6F 6D 2F 73 74 75 62 2F 53 74 75 62 [8-16] 41 70 70 3B 00 }
    // com.stub — package string
    $pkg_stub = { 00 08 63 6F 6D 2E 73 74 75 62 00 }
  condition:
    is_dex and any of them
}
```

字节序列 `00 12 4C 63 6F 6D 2F 73 74 75 62 2F 53 74 75 62 41 70 70 3B 00` 解码后就是 `Lcom/stub/StubApp;`——360 加固的经典 stub Application 类名。`00 12` 是 DEX 字符串长度前缀（0x12 = 18 字符）。`[8-16]` 通配 newer 版本的随机后缀。

### `apkguard_dex` — opcode 序列指纹

`apkguard_dex` 匹配整个 `attachBaseContext` 方法的 opcode 序列：Base64 解码 → 写 zip 文件 → `DexClassLoader` 加载 → 反射调用 `attachBaseContext`。这种 opcode 级指纹极难伪造——改了逻辑就跑不起来。详见源码 `apkid/rules/dex/packers.yara`。

### `jiagu_k` — 尾部藏数据检测

```yara
rule jiagu_k : packer {
  strings:
    $classNameString = { 00 10 4C 76 69 72 62 6F 78 2F 53 74 75 62 41 70 70 3B 00 } // Lvirbox/StubApp;
  condition:
    is_dex and all of them and (dex.header.data_size + dex.header.data_offset) < dex.header.file_size
}
```

`(data_size + data_offset) < file_size`——DEX 的 data 段之后还有数据，说明壳在 dex 尾部藏了加密的真实 dex。这是结构异常检测，与 [DEX 异常结构](./dex-abnormal) 的 `data_injected_after_map` 异曲同工。

## 📊 finding 示例

```json
{
  "tag": "packer::jiagu_360_dex",
  "category": "packer",
  "source": "app.apk!classes.dex",
  "identifier": "jiagu_360_dex",
  "confidence": "high"
}
```

DEX 字节码级匹配 → 置信度 `high`。若同时 APK 层命中 `jiagu_360_v5`（`source` 带 `!assets/libjiagu.so`），同一方案两个角度都确认。

## 🧠 APK 层 vs DEX 层对照

同一加固方案常在两层都有规则，互补确认：

| 方案 | APK 层规则 | DEX 层规则 |
|------|-----------|-----------|
| 360 加固 | `jiagu_360_v4`/`v5`/`v6` | `jiagu_360_dex` |
| 腾讯乐固 | `tencent_legu`/`_2024` | `tencent_legu_dex` |
| 梆梆 | `bangcle`/`_secshell` | `bangcle_dex` |
| 爱加密 | `ijiami`/`_pro` | `ijiami_dex` |
| 阿里 | `alibaba`/`_jiagu_v2` | `alibaba_jiagu_dex` |
| SecNeo | `secneo_a`/`b`/`c` | `secneo_dex` |

APK 层看 so 库路径（low 置信度），DEX 层看 stub 类名（high 置信度）。

## 📍 相关

- [packer 类别](./category-packer) — 加固概念与全文件类型分布
- [APK 加固规则](./apk-packers) — 同方案的 APK 层路径检测（75 条）
- [DEX 规则总览](./dex-overview) — DEX 层规则全貌
- [DEX 异常结构](./dex-abnormal) — `data_injected_after_map` 等结构异常
- [规则文件组织](./organization) — 跨文件类型的同名方案
