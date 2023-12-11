chcp 65001
@echo off
cd %~dp0
echo ------正在执行中，请等待------
@REM call conda activate pool
python update_pool_token.py
echo ------执行完成------
pause
exit
