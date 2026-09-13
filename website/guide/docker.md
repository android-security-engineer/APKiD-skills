# Docker 运行

<span class="badge badge-info">Docker</span>
<span class="badge badge-info">容器化</span>

APKiD 提供 Dockerfile，让你无需在本机装 `libyara` 即可运行。镜像内置三种接口。

## 🏗️ 构建镜像

```bash
git clone https://github.com/rednaga/APKiD
cd APKiD
docker build . -t rednaga:apkid
```

镜像基于 Python，构建时会自动 `pip install` 依赖并 `python prep-release.py` 编译规则，所以镜像内 `rules.yarc` 已就绪。

## 📂 经典 CLI

仓库 `docker/` 目录下有封装脚本 `apkid.sh`，把宿主目录映射进容器：

```bash
# 需先 chmod +x docker/apkid.sh
docker/apkid.sh ~/reverse/targets/android/example/example.apk
```

等价的裸 docker 命令：

```bash
docker run --rm -v /path/to/samples:/input:ro rednaga:apkid apkid /input/app.apk
```

## 🤖 AI CLI

```bash
# 扫描
docker run --rm -v /path/to/samples:/input:ro rednaga:apkid \
  apkid-ai-cli scan /input/app.apk

# 批量
docker run --rm -v /path/to/samples:/input:ro rednaga:apkid \
  apkid-ai-cli batch /input/ --recursive --pattern "*.apk" -o /input/results.json

# 对比
docker run --rm -v /path/to/samples:/input:ro rednaga:apkid \
  apkid-ai-cli diff /input/v1.apk /input/v2.apk
```

## 🔌 MCP 服务器

MCP 用 stdio 传输，加 `-i`（interactive）保持 stdin 打开：

```bash
docker run --rm -i rednaga:apkid apkid-mcp
```

在 MCP 客户端配置里用这个命令即可。详见 [MCP 概览](../interfaces/mcp)。

## 📁 挂载卷说明

- `-v /path/to/samples:/input:ro`：把宿主样本目录只读挂到容器 `/input`。要写结果文件时，把输出目录挂为可写卷，或在宿主 `-o` 指定的路径在挂载卷内。
- `:ro`（只读）是安全建议——分析恶意样本时别给容器写权限。

## 🐳 Dockerfile 要点

仓库的 `Dockerfile` 大致做了：

```dockerfile
FROM python:3.12-slim

# 系统依赖：libyara
RUN apt-get update && apt-get install -y libyara-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN pip install --no-cache-dir .[mcp] \
 && python prep-release.py          # 编译规则

ENTRYPOINT ["apkid-ai-cli"]
```

（实际内容以仓库 `Dockerfile` 为准。）

## 📍 下一步

- [安装指南](./installation) — 非 Docker 安装。
- [AI CLI 概览](../interfaces/ai-cli) — 容器内可用的命令。
