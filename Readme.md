# 基于pandora的ChatGPT API

## 说明

感谢[pandora](https://github.com/zhile-io/pandora)项目，这一次真正实现了ChatGPT自由。本项目主要实现了根据账号密码自动获取accessToken并更新至pool-token。初始脚本来源于旧的pandora，该库被删除，无法添加链接，这个脚本是我进行修改过后的，使用更方便。本人也是小白一枚，欢迎大家一起补充完善。

**如果对您有帮助，请给一个免费的star，谢谢！**

## 写在前面

我们的目标是获得一个 `ChatGPT API Key`，通常是在使用`ChatGPT`的衍生项目时使用，比如[ChatGPT-Next-Web](https://github.com/Yidadaa/ChatGPT-Next-Web)、[gpt_academic](https://github.com/binary-husky/gpt_academic)等。通过使用本项目的脚本，我们将获得一个 `pk-xxxxxxx` 格式的`api key`。

### 大致流程

准备账号密码 => 获取 `Access Token` => 获取 `Share Token` => 获取 `Pool Token`

**`Pool Token` 就是我们最后需要的 `api key`。**

### 简单说明

`Access Token`是 OpenAI 官方的用户鉴权信息，相当于用户的唯一标识了，直接使用`Access Token`和使用官方key一样会扣额度，`Access Token`有效期是14天，所以我们至少要14天运行一次脚本。

`Share Token` 和 `Pool Token` 均是由 pandora 作者提供的服务，与官方无关。`Share Token`可以实现多人共享一个账号，可以进行会话隔离，不会扣除额度，实现了ChatGPT自由。但是`Share Token`依旧存在 `1` 个会话的限制，所以作者提供了 `Pool Token`，使用由最多 `100` 个`Share Token`组合的 `Pool Token` 时会自动轮转，实现了多人同时会话。

**因此，我们在使用 `api key` 时需要将反代url设置为`https://ai.fakeopen.com`**

更多信息可以查看[pandora文档](https://github.com/zhile-io/pandora/blob/master/doc/fakeopen.md)

### 文件说明

- `run_job.bat` windows执行脚本的批处理脚本
- `auto_pool_token.py` 实现功能的脚本。
- `credentials.txt` 存储账号、密码
- `tokens.txt` 存储 `Access Token`
- `share_tokens.txt` 存储 `Share Token`
- `pool_token.txt` 存储 `Pool Token`

## 使用方法

1. 安装python环境，我使用了`miniconda`，或直接下载[python](https://www.python.org/downloads/)安装并设置环境变量。

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

执行`run_job.bat`, **如果不使用`miniconda`，请删除脚本中的 `call conda activate pool`**

7. 定时执行(可选)

**windows:**

使用`任务计划程序`， 创建任务， 根据你的需求添加即可。操作选择执行脚本：`run_job.bat`