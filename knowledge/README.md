# Knowledge Base

环境特定的知识库，需要根据实际生产环境填写。

## 目录结构

| 目录 | 内容 | 示例 |
|------|------|------|
| `architecture/` | 系统架构图、网络拓扑、服务依赖关系 | `network-topology.md`, `service-dependencies.md` |
| `runbooks/` | 运维手册、故障处理 SOP | `database-failover.md`, `disk-full.md`, `high-memory.md` |
| `deploy/` | 部署流程、回滚方案、发布规范 | `k8s-deploy.md`, `rollback-procedure.md` |
| `alert-rules/` | 告警规则、阈值配置、通知策略 | `prometheus-rules.yml`, `alertmanager-config.yml` |
| `databases/` | 数据库架构、备份策略、迁移脚本 | `mysql-schema.md`, `backup-schedule.md` |

## 使用方式

在 OpenCode 中引用知识库：

```
参考 knowledge/runbooks/database-failover.md 处理主库故障
```

## 注意

- 这些文件包含敏感信息，不要推送到公开仓库
- 建议在 `.gitignore` 中排除具体文件，只保留目录结构
- 不同环境（开发/测试/生产）应有独立的知识库
