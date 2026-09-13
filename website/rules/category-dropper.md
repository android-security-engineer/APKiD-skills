# 类别：dropper 释放器

<span class="badge badge-danger">dropper</span>

`dropper` 类别检测 **释放器/加载器行为**——样本在自身结构里塞入额外数据，运行时释放或加载。

## 📋 规则分布

`dropper` tag 的规则：

| 规则 | 文件 | 检测 |
|------|------|------|
| `data_injected_after_map` | dex/abnormal.yara | DEX 的 map_list 之后被注入了数据 |
| `upx_embedded_inside_elf` | elf/packers.yara | ELF 内嵌了 UPX（tag: `packer dropper`） |
| `upx_compressed_apk` | elf/packers.yara | UPX 压缩的 APK（tag: `packer embedded`） |

注意 `upx_embedded_inside_elf` 和 `upx_compressed_apk` 是 **多 tag 规则**——同时带 `packer` 和 `dropper`/`embedded`，会生成多条 finding。

## 🔍 规则示例

```yara
rule data_injected_after_map : dropper {
  condition:
    is_dex and <map_list 之后有非预期数据>
}
```

正常 DEX，`map_list` 之后是 `data` 段，结构是确定的。如果在其后发现了"多余"的数据，说明有人往 dex 里塞了载荷——典型的释放器手法：把真正的恶意代码加密附在 dex 尾部，运行时读取并解密。

## 📊 finding 示例

```json
{
  "tag": "dropper::data_injected_after_map",
  "category": "dropper",
  "description": "Detects dropper/loader behavior patterns",
  "source": "app.apk!classes.dex",
  "identifier": "data_injected_after_map",
  "confidence": "high"
}
```

## 🆚 dropper vs embedded vs packer

- **dropper**：主动 **释放/加载** 额外载荷（有行为意图）。
- **embedded**：内嵌载荷（静态存在，未必主动释放）。
- **packer**：整个 dex 被加密打包（载荷是 dex 本身）。

界限有重叠。UPX 内嵌既是 packer（UPX 打包）又是 dropper（内嵌额外 ELF）。

## 📍 相关

- [DEX 异常结构](./dex-abnormal) — `data_injected_after_map` 所在文件。
- [ELF 加固](./elf-packers) — UPX 规则。
- [embedded / manipulator 类别](./category-misc) — 相关概念。
- [检测类别](../guide/categories)
