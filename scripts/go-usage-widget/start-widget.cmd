@echo off
rem Go 用量悬浮窗启动脚本 - 使用本机 pythonw 后台启动
rem 注意: 脚本路径按本仓库 checkout 位置调整
set SCRIPT_DIR=%~dp0
start "" "%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\pythonw.exe" "%SCRIPT_DIR%go-usage-widget.py"
