# OpenCode 配置同步仓库

## 当前已配置内容

### Skills（23个）

| 类别 | Skill | 功能 |
|------|-------|------|
| 数据库 | `postgresql` | PostgreSQL 最佳实践 |
| | `mysql` | MySQL/MariaDB 编码标准 |
| | `oracle-sql` | Oracle SQL 编码标准 |
| | `sql-review` | SQL 审查标准 |
| DevOps | `kubernetes` | K8s 最佳实践 |
| | `ansible` | Ansible 最佳实践 |
| | `troubleshoot` | 故障排除 |
| 搜索 | `anysearch` | 实时搜索引擎 |
| 开发流程 | `brainstorming` | 创意探索 |
| | `writing-plans` | 编写实施计划 |
| | `executing-plans` | 执行实施计划 |
| | `test-driven-development` | TDD 工作流 |
| | `systematic-debugging` | 系统化调试 |
| | `subagent-driven-development` | 子代理开发 |
| 代码审查 | `receiving-code-review` | 接收代码审查反馈 |
| | `requesting-code-review` | 请求代码审查 |
| | `verification-before-completion` | 完成前验证 |
| Git | `using-git-worktrees` | Git worktree 管理 |
| | `finishing-a-development-branch` | 完成开发分支 |
| OpenCode | `using-superpowers` | 查找和使用 skills |
| | `writing-skills` | 创建/编辑 skills |
| | `opencode-skill-creator` | 创建/测试/评估 skills |
| | `dispatching-parallel-agents` | 并行任务执行 |

### Plugins（3个）

| Plugin | 功能 |
|--------|------|
| `openkilo` | 默认插件 |
| `opencode-skill-creator` | Skill 创建工具 |
| `./plugins/superpowers.js` | 超级能力插件（hooks） |

### MCP 服务器（2个）

| MCP | 类型 | 功能 |
|-----|------|------|
| `infra-ops` | local | 92个基础设施工具（系统、网络、Docker/K8s、云服务、数据库、IaC、安全） |
| `composio` | remote | 500+ 应用集成（Gmail、GitHub、Slack 等，需 OAuth 认证） |

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

### Composio

首次使用时会弹出浏览器让你 OAuth 登录授权。

## 其他机器同步

### 前提条件

- Node.js >= 18.0.0
- OpenCode 已安装 (`npm install -g opencode-ai`)

### 一键同步

```powershell
# 方法1：运行远程脚本
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/ikunops/opencode-dotfiles/main/setup.ps1'))

# 方法2：手动操作
git clone https://github.com/ikunops/opencode-dotfiles.git C:\temp\oc-config
.\C:\temp\oc-config\setup.ps1
```

### 同步后验证

启动 OpenCode，检查：
1. Skills 是否加载：输入 `/skills` 查看
2. MCP 是否加载：运行 `opencode mcp list`
3. 测试工具：问一句"看看系统内存"

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
| `opencode.jsonc` | 主配置（MCP、plugins） |
| `tui.jsonc` | 快捷键配置 |
| `skills/` | 所有 Skills |
| `plugins/` | 所有 Plugins |
| `setup.ps1` | 一键同步脚本 |
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

### Skills 没有加载

检查 `~/.config/opencode/skills/` 目录是否存在且包含 SKILL.md 文件。
