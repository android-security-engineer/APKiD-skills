# 类别：abnormal 异常结构

<span class="badge badge-neutral">abnormal</span>

`abnormal` 类别检测 **DEX 结构异常**——偏离规范但未必是故意对抗，可能是非常规编译器、损坏或实验性产物。

## 📋 规则分布

`abnormal` tag 的规则在 `dex/abnormal.yara`：

| 规则 | 检测 |
|------|------|
| `abnormal_header_size` | DEX header 的 `header_size` 字段异常 |
| `non_little_endian` | DEX 不是小端序（规范要求小端） |

## 🔍 规则示例

```yara
rule abnormal_header_size : abnormal {
  condition:
    is_dex and dex.header.header_size != 0x70   // 标准 DEX header 是 0x70 字节
}
```

正常 DEX 的 header 固定 0x70（112）字节。非此值说明结构异常——可能是被篡改、自定义格式或损坏。

## 🆚 与 anti_disassembly 的区别

- **abnormal**：结构异常，**原因不明**（bug？损坏？实验？）。
- **anti_disassembly**：结构篡改，**明确是对抗手段**（让工具出错）。

界限有时模糊。`non_zero_link_size` 归 `anti_disassembly`（明确对抗），`abnormal_header_size` 归 `abnormal`（可能只是损坏）。

## 📊 finding 示例

```json
{
  "tag": "abnormal::abnormal_header_size",
  "category": "abnormal",
  "description": "Detects abnormal or suspicious modifications",
  "source": "app.apk!classes.dex",
  "identifier": "abnormal_header_size",
  "confidence": "high"
}
```

## 🎯 命中后怎么办

`abnormal` 是 **可疑信号** 而非定论。命中后建议：

1. 用 `apkid-ai-cli type` 确认文件类型。
2. 用 baksmali/jadx 尝试反编译，看是否真能解析。
3. 对比同编译器的正常样本，判断是损坏还是故意。

## 📍 相关

- [DEX 异常结构规则](./dex-abnormal) — 同文件的全部规则。
- [anti_disassembly 类别](./category-anti-disassembly) — 区别。
- [dropper 类别](./category-dropper) — 同在 abnormal.yara 的 `data_injected_after_map`。
- [检测类别](../guide/categories)
