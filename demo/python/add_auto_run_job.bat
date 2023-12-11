@echo off
chcp 65001 > nul

REM 获取当前目录的绝对路径
for %%I in ("%~dp0.") do set "currentDir=%%~fI"

set "username=%USERNAME%"
set "password="

set /p password=请输入windows登录密码（如果不需要静默执行或无密码直接按回车）：

if not "%password%"=="" (
    schtasks /create /tn "auto-update-pool-token" /tr "%currentDir%\run_job.bat" /sc weekly /d TUE /ru %username% /rp %password%
) else (
    schtasks /create /tn "auto-update-pool-token" /tr "%currentDir%\run_job.bat" /sc weekly /d TUE
)

pause
