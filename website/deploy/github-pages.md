# GitHub Pages 部署

<span class="badge badge-info">GitHub Pages</span>
<span class="badge badge-info">部署</span>

本文讲怎么把 VitePress 文档站部署到 GitHub Pages，以及一次性配置和排错。

## 🚀 一次性配置

### 1. 启用 Pages

仓库 **Settings → Pages → Build and deployment**：

- **Source**：选 `GitHub Actions`（不是 `Deploy from a branch`）。

选 `GitHub Actions` 后，部署由 `deploy-docs.yml` 里的 `actions/deploy-pages` 完成，不再需要 `gh-pages` 分支。

### 2. 确认权限

`deploy-docs.yml` 已声明：

```yaml
permissions:
  contents: read
  pages: write
  id-token: write
```

仓库 **Settings → Actions → General → Workflow permissions**：选 `Read and write permissions`（或保持默认，YAML 里的 `permissions` 会覆盖）。`id-token: write` 用于 OIDC。

### 3. 首次部署

```bash
git add website/ .github/workflows/deploy-docs.yml
git commit -m "docs: add VitePress website and deploy workflow"
git push origin master
```

push 后去 **Actions** 标签看 `Deploy Docs` 工作流。首次跑完，**Settings → Pages** 顶部会出现站点 URL，形如：

```
https://rednaga.github.io/APKiD/
```

## 🌐 站点 URL

GitHub Pages 默认 URL 格式：

- 用户/组织站点：`https://<owner>.github.io/`
- 项目站点：`https://<owner>.github.io/<repo>/`

APKiD 是项目仓库，默认是 `https://rednaga.github.io/APKiD/`。

### 自定义域名（可选）

若用自己的域名：

1. **Settings → Pages → Custom domain**：填 `docs.apkid.io`（示例）。
2. DNS 加 CNAME 记录指向 `rednaga.github.io`。
3. 勾选 `Enforce HTTPS`。
4. 在 `website/public/` 放一个 `CNAME` 文件（内容就是域名），让构建产物带上它。

::: tip 自定义域名与 basePath
用自定义域名时，站点在根路径，`config.ts` 不用改 `base`。若用默认项目 URL（`/APKiD/` 子路径），可能需要设 `base: '/APKiD/'`——但 `cleanUrls: true` 配合 `actions/configure-pages` 通常自动处理，先不设 base 试。
:::

## 📦 部署产物

VitePress 构建输出到 `website/.vitepress/dist/`，`upload-pages-artifact` 把它打成 artifact，`deploy-pages` 发布。包含：

- 编译后的 HTML/CSS/JS。
- `public/` 下的静态资源（favicon 等）。
- `sitemap.xml`（VitePress 自动生成）。

## 🔄 部署触发条件

```yaml
on:
  push:
    branches: [master]
    paths:
      - 'website/**'
      - '.github/workflows/deploy-docs.yml'
  workflow_dispatch:
```

- 改 `website/` 下任何文件 → 重新部署。
- 改工作流本身 → 重新部署。
- 改 Python 代码但没动文档 → **不**部署（节省 Actions 分钟）。
- `workflow_dispatch`：Actions 页面可手动触发。

## 🐛 排错

| 现象 | 原因与解决 |
|------|-----------|
| `deploy-pages` 报 403 | Pages Source 没设成 `GitHub Actions`，去 Settings → Pages 改 |
| 部署成功但 404 | URL 路径不对，或 `base` 未设；检查 Settings → Pages 的 URL |
| 构建报 `vitepress: not found` | `npm ci` 失败，检查 package-lock.json；用 `npm install` 兜底 |
| 样式/图标丢失 | `public/` 资源路径问题，确认 favicon 用绝对路径 `/favicon.svg` |
| 改了文档没触发 | 改的文件不在 `website/` 下，或 commit 没包含触发路径 |

## 📊 验证部署

```bash
# 看工作流状态
gh run list --workflow=deploy-docs.yml

# 拿到 URL
gh api repos/rednaga/APKiD/pages --jq '.html_url'
```

或直接访问站点，确认最新内容（GitHub Pages 有 CDN 缓存，强刷或等几分钟）。

## 🛡️ 部署环境保护（可选）

仓库 **Settings → Environments → github-pages**：可加 `Required reviewers`，让文档部署需人工批准。或加 `Deployment branches** 限制只允许 master 部署。生产仓库建议开。

## 📍 相关

- [CI/CD 概览](./cicd) — 两条流水线总览。
- [GitHub Actions 工作流](./github-actions) — `deploy-docs.yml` 逐段详解。
- [文档站本地构建](./build-docs) — push 前本地预览。
