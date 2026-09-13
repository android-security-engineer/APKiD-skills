# 类别：anti_root 反 Root

<span class="badge badge-anti">anti_root</span>

`anti_root` 类别检测 **反 Root 技术与 Root 检测库**——样本用来判断运行设备是否已 Root，若是则拒绝运行或降级功能（常见于银行、DRM、游戏应用）。

## 🎯 常见 Root 检测手段

- **检查 su 二进制**：`/system/bin/su`、`/system/xbin/su` 等。
- **检查 Magisk**：MagiskHide/Zygisk 痕迹、`magisk.db`。
- **检查 Root 管理应用**：SuperSU、Magisk Manager 包名。
- **检查 BusyBox**、挂载点、SELinux 状态。
- **SafetyNet/Play Integrity**：Google 的硬件证明。

## 📋 规则分布

`anti_root` tag 的规则跨 DEX 和 ELF：

| 规则 | 文件 | 说明 |
|------|------|------|
| `rootbeer` | dex/protectors.yara、elf/protectors.yara | [RootBeer](https://github.com/scottyab/rootbeer) 开源库 |
| `ahnlab_v3_engine` | dex/protectors.yara、elf/protectors.yara | AhnLab（含反 Root） |
| `flutterjailbreakdetection` | dex/protectors.yara | Flutter 越狱/Root 检测插件 |

注意这些规则物理上放在 `protectors.yara` 文件里，但 tag 是 `anti_root`——因为它们是专门做 Root 检测的库，归到 `anti_root` 更精确。`_categorize_tag()` 按 tag 子串匹配，所以 tag 是 `anti_root` 就归 `anti_root` 类别。

## 🔗 与 protector 的关系

`anti_root` 可看作 [protector](./category-protector) 的子集——很多 protector SDK 内含 Root 检测。APKiD 把"专做 Root 检测的库"标 `anti_root`，把"综合保护 SDK"标 `protector`。

## 📊 finding 示例

```json
{
  "tag": "anti_root::rootbeer",
  "category": "anti_root",
  "description": "Detects anti-root techniques",
  "source": "app.apk!lib/arm64-v8a/librootbeer.so",
  "identifier": "rootbeer",
  "confidence": "medium"
}
```

## 🆚 root vs anti_root

- **anti_root**：应用 **检测** Root（防御方）。
- **root**：应用 **是** Root 相关工具或带 Root 功能（如 Magisk 模块）。

两者方向相反。详见 [root 类别](./category-misc#root)。

## 📍 相关

- [protector 类别](./category-protector) — 父集。
- [DEX 保护器](./dex-protectors) · [ELF 保护器](./elf-protectors) — 物理位置。
- [anti_vm](./category-anti-vm) · [anti_debug](./category-anti-debug) — 同属反分析。
- [检测类别](../guide/categories)
