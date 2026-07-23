# OpenCode 配置与安全技能仓库

本仓库同步 OpenCode 的跨平台配置、技能、插件、知识库与初始化脚本。

## 仓库结构

```
opencode-dotfiles/
├─ skills/
│  ├─ platform-specific/        # 按平台分类
│  ├─ framework-specific/        # 按框架分类
│  └─ function-specific/         # 按功能域分类
├─ knowledge/
│  └─ ai-safety/                 # AI 安全专业知识库
├─ scripts/
│  ├─ classify-skills.ps1        # 技能分类脚本
│  ├─ init-security.ps1          # 初始化安全技能到本地
│  └─ validate-security.ps1      # 验证安全技能是否已安装
├─ configs/
│  └─ security/                  # 安全相关配置
├─ platforms/                    # 平台特定配置
├─ plugins/                      # 插件
├─ README.md                     # 总览
└─ QUICKSTART.md                 # 快速开始
```

## 快速开始

- Windows：`powershell -ExecutionPolicy Bypass -File .\setup.ps1`
- Linux/macOS：`bash setup.sh`

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
