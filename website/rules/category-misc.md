# 其它检测类别

<span class="badge badge-neutral">misc</span>

本文收录规模较小或较特殊的类别：`anti_hook`、`anticheat`、`signer`、`embedded`、`hook`、`root`、`internal`、`yara_issue`。

## anti_hook 反 Hook

检测反 Hook 技术——应用检测自己是否被 Frida、Xposed、Substrate 动态插桩。

::: tip 与 hook 的区别
- **anti_hook**：应用 **检测** Hook（防御）。
- **hook**：应用 **是** Hook 框架或带 Hook 功能（如 Xposed 模块）。
:::

目前 APKiD 的 `anti_hook` 规则较少，多数 Hook 检测被归到 [protector](./category-protector) 或 [anti_root](./category-anti-root) 类别下（综合保护 SDK 内含反 Hook）。

## anticheat 反作弊

检测游戏反作弊 SDK。tag `anticheat`，与 `packer`/`protector` 并列。游戏类应用常用专门的反作弊方案（如 Denuvo、腾讯 ACE 等）。`denuvo_apk`/`denuvo_elf` 规则虽归 `protector`，但 `anticheat` 类别预留给纯反作弊 SDK。

## signer 签名

检测 APK 签名证书与签名者。APK 用 V1/V2/V3 签名，签名证书有特征（debug 证书、特定 release 证书）。`signer::dev` 表示调试签名（开发构件），`signer::release` 表示发布签名。

::: warning 规则现状
APKiD 主力在加固/混淆/编译器，签名检测规则相对少。深度的签名分析建议用 [apksigner](https://developer.android.com/tools/apksigner)。
:::

## embedded 内嵌载荷

检测内嵌的额外载荷——样本里塞了第二份可执行代码/数据，运行时提取。`upx_compressed_apk : packer embedded` 是典型（UPX 把 APK 压进 ELF）。与 [dropper](./category-dropper) 的区别：embedded 是静态存在，dropper 强调主动释放。

## hook Hook 框架

检测 Hook 框架本身——Xposed、Frida、Substrate 的特征。当 APK 里检测到 `de.robv.android.xposed` 相关类或 `frida-agent` 符号时触发。常用于判断样本是不是个 Xposed 模块或含 Frida gadget。

## root Root 相关

检测 Root 库或 Root 工具——与 [anti_root](./category-anti-root) 方向相反。`root::magisk`、`root::supersu` 表示样本带 Magisk/SuperSU 相关功能（如 Root 管理应用、Magisk 模块）。

## internal 内部构件

::: tip 不直接输出
带 `internal` tag 的是 **private 规则**——不进结果输出，只被其它规则引用。用户扫描时 **看不到** internal finding。
:::

`internal` 是"积木"的标记：`dx_map_type_order`、`r8_marker`、`uses_build_class` 等结构指纹都是 internal，被 `dx`/`r8`/`checks_build_*` 等最终规则组合使用。详见 [YARA 规则系统](../guide/yara-system#private-规则可复用的积木)。

## yara_issue

`yara_undetected_dex : yara_issue`——**诊断信号**，非恶意特征。当 APKiD 用魔数判定文件是 dex，但 YARA 的 dex 模块（`import "dex"`）解析失败时触发：

```yara
private rule yara_detected_dex : internal {
  condition:
    dex.header.magic == ...   // dex 模块能解析
}

rule yara_undetected_dex : yara_issue {
  condition:
    is_dex and not yara_detected_dex   // 魔数说是 dex，但 dex 模块解析不了
}
```

命中它通常意味着：
- dex 结构被故意篡改（让 dex 模块报错）。
- YARA dex 模块版本过旧。
- 非标准或损坏的 dex。

是个 **环境/工具问题提示**，需要人工复核。

## 📍 相关

- [检测类别](../guide/categories) — 全类别速查。
- [RULE_DESCRIPTIONS](../modules/ai-output) — 类别描述源。
- [list-tags 命令](../interfaces/ai-cli-list-tags) — 列出全部类别。
