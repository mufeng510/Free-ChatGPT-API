chcp 65001
@echo off
cd %~dp0
call conda activate pool
echo ------正在执行中，请等待------
python auto_pool_token.py
echo ------执行完成------
pause
exit
