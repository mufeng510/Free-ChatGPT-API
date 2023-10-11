# -*- coding: utf-8 -*-


from os import path

import requests

from pandora.openai.auth import Auth0

import time

import re


def run():
    proxy = 'http://127.0.0.1:10809'
    unique_name = 'mufeng'

    expires_in = 0
    current_dir = path.dirname(path.abspath(__file__))
    credentials_file = path.join(current_dir, 'credentials.txt')
    tokens_file = path.join(current_dir, 'tokens.txt')
    share_tokens_file = path.join(current_dir, 'share_tokens.txt')
    pool_token_file = path.join(current_dir, 'pool_token.txt')

    # 生成 share token。
    with open(credentials_file, 'r', encoding='utf-8') as f:
        credentials = f.read().split('\n')
    credentials = [credential.split(',', 1) for credential in credentials]

    count = 0
    token_keys = []
    for credential in credentials:
        # 接口有限流。
        sleep_seconds = 15
        print(f"开始休眠 {sleep_seconds} 秒...")
        time.sleep(sleep_seconds)
        print("休眠结束，继续执行后续代码。")
        progress = '{}/{}'.format(credentials.index(credential) + 1, len(credentials))
        if not credential or len(credential) != 2:
            continue

        count += 1
        username, password = credential[0].strip(), credential[1].strip()
        print('Login begin: {}, {}'.format(username, progress))

        token_info = {
            'token': 'None',
            'share_token': 'None',
        }
        token_keys.append(token_info)

        try:
            token_info['token'] = Auth0(username, password, proxy).auth(False)
            print('Login success: {}, {}'.format(username, progress))
        except Exception as e:
            err_str = str(e).replace('\n', '').replace('\r', '').strip()
            print('Login failed: {}, {}'.format(username, err_str))
            token_info['token'] = err_str
            continue

        data = {
            'unique_name': unique_name,
            'access_token': token_info['token'],
            'expires_in': expires_in,
        }
        resp = requests.post('https://ai.fakeopen.com/token/register', data=data)
        if resp.status_code == 200:
            token_info['share_token'] = resp.json()['token_key']
            print('share token: {}'.format(token_info['share_token']))
        else:
            err_str = resp.text.replace('\n', '').replace('\r', '').strip()
            print('share token failed: {}'.format(err_str))
            token_info['share_token'] = err_str
            continue

    with open(tokens_file, 'w', encoding='utf-8') as f:
        for token_info in token_keys:
            f.write('{}\n'.format(token_info['token']))

    with open(share_tokens_file, 'w', encoding='utf-8') as f:
        for token_info in token_keys:
            f.write('{}\n'.format(token_info['share_token']))
            
    # 生成 pool token, 如果已有pool token则更新, 没有则新建。
    with open(pool_token_file, 'r', encoding='utf-8') as f:
        pool_token = f.read()
    if(len(pool_token) == 0):
        print("当前不存在pool_token")
    else:
        if(re.compile(r'pk-[0-9a-zA-Z_\-]{43}').match(pool_token)):
            print('已存在: pool token: {}'.format(pool_token))
        else:
            print('pool token: 格式不正确，将重新生成')
            pool_token = ""

    # 从 token_keys 列表中筛选出有效数据
    filtered_tokens = [token_info['share_token'] for token_info in token_keys if re.compile(r'fk-[0-9a-zA-Z_\-]{43}').match(token_info['share_token'])]
    
    with open(pool_token_file, 'w', encoding='utf-8') as f:
        if len(filtered_tokens)==0:
            # 如果没有可用账号，则使用公共pool。
            print('可用账号，请检查后重试')
        else:
            data = {
                'share_tokens': '\n'.join(filtered_tokens),
                'pool_token': pool_token
            }
            resp = requests.post('https://ai.fakeopen.com/pool/update', data=data)
            if resp.status_code == 200:
                result = resp.json()
                print('pool token 更新结果: count:{} pool_token:{}'.format(result['count'],result['pool_token']))
                pool_token = result['pool_token']
                f.write('{}'.format(pool_token))
            else:
                print('pool token 更新失败')
        f.close()


if __name__ == '__main__':
    run()