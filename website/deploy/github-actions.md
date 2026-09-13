# GitHub Actions 工作流

<span class="badge badge-info">GitHub Actions</span>
<span class="badge badge-info">CI</span>

APKiD 用两个 GitHub Actions 工作流：`ci.yml`（测试）和 `deploy-docs.yml`（文档部署）。本文逐段讲解。

## 🧪 ci.yml — 测试与 Lint

文件：`.github/workflows/ci.yml`

### 触发

```yaml
on:
  push:
    branches: [master]
  pull_request:
    branches: [master]
```

push 到 master 或对 master 的 PR 都触发。

### test job — 矩阵测试

```yaml
test:
  runs-on: ubuntu-latest
  strategy:
    matrix:
      python-version: ["3.9", "3.10", "3.11", "3.12"]
```

4 个 Python 版本并行跑，确保兼容性。

步骤：

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Set up Python ${{ matrix.python-version }}
    uses: actions/setup-python@v5
    with:
      python-version: ${{ matrix.python-version }}

  - name: Install system dependencies
    run: |
      sudo apt-get update
      sudo apt-get install -y libyara-dev        # ← yara-python-dex 编译需要

  - name: Install Python dependencies
    run: |
      python -m pip install --upgrade pip setuptools wheel
      pip install yara-python-dex>=1.0.1
      pip install -e ".[dev,test,mcp]"           # ← 全装开发/测试/MCP 依赖

  - name: Compile YARA rules
    run: python prep-release.py                  # ← 生成 rules.yarc

  - name: Run tests
    run: python -m pytest tests/ -q
```

::: tip 为何 CI 要编译规则
`rules.yarc` 是 gitignored 的，CI checkout 后不存在。所以测试前必须 `prep-release.py`。这也顺带验证规则能编译通过（语法检查）。
:::

### lint job — 语法与一致性

```yaml
lint:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: "3.12"

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -e ".[dev]"

    - name: Check Python syntax
      run: |
        python -m py_compile apkid/ai_output.py
        python -m py_compile apkid/cli/app.py
        # ... 列出所有 CLI 文件逐个编译

    - name: Validate plugin JS
      run: node -e "const p = require('./.claude/plugins/ai-apkid.js'); \
                    console.log('Plugin OK:', p.name, p.skills.length, 'skills')"

    - name: Check SKILL.md frontmatter
      run: |
        for dir in .claude/skills/apkid-*/; do
          name=$(basename "$dir")
          file="${dir}SKILL.md"
          [ -f "$file" ] || { echo "MISSING: $file"; exit 1; }
          grep -q "^name:" "$file" || { echo "NO name: in $file"; exit 1; }
          grep -q "^description:" "$file" || { echo "NO description: in $file"; exit 1; }
          echo "OK: $name"
        done
```

lint job 做三件事：
1. **Python 语法**：`py_compile` 每个 CLI 文件（比 mypy 轻，只查语法）。
2. **插件 JS**：`node -e` 加载 `ai-apkid.js`，验证它是合法模块且能读到 skills。
3. **SKILL.md 一致性**：每个 skill 目录必须有 `SKILL.md` 且含 `name:`/`description:` frontmatter。

## 📖 deploy-docs.yml — 文档部署

文件：`.github/workflows/deploy-docs.yml`（新增）

### 触发

```yaml
on:
  push:
    branches: [master]
    paths:
      - 'website/**'                          # ← 只在改文档时触发
      - '.github/workflows/deploy-docs.yml'
  workflow_dispatch:                          # ← 允许手动触发
```

`paths` 过滤避免改 Python 代码也重新部署文档。

### 权限

```yaml
permissions:
  contents: read
  pages: write                                 # ← Pages 部署必需
  id-token: write                              # ← OIDC token，deploy-pages 需要
```

### 并发控制

```yaml
concurrency:
  group: pages
  cancel-in-progress: false                    # ← 排队而非取消，避免部署到一半被中断
```

### build job

```yaml
build:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
        cache-dependency-path: website/package-lock.json

    - name: Install dependencies
      working-directory: website
      run: npm ci || npm install               # ← 有 lock 用 ci，否则 install

    - name: Build VitePress site
      working-directory: website
      run: npm run build                       # → website/.vitepress/dist

    - name: Setup Pages
      uses: actions/configure-pages@v5

    - name: Upload artifact
      uses: actions/upload-pages-artifact@v3
      with:
        path: website/.vitepress/dist
```

### deploy job

```yaml
deploy:
  needs: build
  runs-on: ubuntu-latest
  environment:
    name: github-pages
    url: ${{ steps.deployment.outputs.page_url }}
  steps:
    - name: Deploy to GitHub Pages
      id: deployment
      uses: actions/deploy-pages@v4
```

`environment: github-pages` 让部署出现在 Environments 里，`url` 输出最终 Pages 地址。

## 🛠️ 本地复现 CI

```bash
# 复现 test job
sudo apt-get install -y libyara-dev
pip install -e ".[dev,test,mcp]"
python prep-release.py
pytest tests/ -q

# 复现 lint job
python -m py_compile apkid/cli/app.py   # 等
node -e "const p = require('./.claude/plugins/ai-apkid.js'); console.log(p.name, p.skills.length)"

# 复现 build job
cd website && npm install && npm run build
```

## 📊 工作流徽章

```markdown
![CI](https://github.com/rednaga/APKiD/actions/workflows/ci.yml/badge.svg)
![Deploy Docs](https://github.com/rednaga/APKiD/actions/workflows/deploy-docs.yml/badge.svg)
```

## 📍 相关

- [CI/CD 概览](./cicd) — 两条流水线总览。
- [GitHub Pages 部署](./github-pages) — Pages 配置细节。
- [文档站本地构建](./build-docs) — 本地预览。
- [开发环境](../guide/development) — 本地测试。
