# 基于pandora的ChatGpt API

## 说明

感谢[pandora](https://github.com/zhile-io/pandora)项目，这一次真正实现了ChatGPT自由。本项目主要实现了根据账号密码自动获取accessToken并更新至pool-token。初始脚本来源于旧的pandora，该库被删除，无法添加链接，这个脚本是我进行修改过后的，使用更方便。

**如果对您有帮助，请给一个免费的star，谢谢！**

## 使用方法

1. 安装python环境，我使用了`miniconda`，也可以直接下载[python](https://www.python.org/downloads/)安装。

```
# 使用scoop安装miniconda3
scoop install miniconda3
# 创建pandora专用的环境
conda create -n pool python=3.10
conda init pool
conda activate pool
```

2. 安装依赖

```
pip install pandora-chatgpt
```

3. 新建`credentials.txt`并设置内容为账号密码，一行一个，账号密码用逗号分隔

```
xxx@outlook.com,xxxxxx
xxx@outlook.com,xxxxxx
```

4. 新建`pool_token.txt`并设置内容为你的pool tohen (可选，没有会自动生成)

```
pk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

5. 打开`auto_pool_token.py`，修改以下内容

```
# 你的魔法地址
proxy = 'http://127.0.0.1:10809'

# 唯一的名字，用于注册或更新 Share Token，相同 unique_name 和 access_token 始终生成相同的 Share Token

unique_name = 'mufeng'
```

6. 运行脚本

**windows:**

执行`run_job.bat`, 如果不使用`miniconda`，请删除脚本中的 `call conda activate pool`

7. 定时执行

**windows:**

使用`任务计划程序`， 创建任务， 根据你的需求添加即可。操作选择执行脚本：`run_job.bat`