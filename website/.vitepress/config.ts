import { defineConfig } from 'vitepress'

// APKiD 文档站点配置
// 侧边栏按模块组织，目标是让用户只看文档站就能学会整个项目
export default defineConfig({
  lang: 'zh-CN',
  title: 'APKiD',
  description: 'Android 二进制识别工具 — 加固、混淆器、保护器、编译器指纹识别',
  lastUpdated: true,
  cleanUrls: true,

  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' }],
    ['meta', { name: 'theme-color', content: '#3aa675' }],
    ['meta', { name: 'og:title', content: 'APKiD — Android 二进制识别工具' }],
    ['meta', { name: 'og:description', content: '识别 APK 是如何被构建、加固与混淆的。Android 版的 PEiD。' }]
  ],

  themeConfig: {
    logo: '/favicon.svg',

    siteTitle: 'APKiD 文档',

    nav: [
      { text: '指南', link: '/guide/what-is-apkid' },
      { text: '接口', link: '/interfaces/overview' },
      { text: '代码模块', link: '/modules/core-apkid' },
      { text: '检测规则', link: '/rules/overview' },
      { text: 'GitHub', link: 'https://github.com/rednaga/APKiD' }
    ],

    sidebar: {
      // 指南
      '/guide/': [
        {
          text: '入门',
          collapsed: false,
          items: [
            { text: 'APKiD 是什么', link: '/guide/what-is-apkid' },
            { text: '解决了什么问题', link: '/guide/problem-it-solves' },
            { text: '工作原理', link: '/guide/how-it-works' },
            { text: '架构概览', link: '/guide/architecture' },
            { text: '快速开始', link: '/guide/quickstart' }
          ]
        },
        {
          text: '安装',
          collapsed: false,
          items: [
            { text: '安装指南', link: '/guide/installation' },
            { text: 'Docker 运行', link: '/guide/docker' },
            { text: '开发环境', link: '/guide/development' }
          ]
        },
        {
          text: '核心概念',
          collapsed: false,
          items: [
            { text: '文件类型识别', link: '/guide/file-types' },
            { text: '检测类别', link: '/guide/categories' },
            { text: 'YARA 规则系统', link: '/guide/yara-system' },
            { text: 'AI 输出格式', link: '/guide/output-format' },
            { text: '扫描深度与递归', link: '/guide/scan-depth' }
          ]
        }
      ],

      // 三种接口
      '/interfaces/': [
        {
          text: '接口总览',
          items: [
            { text: '三种接口对比', link: '/interfaces/overview' }
          ]
        },
        {
          text: '经典 CLI (apkid)',
          collapsed: false,
          items: [
            { text: '经典 CLI 概览', link: '/interfaces/classic-cli' }
          ]
        },
        {
          text: 'AI CLI (apkid-ai-cli)',
          collapsed: false,
          items: [
            { text: 'AI CLI 概览', link: '/interfaces/ai-cli' },
            { text: 'scan 扫描单文件', link: '/interfaces/ai-cli-scan' },
            { text: 'batch 批量扫描', link: '/interfaces/ai-cli-batch' },
            { text: 'diff 对比差异', link: '/interfaces/ai-cli-diff' },
            { text: 'type 文件类型', link: '/interfaces/ai-cli-type' },
            { text: 'info 版本信息', link: '/interfaces/ai-cli-info' },
            { text: 'list-tags 标签列表', link: '/interfaces/ai-cli-list-tags' },
            { text: 'rules 规则管理', link: '/interfaces/ai-cli-rules' },
            { text: 'skills 自发现', link: '/interfaces/ai-cli-skills' }
          ]
        },
        {
          text: 'MCP 服务器 (apkid-mcp)',
          collapsed: false,
          items: [
            { text: 'MCP 概览', link: '/interfaces/mcp' },
            { text: 'scan_file', link: '/interfaces/mcp-scan-file' },
            { text: 'batch_scan', link: '/interfaces/mcp-batch-scan' },
            { text: 'diff_files', link: '/interfaces/mcp-diff-files' },
            { text: 'type_file', link: '/interfaces/mcp-type-file' },
            { text: 'info', link: '/interfaces/mcp-info' },
            { text: 'list_tags', link: '/interfaces/mcp-list-tags' },
            { text: 'rules', link: '/interfaces/mcp-rules' },
            { text: 'skills', link: '/interfaces/mcp-skills' }
          ]
        }
      ],

      // 代码模块
      '/modules/': [
        {
          text: '核心模块',
          collapsed: false,
          items: [
            { text: 'apkid.py 扫描引擎', link: '/modules/core-apkid' },
            { text: 'ai_output.py AI 输出', link: '/modules/ai-output' },
            { text: 'output.py 经典输出', link: '/modules/output' },
            { text: 'rules.py 规则管理', link: '/modules/rules' },
            { text: '__init__.py 版本信息', link: '/modules/init' },
            { text: 'main.py 经典入口', link: '/modules/main' }
          ]
        },
        {
          text: 'CLI 模块 (apkid/cli)',
          collapsed: false,
          items: [
            { text: 'app.py 应用入口', link: '/modules/cli-app' },
            { text: 'common.py 共享工具', link: '/modules/cli-common' },
            { text: 'cmd_scan.py', link: '/modules/cli-cmd-scan' },
            { text: 'cmd_batch.py', link: '/modules/cli-cmd-batch' },
            { text: 'cmd_diff.py', link: '/modules/cli-cmd-diff' },
            { text: 'cmd_type.py', link: '/modules/cli-cmd-type' },
            { text: 'cmd_info.py', link: '/modules/cli-cmd-info' },
            { text: 'cmd_tags.py', link: '/modules/cli-cmd-tags' },
            { text: 'cmd_rules.py', link: '/modules/cli-cmd-rules' },
            { text: 'cmd_skills.py', link: '/modules/cli-cmd-skills' }
          ]
        },
        {
          text: 'MCP 模块 (apkid/mcp)',
          collapsed: false,
          items: [
            { text: 'server.py FastMCP 服务器', link: '/modules/mcp-server' },
            { text: 'tools_scan.py 扫描工具', link: '/modules/mcp-tools-scan' },
            { text: 'tools_info.py 信息工具', link: '/modules/mcp-tools-info' }
          ]
        }
      ],

      // 检测规则
      '/rules/': [
        {
          text: '规则总览',
          items: [
            { text: '规则系统概览', link: '/rules/overview' },
            { text: '规则文件组织', link: '/rules/organization' },
            { text: '编写 YARA 规则', link: '/rules/writing-rules' },
            { text: '编译与发布', link: '/rules/compilation' }
          ]
        },
        {
          text: '检测类别',
          collapsed: false,
          items: [
            { text: 'packer 加固', link: '/rules/category-packer' },
            { text: 'protector 保护器', link: '/rules/category-protector' },
            { text: 'obfuscator 混淆器', link: '/rules/category-obfuscator' },
            { text: 'compiler 编译器', link: '/rules/category-compiler' },
            { text: 'anti_vm 反虚拟机', link: '/rules/category-anti-vm' },
            { text: 'anti_debug 反调试', link: '/rules/category-anti-debug' },
            { text: 'anti_disassembly 反汇编', link: '/rules/category-anti-disassembly' },
            { text: 'anti_root 反 Root', link: '/rules/category-anti-root' },
            { text: 'abnormal 异常结构', link: '/rules/category-abnormal' },
            { text: 'dropper 释放器', link: '/rules/category-dropper' },
            { text: 'manipulator 篡改器', link: '/rules/category-manipulator' },
            { text: 'file_type 文件类型', link: '/rules/category-file-type' },
            { text: '其它类别', link: '/rules/category-misc' }
          ]
        },
        {
          text: 'APK 规则',
          collapsed: false,
          items: [
            { text: 'APK 规则总览', link: '/rules/apk-overview' },
            { text: 'APK 加固 (packers)', link: '/rules/apk-packers' },
            { text: 'APK 保护器 (protectors)', link: '/rules/apk-protectors' },
            { text: 'APK 混淆器 (obfuscators)', link: '/rules/apk-obfuscators' },
            { text: 'APK 通用 (common)', link: '/rules/apk-common' }
          ]
        },
        {
          text: 'DEX 规则',
          collapsed: false,
          items: [
            { text: 'DEX 规则总览', link: '/rules/dex-overview' },
            { text: 'DEX 加固 (packers)', link: '/rules/dex-packers' },
            { text: 'DEX 保护器 (protectors)', link: '/rules/dex-protectors' },
            { text: 'DEX 混淆器 (obfuscators)', link: '/rules/dex-obfuscators' },
            { text: 'DEX 编译器 (compilers)', link: '/rules/dex-compilers' },
            { text: 'DEX 反虚拟机 (anti-vm)', link: '/rules/dex-anti-vm' },
            { text: 'DEX 异常结构 (abnormal)', link: '/rules/dex-abnormal' },
            { text: 'DEX 通用 (common)', link: '/rules/dex-common' }
          ]
        },
        {
          text: 'ELF 规则',
          collapsed: false,
          items: [
            { text: 'ELF 规则总览', link: '/rules/elf-overview' },
            { text: 'ELF 加固 (packers)', link: '/rules/elf-packers' },
            { text: 'ELF 保护器 (protectors)', link: '/rules/elf-protectors' },
            { text: 'ELF 混淆器 (obfuscators)', link: '/rules/elf-obfuscators' },
            { text: 'ELF 反虚拟机 (anti-vm)', link: '/rules/elf-anti-vm' },
            { text: 'ELF 通用 (common)', link: '/rules/elf-common' }
          ]
        },
        {
          text: 'DLL / RES 规则',
          collapsed: false,
          items: [
            { text: 'DLL 规则', link: '/rules/dll-overview' },
            { text: 'RES 规则', link: '/rules/res-overview' }
          ]
        }
      ],

      // 部署与运维
      '/deploy/': [
        {
          text: '部署',
          items: [
            { text: 'CI/CD 概览', link: '/deploy/cicd' },
            { text: 'GitHub Actions 工作流', link: '/deploy/github-actions' },
            { text: 'GitHub Pages 部署', link: '/deploy/github-pages' },
            { text: '文档站本地构建', link: '/deploy/build-docs' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/rednaga/APKiD' }
    ],

    outline: {
      level: [2, 3],
      label: '本页目录'
    },

    docFooter: {
      prev: '上一页',
      next: '下一页'
    },

    lastUpdatedText: '最后更新',

    search: {
      provider: 'local',
      options: {
        translations: {
          button: { buttonText: '搜索文档', buttonAriaLabel: '搜索' },
          modal: {
            displayDetails: '显示详情',
            resetButtonTitle: '清除',
            backButtonTitle: '返回',
            noResultsText: '没有结果',
            footer: {
              selectText: '选择',
              navigateText: '切换',
              closeText: '关闭'
            }
          }
        }
      }
    },

    footer: {
      message: '基于 GPL & Commercial 双重许可发布',
      copyright: 'Copyright © 2026 RedNaga'
    }
  }
})
