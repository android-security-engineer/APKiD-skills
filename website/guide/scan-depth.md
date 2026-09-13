# 扫描深度与递归

<span class="badge badge-info">递归</span>
<span class="badge badge-info">ZIP</span>
<span class="badge badge-danger">zip bomb</span>

APK 是 ZIP，里面可能有嵌套的 ZIP（套娃加固、内嵌 APK）。APKiD 会递归解包扫描，但必须有边界——本文讲清楚边界在哪。

## 🔄 递归是怎么发生的

`Scanner._scan_zip_entry()` 扫完一个条目后，会判断该条目本身是不是 ZIP：

```python
if depth < self.options.scan_depth and self._is_zipfile(entry_buffer, info.filename):
    with zipfile.ZipFile(entry_buffer) as zip_entry:
        nested_results = self._scan_zip(zip_entry, depth=depth + 1)
        for nested_name, nested_matches in nested_results.items():
            results[f'{info.filename}!{nested_name}'] = nested_matches
```

每次深入一层，`depth` 加 1，直到达到 `scan_depth` 上限。

## 📏 命名约定：`!` 分隔

嵌套条目的 `source`/结果键用 `!` 串联层级：

```
app.apk
  └─ assets/inner.apk            ← 第 1 层
       └─ classes.dex            ← 第 2 层
            └─ ...
```

扫描结果的键：

```
app.apk                                  （外层 ZIP 自身命中）
app.apk!assets/inner.apk                 （第 1 层 inner.apk 命中）
app.apk!assets/inner.apk!classes.dex     （第 2 层 dex 命中）
```

## ⚙️ scan_depth 选项

`Options.scan_depth`（默认 `2`）控制最大递归深度。

| 值 | 行为 |
|----|------|
| `0` | 不递归。只扫外层文件本身，不解压 ZIP 条目 |
| `1` | 解压一层，扫第 1 层条目，不继续深入 |
| `2`（默认） | 解压两层 |
| `N` | 解压 N 层 |

```bash
# 默认深度 2
apkid-ai-cli scan app.apk

# 只扫外层，不进 ZIP
apkid-ai-cli scan app.apk --scan-depth 0

# 扫更深的嵌套（套娃加固）
apkid-ai-cli scan app.apk --scan-depth 4
```

::: warning 别设太大
恶意 ZIP 可以无限嵌套（zip bomb）。把 `scan_depth` 设成 1000 然后扫陌生样本，会指数级占用内存。源码注释原话："Don't get cheeky and think you can set this value to 1000 and scan random malware without blowing up your memory."
:::

## 🛡️ zip bomb 防护

除了深度限制，`_scan_zip_entry()` 还捕获重叠条目 / zip bomb 异常：

```python
except zipfile.BadZipFile as e:
    if "Overlapped entries" in str(e) or "possible zip bomb" in str(e):
        if self.options.verbose:
            print(f"[W] Skipping overlapped entry {info.filename} (possible zip bomb)")
        return
    else:
        raise
```

碰到可疑的重叠条目就跳过该条目，而非崩溃。配合 `scan_depth` 双保险。

## 🗜️ XZ 压缩条目

标准库 `zipfile` 不支持 XZ 压缩（`compress_type == 95`），会抛 `NotImplementedError`。APKiD 手动解析 Local File Header、用 `lzma` 解压：

```python
if info.compress_type == XZ_COMPRESSION_TYPE:
    # 手动定位数据偏移：LFH 头 + filename 长度 + extra 长度
    raw_zip.seek(info.header_offset + ZIP_LFH_FIELDS_SIZE)
    filename_len = struct.unpack('<H', raw_zip.read(2))[0]
    extra_len = struct.unpack('<H', raw_zip.read(2))[0]
    data_offset = info.header_offset + ZIP_LFH_HEADER_SIZE + filename_len + extra_len
    raw_zip.seek(data_offset)
    decompressed_data = lzma.decompress(raw_zip.read(info.compress_size))
```

这让用 XZ 压缩的 dex/so 条目也能被扫到。解压失败会打印错误并跳过，不中断整个扫描。

## 📏 entry_max_scan_size：条目大小限制

`Options.entry_max_scan_size`（默认 `0`，即无限制）让你跳过过大的 ZIP 条目：

- 经典 CLI 默认 `100 * 1024 * 1024`（100 MB）——避免解压巨型资源。
- AI CLI 默认 `0`（无限制），但可设：

```bash
apkid-ai-cli scan app.apk --entry-max-scan-size 52428800   # 跳过 >50MB 的条目
```

`0` 表示不限制。非 0 时，仅扫解压后小于该值的条目。

::: tip 何时调小
扫一个塞了几个 500MB 视频资源的"伪 APK"时，`entry_max_scan_size` 能避免把内存吃光。恶意样本常用超大条目做 DoS。
:::

## 🧭 扫描决策流程

一个 ZIP 条目要不要扫、扫多深，综合判定：

```
ZIP 条目 info
  │
  ├─ 解压（支持 deflate/store/xz；zip bomb → 跳过）
  │
  ├─ _should_scan()?  ← 看 typing 策略（magic/filename/none）
  │     ├─ 否 → 跳过
  │     └─ 是 ↓
  │
  ├─ entry_max_scan_size 检查（>0 且超限 → 跳过）
  │
  ├─ rules.match() 匹配
  │
  └─ depth < scan_depth 且 _is_zipfile?
        ├─ 是 → 递归 _scan_zip(depth+1)
        └─ 否 → 结束
```

## 📍 下一步

- [文件类型识别](./file-types) — `typing` 与 `_should_scan` 详解。
- [代码模块：apkid.py](../modules/core-apkid) — `_scan_zip_entry` 源码。
- [工作原理](./how-it-works) — 整体流程。
