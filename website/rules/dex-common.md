# DEX common 规则

<span class="badge badge-file">file_type</span>
<span class="badge badge-info">internal</span>
<span class="badge badge-misc">yara_issue</span>
<span class="badge badge-file">3 条</span>

`apkid/rules/dex/common.yara` — 3 条规则（1 公开 file_type + 1 private internal + 1 公开 yara_issue）。这是 DEX 规则的 **前置条件层与诊断信号层**：定义 `is_dex` 判定，以及当 `dex` 模块解析失败时的诊断输出。

## 🎯 is_dex 是所有 DEX 规则的门

`compilers.yara`、`packers.yara`、`protectors.yara` 等文件里每条规则都带 `is_dex and ...`。先确认"这是个 DEX"，再匹配字节码特征——避免在普通文件上误报。

## 📋 规则清单

| 规则 | tag | 可见性 | 说明 |
|------|-----|--------|------|
| `is_dex` | file_type | 公开 | DEX — 魔数 `dex\n035` 或 `dey\n035`（odex）在文件开头 |
| `yara_detected_dex` | internal | private | magic bytes look like a dex but yara disagrees — `is_dex` 且 `dex.header.header_size > 0`（dex 模块能解析） |
| `yara_undetected_dex` | yara_issue | 公开 | yara issue — dex file recognized by apkid but not yara module — `is_dex` 但 `dex` 模块解析不了 |

## 🔍 规则源码

### `is_dex` — 魔数判定

```yara
import "dex"

rule is_dex : file_type {
  meta:
    description = "DEX"
  strings:
    $dex = { 64 65 78 0A 30 33 ?? 00 }
    $odex = { 64 65 79 0A 30 33 ?? 00 }
  condition:
    $dex at 0 or $odex at 0
}
```

魔数解析：
- `{ 64 65 78 0A 30 33 ?? 00 }` = ASCII `dex\n03?\0` — 标准 DEX（`?` 是版本号，如 `5` 表示 `035`）。
- `{ 64 65 79 0A 30 33 ?? 00 }` = ASCII `dey\n03?\0` — ODEX（优化后的 dex）。

`at 0` 要求魔数在文件开头。`import "dex"` 引入 yara-python-dex 模块，供后续规则用 `dex.header.*` 等字段。

### `yara_detected_dex` 与 `yara_undetected_dex` — 诊断信号

```yara
private rule yara_detected_dex : internal {
  meta:
    description = "magic bytes look like a dex but yara disagrees"
  condition:
    is_dex
    and dex.header.header_size > 0
}

rule yara_undetected_dex : yara_issue {
  meta:
    description = "yara issue - dex file recognized by apkid but not yara module"
  condition:
    is_dex
    and not yara_detected_dex
}
```

逻辑：
- `is_dex` 命中（魔数认出是 dex）→ 检查 `dex` 模块能否解析（`header_size > 0`）。
- 能解析 → `yara_detected_dex`（internal，不输出）。
- **不能解析** → `yara_undetected_dex`（yara_issue，输出）。

`yara_undetected_dex` 是 **诊断信号**——APKiD 通过魔数知道这是 dex，但 `dex` 模块解析不了（可能文件损坏、或 dex 模块版本不兼容、或遇到了非标准 dex 变体）。命中它说明：
1. 文件可能是损坏的 dex，或
2. yara-python-dex 模块需要更新，或
3. 遇到了新的 dex 变体（如某些加固的私有格式）。

所有依赖 `dex.header.*`/`dex.map_list.*` 字段的规则（编译器、异常结构等）在 `yara_undetected_dex` 命中时 **全部失效**——因为模块读不出字段。但依赖 `is_dex` + 字符串匹配的规则（如 packers 的 stub 类名）仍能工作。

## 📊 输出行为

- `is_dex` 是 `file_type` tag，**默认不输出**（信息量低），需 `--include-types` 显示。
- `yara_detected_dex` 是 `internal`，永远不输出。
- `yara_undetected_dex` 是 `yara_issue` tag，**会输出**——这是个需要用户注意的诊断信号。详见 [misc 类别](./category-misc)。

## 🧠 为什么 yara_issue 要单独输出

正常情况下，APKiD 扫一个 dex 应该能命中编译器、加固等规则。如果只命中 `yara_undetected_dex` 而没有其它 DEX 规则——说明 `dex` 模块挂了，扫描结果不完整。这个 finding 提醒用户："这个文件的 dex 模块解析失败，结果可能不准，建议检查 yara-python-dex 版本或提 issue。"

## 📍 相关

- [file_type 类别](./category-file-type) — 为什么 file_type 默认不输出
- [misc 类别](./category-misc) — `yara_issue` tag 的归属
- [DEX 规则总览](./dex-overview) — DEX 层规则全貌
- [YARA 规则系统（指南）](../guide/yara-system) — yara-python-dex 依赖与安装
- [组织方式](./organization) — common.yara 的角色
- [APK common 规则](./apk-common) — 对照 `is_apk` 的写法
