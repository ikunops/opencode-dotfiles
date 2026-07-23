# OpenCode 配置同步仓库

本仓库用于同步 OpenCode 的跨平台配置、Skills、Plugins、MCP 服务、知识库与初始化脚本。
当前已将原始 Skills 按“平台 / 框架 / 功能域”三层结构整理，方便按需查找和复用。

## 仓库结构

```
opencode-dotfiles/
├─ skills/
│  ├─ platform-specific/       # 按平台分类
│  ├─ framework-specific/       # 按框架分类
│  └─ function-specific/        # 按功能域分类
├─ knowledge/
│  └─ ai-safety/                # AI 安全专业知识库
├─ scripts/
│  ├─ classify-skills.ps1       # 技能分类脚本
│  ├─ init-security.ps1         # 初始化安全技能到本地
│  └─ validate-security.ps1     # 验证安全技能是否已安装
├─ configs/
│  └─ security/                 # 安全相关配置
├─ platforms/                   # 平台特定配置
├─ plugins/                     # 插件
├─ README.md                    # 总览
└─ QUICKSTART.md                # 快速开始
```

## 快速开始

- Windows：`powershell -ExecutionPolicy Bypass -File .\setup.ps1`
- Linux/macOS：`bash setup.sh`

## Skills 现状

本仓库已整理为三类目录，入口更清晰，查找成本更低：

## 平台特定

- `platform-specific/windows`：Windows 桌面自动化与原生应用相关
- `platform-specific/linux`：Linux 运维与系统自动化
- `platform-specific/macos`：macOS 环境与原生开发
- `platform-specific/android`：Android 架构与工程化
- `platform-specific/ios`：iOS、Swift 与 Apple 生态
- `platform-specific/flutter`：Flutter 移动端跨端
- `platform-specific/react-native`：React Native 移动端
- `platform-specific/cross-platform`：跨平台通用能力
- `platform-specific/bun`：Bun 运行时
- `platform-specific/flox`：Flox 可复现环境

## 框架特定

- `framework-specific/react`：React 组件、性能、测试
- `framework-specific/vue`：Vue 模式与生态
- `framework-specific/angular`：Angular 工程化
- `framework-specific/nextjs`：Next.js 服务端与渲染
- `framework-specific/nuxt`：Nuxt 工程化
- `framework-specific/vite`：Vite 构建与插件
- `framework-specific/django`：Django 架构与安全
- `framework-specific/laravel`：Laravel 工程化
- `framework-specific/spring-boot`：Spring Boot 架构
- `framework-specific/quarkus`：Quarkus 云原生
- `framework-specific/nestjs`：NestJS 服务端
- `framework-specific/fastapi`：FastAPI 后端
- `framework-specific/compose-multiplatform`：Compose Multiplatform

## 功能域特定

- `function-specific/ai-agent`：Agent 架构、评估、自主运行、成本追踪、并行编排
- `function-specific/backend`：后端模式、API 设计、RPC/TS/Go/.NET
- `function-specific/database`：PostgreSQL、MySQL、Oracle、SQL Review、迁移、ORM
- `function-specific/devops`：K8s、Terraform、SRE、监控、网络、Docker
- `function-specific/frontend`：前端模式、无障碍、动效、设计系统
- `function-specific/testing`：单测、集成、E2E、压测、基准
- `function-specific/security`：安全审查、赏金、合规、PHI、DeFi、LLM 安全
- `function-specific/monitoring`：监控、告警、SLO、可观测性
- `function-specific/content`：写作、视频、营销、SEO、社交媒体
- `function-specific/business`：运筹、财务、供应链、库存、预测市场
- `function-specific/research`：文献、PubMed、USPTO、深度研究
- `function-specific/integration`：GitHub、Jira、Gmail、Slack、文档、音视频、MCP
- `function-specific/cloud`：云架构、Homelab、DNS、VLAN、WireGuard
- `function-specific/data`：数据工程、ClickHouse、推荐系统
- `function-specific/development-workflow`：需求、计划、TDD、调试、评审、交付
- `function-specific/language-ecosystem`：各语言标准、测试、编码规范
- `function-specific/misc`：暂未归类的通用能力

## 安全规则

本仓库包含 `ai-safety-sop` 技能，提供四层漏斗模型与不可逆操作阻断规则。

