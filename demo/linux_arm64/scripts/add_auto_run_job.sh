#!/bin/bash

# 获取脚本所在的目录
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 检查是否已经存在定时任务
croncmd="$script_dir/update_pool_token.sh"
cronjob="0 0 */7 * * $croncmd"

# 检查是否已经存在定时任务
if ! crontab -l | grep -q "$croncmd"; then
  # 如果不存在，则添加定时任务
  (crontab -l ; echo "$cronjob") | crontab -
  echo "定时任务已添加"
else
  echo "定时任务已存在"
fi
