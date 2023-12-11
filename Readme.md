# 基于pandora的ChatGPT API

## 说明

感谢[pandora](https://github.com/pandora-next)项目，这一次真正实现了ChatGPT自由。本项目主要实现了根据账号密码自动获取accessToken并更新至pool-token。初始脚本来源于旧的pandora，该库被删除，无法添加链接，这个脚本是我进行修改过后的，使用更方便。本人也是小白一枚，欢迎大家一起补充完善。

**如果对您有帮助，请给一个免费的star，谢谢！**

## 写在前面

我们的目标是获得一个 `ChatGPT API Key`，通常是在使用`ChatGPT`的衍生项目时使用，比如[ChatGPT-Next-Web](https://github.com/Yidadaa/ChatGPT-Next-Web)、[gpt_academic](https://github.com/binary-husky/gpt_academic)等。这些项目需要我们提供一个 `API Key` 及其对应的 `APIUrl`。

通过使用本项目的脚本，我们将获得一个 `pk-xxxxxxx` 格式的`api key`。`APIUrl`则为你部署的`PandoraNext`地址

### 大致流程

准备账号密码 => 获取 `Access Token` => 获取 `Share Token` => 获取 `Pool Token`

**`Pool Token` 就是我们最后需要的 `api key`。**

### 简单说明

`Access Token`是 OpenAI 官方的用户鉴权信息，相当于用户的唯一标识了，直接使用`Access Token`和使用官方key一样会扣额度，`Access Token`有效期是14天，所以我们至少要14天运行一次脚本。

`Share Token` 和 `Pool Token` 均是由 pandora 作者提供的服务，与官方无关。`Share Token`可以实现多人共享一个账号，可以进行会话隔离，不会扣除额度，实现了ChatGPT自由。但是`Share Token`依旧存在 `1` 个会话的限制，所以作者提供了 `Pool Token`，使用由最多 `100` 个`Share Token`组合的 `Pool Token` 时会自动轮转，实现了多人同时会话。

更多信息可以查看[pandora文档](https://github.com/zhile-io/pandora/blob/master/doc/fakeopen.md)

### 文件说明

`demo`目录下存放了各环境的示例，本项目是通过`scripts`下的文件实现功能的。

- `run_job.bat` windows执行脚本的批处理脚本
- `add_auto_run_job.bat` 添加定时任务的批处理脚本
- `update_pool_token.*` 实现功能的脚本。
- `credentials.txt` 存储账号、密码
- `pool_token.txt` 存储 `Pool Token`

## 使用方法

## 部署PandoraNext

首先你需要参考[PandoraNext文档](https://fakeopen.org/PandoraNext/)进行部署，本项目的脚本无需与PandoraNext在同一位置。如果你怕出问题，就按照demo一样，将本项目的`scripts`文件夹放在`PandoraNext`目录下。

**部署PandoraNext时，你至少应配置`config.json`中的 `bind`,`license_id`、`proxy_api_prefix`**
```
示例
{
    "bind": "0.0.0.0:8181",
    "license_id": "xxxxxxxxxxx",
    "proxy_api_prefix": "hahaha-prefix",
}
```

我们在使用 `api key` 时需要将反代url设置为`http(s)://<bind>/<proxy_api_prefix>`

如: `http://127.0.0.1:8181/hahaha-prefix`

### 自动更新pool token脚本

1. 下载[scripts](https://github.com/mufeng510/Free-ChatGPT-API/tree/master/demo/)到你本地

2. 打开`update_pool_token`文件，修改`$api_url`为`http(s)://<bind>/<proxy_api_prefix>`。

3. 新建`credentials.txt`并设置内容为账号密码，一行一个，账号密码用逗号分隔

```
xxx@outlook.com,xxxxxx
xxx@outlook.com,xxxxxx
```

4. 新建`pool_token.txt`并设置内容为你的pool tohen (可选，没有会自动生成)

```
pk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

pool tohen设置一次后就不会再变了，以后添加修改账号密码只需要执行一次脚本就行了。

5. 执行`run_job` 即可，pool tohen最后会保存到`pool_token.txt`。

<details> <summary>python额外要做的（在上述步骤之前）</summary>

1. 安装python环境

方法一：下载[python](https://www.python.org/downloads/)安装并设置环境变量。

方法二：使用`miniconda`。

- 在终端中执行：
```
# 使用scoop安装miniconda3 (没有scoop请手动安装miniconda)
scoop install miniconda3
# 创建pandora专用的环境
conda create -n pool python=3.10
conda init bash
conda activate pool
```

-  打开`run_job.bat`，在`python update_pool_token.py`之前添加`call conda activate pool`
![conda](https://github.com/mufeng510/Free-ChatGPT-API/raw/master/images/5.png)

2. 安装依赖

```
pip install pandora-chatgpt
```
</details>

## 在其他项目中使用 pool token

### [ChatGPT-Next-Web](https://github.com/Yidadaa/ChatGPT-Next-Web)

```
OPENAI_API_KEY: 'pk-xxxxxxxxxxxxxxxxxxxxxxxxxxxx'
BASE_URL: 'https://ai.fakeopen.com'
```

### [gpt_academic](https://github.com/binary-husky/gpt_academic)

```
API_KEY: 'pk-xxxxxxxxxxxxxxxxxxxxxxxxxxxx'
CUSTOM_API_KEY_PATTERN : 'pk-[a-zA-Z0-9-]+$$'
API_URL_REDIRECT : '{"https://api.openai.com/v1/chat/completions": "https://ai.fakeopen.com/v1/chat/completions"}'
```

## 定时执行

**windows:**

运行`add_auto_run_job.bat`,默认每周二执行，想修改可以发给GPT说明你的需求进行改，添加好后可以运行一次试试有没有问题。

![测试](https://github.com/mufeng510/Free-ChatGPT-API/raw/master/images/4.png)

### 共享站

PandoraNext提供了一个功能等同[chat-shared3.zhile.io](https://chat-shared3.zhile.io/)的共享站，如果你需要保存`access_token`以供共享站使用，需要做以下修改

1. 将本项目脚本放置`PandoraNext`的子目录下，如本项目demo一样

2. 打开`update_pool_token`文件，取消 `Run` 方法中的 `Save-Tokens` 的注释

3. 运行脚本