如需立即应用到本机：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\init-security.ps1
```

验证：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-security.ps1
```

## 平台适配

脚本会自动检测操作系统并应用对应配置：

| 平台 | Shell | 说明 |
|------|-------|------|
| Windows | `powershell` | 完整支持 |
| Linux | `bash` | 完整支持 |
| macOS | `bash` | 完整支持 |

## 使用方式

### Skills 和 Plugins

重启 OpenCode 后自动生效，无需额外操作。

### MCP 工具

直接用自然语言提问，LLM 会自动调用：

```
看看这台机器内存够不够
Docker 容器都正常吗
帮我扫一下项目有没有安全漏洞
```

### Context7

Context7 提供实时库文档查询，替代过时的训练数据：

```bash
# 安装
npx ctx7 setup --opencode

# 使用
use context7 to show me how to set up middleware in Next.js 15
```

也可以通过 MCP 直接连接（无需安装）：

```json
{
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```

### Firecrawl

Firecrawl 提供网页爬取、搜索和抓取功能。**需要先注册账号获取 API Key**：

1. 访问 [firecrawl.dev](https://firecrawl.dev) 注册账号
2. 在控制台获取 API Key（格式：`fc-xxx`）
3. 配置认证：

```bash
# 安装 CLI
npm install -g firecrawl-cli

# 方式一：浏览器登录（推荐）
firecrawl login --browser

# 方式二：设置 API Key
export FIRECRAWL_API_KEY=fc-your-api-key
```

免费套餐包含每月 500 次爬取。

### Composio

首次使用时需要认证：

```bash
opencode mcp auth composio
```

然后在浏览器中完成 OAuth 登录授权。

## 其他机器同步

### 前提条件

- Node.js >= 18.0.0
- OpenCode 已安装

### 一键同步

```powershell
# Windows
git clone https://github.com/ikunops/opencode-dotfiles.git $env:TEMP\oc-config
.\$env:TEMP\oc-config\setup.ps1

# Linux/macOS
git clone https://github.com/ikunops/opencode-dotfiles.git /tmp/oc-config
bash /tmp/oc-config/setup.sh
```

### 同步后验证

启动 OpenCode，检查：
1. Skills 是否加载：输入 `/skills` 查看
2. MCP 是否加载：运行 `opencode mcp list`
3. 测试工具：问一句“看看系统内存”

## 首次拉取后需要做的（每台机器只需一次）

以下内容**不同步到 git**，每台新机器首次拉取后必须手动完成：

### 1. 安装 npm 依赖

```bash
cd ~/.config/opencode
npm install
```

### 2. Composio OAuth 认证

Composio 的认证令牌存在本地凭据中，不会同步到 git。使用涉及第三方应用（Gmail、Slack、GitHub 等）的指令时，OpenCode 会自动提示你点链接授权，或在终端运行：

```bash
opencode mcp auth composio
```

然后在浏览器中完成登录。

### 3. infra-ops-mcp（可选）

如需本地基础设施工具：

```bash
npm install -g github:skyvanguard/infra-ops-mcp
```

### 4. Firecrawl（可选）

如需网页爬取/搜索功能，需在 [firecrawl.dev](https://firecrawl.dev) 注册获取 API Key。

## 更新配置

在任意机器修改后：

```powershell
cd ~/.config/opencode
git add .
git commit -m "更新xxx"
git push
```

其他机器同步：

```powershell
cd ~/.config/opencode
git pull
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `opencode.base.jsonc` | 基础配置（跨平台） |
| `platforms/windows.jsonc` | Windows 特定配置 |
| `platforms/linux.jsonc` | Linux/macOS 特定配置 |
| `setup.ps1` | Windows 同步脚本 |
| `setup.sh` | Linux/macOS 同步脚本 |
| `skills/` | 所有 Skills |
| `plugins/` | 所有 Plugins |
| `package.json` | npm 依赖（含 infra-ops-mcp） |
| `.gitignore` | Git 忽略规则 |

## 故障排除

### infra-ops-mcp 工具不可用

```powershell
# 重新安装
npm install -g github:skyvanguard/infra-ops-mcp
```

### Composio 认证失败

```bash
# 重新认证
opencode mcp auth composio
```

### Context7 文档查询失败

```bash
# 检查 CLI 版本
npx ctx7@latest --version

# 重新安装
npx ctx7 setup --opencode
```

### Firecrawl 认证失败

```bash
# 检查 API key
echo $FIRECRAWL_API_KEY

# 重新登录
firecrawl login --browser
```

### Skills 没有加载

检查 `~/.config/opencode/skills/` 目录是否存在且包含 SKILL.md 文件。

### ECC 安装问题

```bash
# 安装 ECC
npm install ecc-universal

# 或直接克隆使用
git clone https://github.com/affaan-m/ECC.git /tmp/ecc
cd /tmp/ecc && opencode
```

### Shell 配置错误

脚本会自动检测平台，如果手动修改，请确保：
- Windows 使用 `powershell`
- Linux/macOS 使用 `bash`

## Skill 市场和资源

### 在线市场

| 市场 | 地址 | 说明 |
|------|------|------|
| SkillsMP | https://skillsmp.com | 2,000,000+ skills，最大的市场 |
| Skill Store | https://skillstore.io | 精选市场，质量较高 |
| Skills.sh | https://skills.sh | Skills 目录和排行榜 |
| awesome-opencode | https://github.com/TheArchitectit/awesome-opencode-skills | 精选 skill 列表 |

### 推荐 Skills 仓库

| 仓库 | 说明 | 安装方式 |
|------|------|----------|
| [farmage/opencode-skills](https://github.com/farmage/opencode-skills) | 66个专业 skills（K8s, Terraform, Docker, SRE, 监控等） | `curl -fsSL https://raw.githubusercontent.com/farmage/opencode-skills/main/install.sh \| bash` |
| [affaan-m/ECC](https://github.com/affaan-m/ECC) | Agent harness 性能优化系统（agents, commands, skills, hooks） | `npm install ecc-universal` |
| [upstash/context7](https://github.com/upstash/context7) | 实时库文档查询 CLI | `npx ctx7 setup --opencode` |
| [firecrawl/skills](https://github.com/firecrawl/skills) | 网页爬取/搜索 skills | `npx -y firecrawl-cli@latest init --all --browser` |
| [obra/superpowers](https://github.com/obra/superpowers) | 超级能力插件（已安装） | 已配置 |

### 手动安装新 Skill

```bash
# 1. 下载 skill 到 skills 目录
git clone https://github.com/user/repo.git ~/.config/opencode/skills/skill-name

# 2. 确保 SKILL.md 存在
ls ~/.config/opencode/skills/skill-name/SKILL.md

# 3. 重启 OpenCode
```

## 故障排除

### 1. Skills 没有加载

**检查步骤：**
1. 确认目录存在：`~/.config/opencode/skills/`
2. 确认 SKILL.md 文件存在
3. 重启 OpenCode

```bash
# 验证 skills 目录
ls -la ~/.config/opencode/skills/

# 检查特定 skill
ls ~/.config/opencode/skills/ai-safety-sop/SKILL.md
```

### 2. Hookify 规则未生效

**检查步骤：**
1. 确认 hookify 规则已安装：`~/.claude/hookify/`
2. 确认文件扩展名为 `.local.md`
3. 重启 OpenCode

```bash
# 查看 hookify 规则
ls ~/.claude/hookify/*.local.md
```

### 3. 安全技能未安装

**安装步骤：**
1. 运行初始化脚本：`.\scripts\init-security.ps1`
2. 验证安装：`.\scripts\validate-security.ps1`
3. 重启 OpenCode

### 4. MCP 服务连接失败

**检查步骤：**
1. 确认网络连接正常
2. 检查 MCP 配置：`opencode.jsonc`
3. 重新认证：`opencode mcp auth composio`

### 5. 性能问题

**优化建议：**
1. 减少同时加载的 skills 数量
2. 清理未使用的 hooks
3. 更新到最新版本

```bash
# 更新 OpenCode
npm update -g opencode

# 清理缓存
opencode cache clear
```

## 相关资源

- [OpenCode 官方文档](https://opencode.ai)
- [OpenCode Skills 市场](https://skillsmp.com)
- [Context7 文档查询](https://context7.com)
- [Firecrawl 网页抓取](https://firecrawl.dev)
- [Composio 应用集成](https://composio.dev)

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个仓库。

## 许可

MIT License
