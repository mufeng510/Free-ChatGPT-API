#!/bin/bash

# 获取脚本所在的目录
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 要删除的定时任务命令
croncmd="$script_dir/update_pool_token.sh"

# 从cron中删除指定的定时任务
if crontab -l | grep -q "$croncmd"; then
  crontab -l | grep -v "$croncmd"  | crontab -
  echo "定时任务已删除"
else
  echo "定时任务不存在"
fi
