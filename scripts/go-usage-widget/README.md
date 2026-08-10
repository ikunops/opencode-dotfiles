# Go 用量 Widget

OpenCode Go 订阅 ($12/5h, $30/周, $60/月) 用量悬浮窗。

## 文件

- `go-usage-widget.py` - 后端 (pywebview + 数据收集 + 统计)
- `index.html` - 前端 (悬浮窗 UI)
- `server_data.py` - 服务器用量同步
- `start-widget.cmd` - Windows 启动脚本

## 用法

```powershell
# 启动
.\scripts\go-usage-widget\start-widget.cmd

# 或直接
python scripts\go-usage-widget\go-usage-widget.py
```

## 功能

- 5h/周/月 三窗口配额环 + 模型列表
- go 模型: 共享费用池剩余折算 (剩余次数/剩余 token, 按实际均价或官方估算)
- free 模型: 动态扫描 `opencode models` 全部免费模型, 总览显示本地历史全量
- 服务器用量同步 (需 config.json 中 auth_cookie)

## 本地运行所需文件 (不入库)

以下文件由 widget 首次运行时自动创建, 含敏感信息, **不要提交**:

- `config.json` - API key / auth_cookie / 缓存
- `server_usage.db` - 服务器用量数据
- `webdata/` `logs/` `pylib/` `.cache/` - 运行时产物
