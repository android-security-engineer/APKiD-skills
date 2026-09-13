# CI/CD 概览

<span class="badge badge-info">CI/CD</span>
<span class="badge badge-info">GitHub Actions</span>
<span class="badge badge-info">GitHub Pages</span>

APKiD-skills 用 **GitHub Actions** 做 CI/CD，**GitHub Pages** 部署文档站。本文是整体概览。

## 🔄 两条流水线

| 流水线 | 触发 | 作用 | 工作流文件 |
|--------|------|------|-----------|
| **CI 测试** | push/PR 到 master | 编译规则、跑测试、lint | `.github/workflows/ci.yml`（已有） |
| **文档部署** | push 到 master（改 website/） | 构建 VitePress、部署到 GitHub Pages | `.github/workflows/deploy-docs.yml`（新增） |

## 🧪 CI 测试流水线

已有的 `ci.yml` 包含两个 job：

### test job
- 矩阵：Python 3.9 / 3.10 / 3.11 / 3.12
- 装 `libyara-dev` + `yara-python-dex` + `.[dev,test,mcp]`
- `python prep-release.py` 编译规则
- `pytest tests/ -q`

### lint job
- `py_compile` 检查关键 Python 文件语法
- `node -e` 校验插件 JS
- 检查所有 `SKILL.md` 的 frontmatter（必须有 `name:` 和 `description:`）

详见 [GitHub Actions 工作流](./github-actions)。

## 📖 文档部署流水线

新增的 `deploy-docs.yml`：

- 触发：push 到 master 且 `website/**` 有改动。
- 装 Node.js，`npm ci` 装 VitePress。
- `npm run build` 构建 `website/.vitepress/dist`。
- 上传 artifact，部署到 GitHub Pages。
- 产物 URL：`https://rednaga.github.io/APKiD/`（或配置的域名）。

详见 [GitHub Pages 部署](./github-pages)。

## 🏗️ 一次提交的旅程

```
git push origin master
        │
        ▼
┌───────────────────────────────────┐
│  GitHub Actions 触发               │
└───────────┬───────────────────────┘
            │
   ┌────────┴─────────┐
   ▼                  ▼
 ci.yml            deploy-docs.yml
 (test + lint)     (仅当改了 website/)
   │                  │
   ▼                  ▼
 pytest 通过?      vitepress build
   │                  │
   ▼                  ▼
 ✅/❌ 状态徽章     部署到 Pages
                      │
                      ▼
            https://...github.io/APKiD
```

## ⚙️ 前置配置（一次性）

部署文档前需在仓库设置里启用 GitHub Pages：

1. **Settings → Pages → Build and deployment → Source**：选 `GitHub Actions`（不是 branch）。
2. 这样 `deploy-docs.yml` 用 `actions/deploy-pages` 部署才有权限。
3. 首次部署后，Pages URL 出现在 Settings → Pages 顶部。

无需额外 token——`actions/deploy-pages` 用默认 `GITHUB_TOKEN`，需 workflow 加 `permissions: pages: write, id-token: write`。

## 📊 状态徽章

在 README 加徽章（可选）：

```markdown
![CI](https://github.com/rednaga/APKiD/actions/workflows/ci.yml/badge.svg)
![Docs](https://github.com/rednaga/APKiD/actions/workflows/deploy-docs.yml/badge.svg)
```

## 📍 相关

- [GitHub Actions 工作流](./github-actions) — ci.yml 详解。
- [GitHub Pages 部署](./github-pages) — deploy-docs.yml 详解。
- [文档站本地构建](./build-docs) — 本地预览。
