# 文件类型识别

<span class="badge badge-file">file_type</span>
<span class="badge badge-info">魔数</span>

APKiD 只扫描它能识别的文件类型。本文解释每种类型、它的魔数，以及 `typing` 选项如何影响判定。

## 📋 支持的文件类型

定义在 [`apkid/apkid.py`](../modules/core-apkid) 的 `SCANNABLE_FILE_MAGICS`：

| 类型 | 魔数（hex） | 魔数（ASCII） | 典型文件 |
|------|------------|--------------|----------|
| `zip` | `50 4B 03 04` / `50 4B 05 06` / `50 4B 07 08` | `PK..` | APK、JAR、AAR、ZIP |
| `dex` | `64 65 78 0A` / `64 65 79 0A` | `dex\n` / `dey\n` | `classes.dex`、ODEX |
| `elf` | `7F 45 4C 46` | `\x7fELF` | `lib/*/*.so`、原生可执行文件 |
| `res` | `02 00 0C 00` | — | `resources.arsc`、二进制资源 |
| `dll` | `4D 5A 90 00` | `MZ..\x00` | Windows PE DLL |

::: tip 为何有三种 zip 魔数
`PK\x03\x04` 是 Local File Header（正常条目），`PK\x05\x06` 是 End of Central Directory（空压缩包也可能有），`PK\x07\x08` 是 Spanned Archive 标记。三者都算 ZIP。
:::

## 🔍 判定逻辑：`Scanner._type_file()`

只读前 4 字节，逐一比对魔数集合：

```python
@staticmethod
def _type_file(file: IO) -> Union[None, str]:
    magic = file.read(4)
    file.seek(0)
    for file_type, magics in SCANNABLE_FILE_MAGICS.items():
        if magic in magics:
            return file_type
    return None
```

返回类型字符串或 `None`（不识别）。开销极小——一次 4 字节读取。

## ⚙️ `typing` 选项

`Options.typing` 控制"什么文件值得扫描"，是 **性能与准确性的核心权衡**：

### `magic`（默认）

只扫描魔数匹配的文件。APK 内部有大量图片、字体等无关条目，魔数判定只需读 4 字节就能跳过它们，避免无谓的全量解压。

**适用**：绝大多数场景。平衡了速度与覆盖。

### `filename`

按文件名/路径判断，不读内容：

```python
name.lower().startswith('classes')        # classes*.dex
or name.startswith('AndroidManifest.xml')
or name.startswith('lib/')                 # 原生库目录
or name.endswith('.so')
or name.endswith('.dex')
or name.endswith('.apk')
or name.endswith('.arsc')
or name.endswith('.dll')
```

**更快**（连魔数都不读），但 **可能漏报**：一个被改名为 `notmalware.gif` 的 dex 不会被发现。恶意样本常用这招规避基于扩展名的扫描。

### `none`

不做任何过滤，把每个文件都喂给 YARA。**最彻底**但 **最慢**，且对 zip bomb 毫无防护——每个条目都会被全量解压扫描。

::: warning none 的代价
设 `typing=none` 扫描大型 APK 时，APK 里成百上千的图片资源会被逐个读入内存做 YARA 匹配，既慢又吃内存。只在确认需要时用，并配合 `--entry-max-scan-size` 限制条目大小。
:::

## 🧩 嵌套 ZIP 的判定

`_is_zipfile()` 同时用魔数和 `zipfile.is_zipfile()` 双重判定，避免某些 ELF 被误判为 zip（`zipfile.is_zipfile` 不够严谨）：

```python
def _is_zipfile(self, file: IO, name: str) -> bool:
    if self.options.typing == 'filename':
        return name.lower().endswith(('.apk', '.zip', '.jar'))
    else:
        file.seek(0)
        return Scanner._type_file(file) == 'zip' and zipfile.is_zipfile(file)
```

## 📤 用 `type` 命令快速判定

不需要跑完整扫描时，用 `apkid-ai-cli type` 只做类型判定（不加载 YARA，秒出）：

```bash
apkid-ai-cli type /path/to/file
```

```json
{
  "error": false,
  "file": "/path/to/file",
  "type": "dex",
  "supported_types": ["dex", "dll", "elf", "res", "zip"]
}
```

详见 [type 命令](../interfaces/ai-cli-type)。

## 📍 下一步

- [扫描深度与递归](./scan-depth) — 识别为 zip 后如何递归。
- [代码模块：apkid.py](../modules/core-apkid) — `_type_file` 源码。
- [file_type 检测类别](../rules/category-file-type) — file_type 标签的规则。
