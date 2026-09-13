# cli/cmd_type.py — type 命令

<span class="badge badge-info">CLI</span>
<span class="badge badge-info">typer</span>
<span class="badge badge-success">轻量</span>

📄 `apkid-ai-cli type` 通过魔数（magic bytes）快速识别文件类型（APK/DEX/ELF 等），**不加载 YARA 规则**，是最快的识别入口。

## 📋 文件内容一览

| 符号 | 类型 | 说明 |
|------|------|------|
| `type_file(...)` | func | typer 命令回调，识别文件类型 |

模块仅导出 `type_file` 函数。`app.py` 用 `app.command(name="type")(cmd_type.type_file)` 注册——函数名 `type_file` 但命令名 `type`（避开 Python 内置 `type`）。

## 🖥️ 命令签名

```bash
apkid-ai-cli type <target>
```

## 📑 参数表

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `target` | `Path` | （必填） | 待识别文件，`exists=True` |

**仅一个参数**——type 命令不接受任何选项，因为它不扫描、不加载规则。

## 🔧 源码要点

### 不调 make_scanner

```python
from apkid.apkid import Scanner, SCANNABLE_FILE_MAGICS
from apkid.cli.common import error_exit
```

注意导入：**只 import `error_exit`，不 import `make_scanner`**。这是 8 个命令里唯一不构造 Scanner 的——它直接用 `Scanner._type_file` 静态方法。

### 读 4 字节魔数

```python
with open(target, "rb") as f:
    detected = Scanner._type_file(f)
```

`Scanner._type_file` 是**静态方法**，只读文件开头 4 字节魔数，匹配 `SCANNABLE_FILE_MAGICS`，不实例化 Scanner、不加载 `rules.yarc`。所以：

- 速度极快（毫秒级）。
- 不依赖 `rules.yarc` 是否已编译。
- 适合在 scan 前预判文件是否值得全量扫描。

### 识别成功

```python
if detected is None:
    result = {
        "error": False,
        "file": str(target),
        "type": None,
        "message": "Unknown file type — not a recognized Android binary format",
    }
else:
    result = {
        "error": False,
        "file": str(target),
        "type": detected,
        "supported_types": sorted(SCANNABLE_FILE_MAGICS.keys()),
    }
typer.echo(json.dumps(result, ensure_ascii=False, indent=2))
```

要点：

- **不识别不是错误**（`error: False`，`type: null`），带 `message` 提示。
- **识别成功**附带 `supported_types`：列出所有可扫描的文件类型，方便调用方知道 APKiD 支持哪些格式。
- **直接 `typer.echo`**：不走 `common.output_result`（无 `--output` 选项），也不走 `AIOutputFormatter`（不需要规则描述）。

### 异常处理

```python
except Exception as e:
    error_exit(str(e), type(e).__name__)
```

仅 IO 异常（如文件无法打开）会走这里。

## 🔗 调用链

```
type_file() → open(target, "rb")
            → Scanner._type_file(f)        # 静态方法，读 4 字节魔数
            → typer.echo(json.dumps(result))
异常 → common.error_exit()
```

注意：调用链里 **没有** `make_scanner`、没有 YARA、没有 `AIOutputFormatter`。

## 🤝 与其它模块的关系

- **依赖 [common.py](./cli-common)**：仅 `error_exit`（不依赖 `make_scanner`/`output_result`/枚举）。
- **依赖 [apkid/apkid.py](./core-apkid)**：`Scanner._type_file` 静态方法 + `SCANNABLE_FILE_MAGICS` 常量。
- **被 [app.py](./cli-app) 注册**：`app.command(name="type")(cmd_type.type_file)`，名字重映射。
- **与 [cmd_scan.py](./cli-cmd-scan) 互补**：type 是 scan 的"轻量前置"——先 type 判断格式，再 scan 提取标识。scan 内部也会先 `_type_file` 决定扫描路径，但 type 命令把它独立暴露。

## 📍 相关

- [AI CLI · type](../interfaces/ai-cli-type) — 用户视角用法与示例。
- [core-apkid.py](./core-apkid) — `Scanner._type_file` 与 `SCANNABLE_FILE_MAGICS`。
- [cmd_scan.py](./cli-cmd-scan) — 全量扫描（含类型识别）。
- [common.py](./cli-common) — `error_exit`。
