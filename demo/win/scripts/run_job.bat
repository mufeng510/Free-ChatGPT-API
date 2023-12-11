chcp 65001
@echo off
cd %~dp0
echo ------正在执行中，请等待------
echo %~dp0
powershell %~dp0\update_pool_token.ps1
echo ------执行完成------
pause
exit
