# OpenCode 配置同步仓库

## 当前已配置内容

### Skills（295个）

| 类别 | Skill | 功能 | Windows | Linux/macOS |
|------|-------|------|---------|-------------|
| 数据库 | `postgresql` | PostgreSQL 最佳实践 | ✅ | ✅ |
| | `mysql` | MySQL/MariaDB 编码标准 | ✅ | ✅ |
| | `oracle-sql` | Oracle SQL 编码标准 | ✅ | ✅ |
| | `sql-review` | SQL 审查标准 | ✅ | ✅ |
| DevOps | `kubernetes` | K8s 最佳实践 | ✅ | ✅ |
| | `ansible` | Ansible 最佳实践 | ✅ | ✅ |
| | `troubleshoot` | 故障排除 | ✅ | ⚠️ 部分 |
| 搜索 | `anysearch` | 实时搜索引擎 | ✅ | ✅ |
| 开发流程 | `brainstorming` | 创意探索 | ✅ | ✅ |
| | `writing-plans` | 编写实施计划 | ✅ | ✅ |
| | `executing-plans` | 执行实施计划 | ✅ | ✅ |
| | `test-driven-development` | TDD 工作流 | ✅ | ✅ |
| | `systematic-debugging` | 系统化调试 | ✅ | ✅ |
| | `subagent-driven-development` | 子代理开发 | ✅ | ✅ |
| 代码审查 | `receiving-code-review` | 接收代码审查反馈 | ✅ | ✅ |
| | `requesting-code-review` | 请求代码审查 | ✅ | ✅ |
| | `verification-before-completion` | 完成前验证 | ✅ | ✅ |
| Git | `using-git-worktrees` | Git worktree 管理 | ✅ | ✅ |
| | `finishing-a-development-branch` | 完成开发分支 | ✅ | ✅ |
| OpenCode | `using-superpowers` | 查找和使用 skills | ✅ | ✅ |
| | `writing-skills` | 创建/编辑 skills | ✅ | ✅ |
| | `opencode-skill-creator` | 创建/测试/评估 skills | ✅ | ✅ |
| | `dispatching-parallel-agents` | 并行任务执行 | ✅ | ✅ |
| 文档 | `context7` | 实时库文档查询 | ✅ | ✅ |
| 网络 | `firecrawl` | 网页爬取/搜索/抓取 | ✅ | ✅ |
| ECC | `api-design` | API 设计最佳实践 | ✅ | ✅ |
| | `architecture-designer` | 架构设计 | ✅ | ✅ |
| | `code-reviewer` | 代码审查 | ✅ | ✅ |
| | `security-reviewer` | 安全审查 | ✅ | ✅ |
| | `test-master` | 测试专家 | ✅ | ✅ |
| | `tdd-workflow` | TDD 工作流 | ✅ | ✅ |
| | `debugging-wizard` | 调试向导 | ✅ | ✅ |
| | `documentation-expert` | 文档专家 | ✅ | ✅ |
| DevOps | `terraform` | Terraform 最佳实践 | ✅ | ✅ |
| | `sre` | SRE 实践 | ✅ | ✅ |
| | `monitoring` | 监控实践 | ✅ | ✅ |
| | `security-review` | 安全审查 | ✅ | ✅ |
| | `docker-ci` | Docker/CI 实践 | ✅ | ✅ |
| | `cloud-architecture` | 云架构 | ✅ | ✅ |
| | `chaos-engineering` | 混沌工程 | ✅ | ✅ |
| | `embedded-systems` | 嵌入式系统 | ✅ | ✅ |

### Plugins（3个）

| Plugin | 功能 |
|--------|------|
| `openkilo` | 默认插件 |
| `opencode-skill-creator` | Skill 创建工具 |
| `./plugins/superpowers.js` | 超级能力插件（hooks） |

### MCP 服务器（3个）

| MCP | 类型 | 功能 | 说明 |
|-----|------|------|------|
| `infra-ops` | local | 92个基础设施工具 | 需要 `npm install -g github:skyvanguard/infra-ops-mcp` |
| `composio` | remote | 500+ 应用集成 | 首次使用需 OAuth 认证 |
| `context7` | remote | 实时库文档搜索 | 无需认证，免费使用 |

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
3. 测试工具：问一句"看看系统内存"

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
