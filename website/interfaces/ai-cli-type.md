# AI CLI · type — 识别文件类型

<span class="badge badge-info">AI CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-success">秒出</span>

⚡ `apkid-ai-cli type` 只读文件头 4 字节魔数判断文件类型，**不加载 YARA 规则、不做扫描**，几乎瞬时返回。适合在决定是否跑完整 scan 之前先探一下文件是不是 Android 二进制。

## 🚀 一行用法

```bash
apkid-ai-cli type /path/to/mystery.file
```

## 🖥️ 命令签名

```bash
apkid-ai-cli type <target>
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `target` | `Path`（必填） | — | 待识别的文件，`exists=True` 校验存在 |

::: tip 无任何选项
type 命令只有一个必填位置参数，没有 `--output`、`--format` 等开关。输出恒为 JSON，直接 `typer.echo` 到 stdout。
:::

## ⚡ 为什么秒出：不加载 YARA

type 命令的实现路径与 scan 完全不同：

```python
from apkid.apkid import Scanner, SCANNABLE_FILE_MAGICS

with open(target, "rb") as f:
    detected = Scanner._type_file(f)   # 只读首字节，匹配魔数字典
```

- **不调 `make_scanner()`**：意味着不加载 `rules.yarc`、不初始化 YARA 引擎。省掉了规则编译/加载（几十毫秒到几百毫秒）的开销。
- **`Scanner._type_file`**：只读文件开头几字节，与 `SCANNABLE_FILE_MAGICS` 字典比对。
- 因此返回几乎是即时的，对大批量文件做"先探类型"非常划算。

## 📚 可识别的类型

`SCANNABLE_FILE_MAGICS` 定义了 APKiD 能识别的魔数：

| type | 魔数 | 文件类型 |
|------|------|----------|
| `zip` | `PK\x03\x04` 等 | ZIP 容器（APK/AAR/JAR/WAR 本质都是 zip） |
| `dex` | `dex\n` / `dey\n` | Dalvik 字节码 |
| `elf` | `\x7fELF` | ELF 可执行（native .so 等） |
| `res` | `\x02\x00\x0c\x00` | Android 二进制资源（resources.arsc） |
| `dll` | `MZ\x90\x00` | Windows PE（DLL/EXE） |

APK 本质是 zip，所以 APK 的 `type` 会是 `zip`。

## 📤 输出示例

### 识别成功

```bash
apkid-ai-cli type app.apk
```

```json
{
  "error": false,
  "file": "app.apk",
  "type": "zip",
  "supported_types": [
    "dex",
    "dll",
    "elf",
    "res",
    "zip"
  ]
}
```

字段说明：

| 字段 | 含义 |
|------|------|
| `error` | 恒为 `false`（识别不出也不算出错，见下） |
| `file` | 输入文件路径 |
| `type` | 识别出的类型字符串，取 `SCANNABLE_FILE_MAGICS` 的 key 之一 |
| `supported_types` | APKiD 当前支持的全部类型，按字典序排列，方便 AI 自我感知能力边界 |

### 识别不出

```bash
apkid-ai-cli type random.txt
```

```json
{
  "error": false,
  "file": "random.txt",
  "type": null,
  "message": "Unknown file type — not a recognized Android binary format"
}
```

`type: null` + `message` 表示这不是 Android 二进制——别浪费力气跑 scan 了。

::: warning type=null 不是错误
注意 `error` 仍是 `false`。识别不出是合法结果，命令成功完成。脚本里应判断 `type == null` 而非 `error == true` 来跳过扫描。
:::

## 🧪 示例命令

```bash
# 先探类型再决定扫不扫
TYPE=$(apkid-ai-cli type mystery.file | jq -r '.type')
if [ "$TYPE" = "null" ]; then
  echo "不是 Android 二进制，跳过"
else
  apkid-ai-cli scan mystery.file
fi

# 批量探类型，挑出 DEX
for f in extracted/*; do
  apkid-ai-cli type "$f" | jq -r --arg f "$f" 'select(.type=="dex") | $f'
done

# 确认 APK 是否真是 zip 容器
apkid-ai-cli type app.apk | jq '.type'   # "zip"

# 看一个 native 库
apkid-ai-cli type lib/arm64-v8a/libnative.so | jq '.type'   # "elf"
```

::: tip 典型工作流
拿到不明文件先 `type`，是 zip/dex/elf 才值得 `scan`。这能把扫描预算花在真正可能命中 YARA 规则的文件上，尤其在批量处理混合目录时。
:::

## 📍 相关

- [文件类型](../guide/file-types) — 各类型魔数与扫描行为详解。
- [type 命令源码](../modules/cli-cmd-type) — `cmd_type.py` 实现。
- [scan 命令](./ai-cli-scan) — type 确认可扫后再跑完整扫描。
- [AI CLI 概览](./ai-cli) — 全部命令索引。
