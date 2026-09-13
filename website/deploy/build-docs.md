# 文档站本地构建

<span class="badge badge-info">VitePress</span>
<span class="badge badge-info">本地预览</span>

本文讲怎么在本地跑起 VitePress 文档站，预览改动后再 push。

## 📋 前置

- **Node.js** ≥ 18（VitePress 要求）。推荐 20。
- 仓库已 clone。

## 📦 安装依赖

```bash
cd website
npm install
```

这会装 `vitepress`（devDependencies 里声明的 `^1.5.0`）。建议生成 `package-lock.json` 后提交，让 CI 用 `npm ci`：

```bash
npm install   # 生成 package-lock.json
git add package-lock.json
git commit -m "chore(website): add package-lock.json"
```

## 🚀 本地开发服务器

```bash
npm run dev
```

等价 `vitepress dev`。启动后访问 `http://localhost:5173`。**热更新**：改 Markdown 立即刷新。

按 `Ctrl+C` 停止。

## 🏗️ 生产构建

```bash
npm run build
```

等价 `vitepress build`。输出到 `website/.vitepress/dist/`。这是 CI 部署时生成的同一份产物。

## 👁️ 预览构建产物

```bash
npm run preview
```

等价 `vitepress preview`。用本地服务器跑 `dist/` 里的构建结果，模拟线上效果（含路由、cleanUrls 等）。访问 `http://localhost:4173`。

## 📁 目录结构

```
website/
├── .vitepress/
│   ├── config.ts          # ★ 站点配置 + 侧边栏
│   └── theme/
│       ├── index.ts        # 主题入口
│       └── custom.css      # 自定义样式（badge、品牌色）
├── public/
│   └── favicon.svg         # 站点图标
├── index.md                # 首页
├── guide/                  # 指南文档
├── interfaces/             # 接口文档
├── modules/                # 代码模块文档
├── rules/                  # 检测规则文档
├── deploy/                 # 部署文档
└── package.json
```

## ✏️ 改文档的流程

```bash
# 1. 开发服务器
cd website && npm run dev

# 2. 改 Markdown（浏览器实时刷新）
# 编辑 website/guide/xxx.md

# 3. 加新页要同步改侧边栏
# 编辑 .vitepress/config.ts 的 sidebar

# 4. 本地构建确认无误
npm run build

# 5. 提交
cd ..
git add website/
git commit -m "docs: 完善xxx文档"
git push   # → 触发 deploy-docs.yml
```

::: warning 加新页要改 config.ts
VitePress 不会自动把新 `.md` 加进侧边栏。新建文档后，必须在 `.vitepress/config.ts` 的 `sidebar` 里加对应链接，否则用户从侧边栏点不到（但能通过直接 URL 访问）。
:::

## 🎨 自定义样式

改 `.vitepress/theme/custom.css` 调整：

- `--vp-c-brand-1/2/3`：品牌主色（绿）。
- `--vp-custom-block-*`：提示框颜色。
- `.badge-*`：徽章样式。

改完 `npm run dev` 立即看效果。

## 🔍 检查死链

VitePress 构建时会警告指向不存在 `.md` 的链接。构建后看输出：

```bash
npm run build 2>&1 | grep -i "dead\|not found\|warn"
```

有死链就修 `config.ts` 或链接路径。

## 🐳 不装 Node 也能预览？

如果你只想看效果不想装 Node，可以等 push 后让 CI 部署，去 GitHub Pages URL 看。但本地预览迭代快得多，推荐装。

## 📍 相关

- [GitHub Actions 工作流](./github-actions) — CI 怎么构建。
- [GitHub Pages 部署](./github-pages) — 线上部署。
- [config.ts 解读](../deploy/cicd) — 配置结构。
