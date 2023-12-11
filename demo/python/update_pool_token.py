# -*- coding: utf-8 -*-


import requests
import random
import string
import time
import re
import json
from os import path


def run():
    api_url = "http://127.0.0.1:8181/qqrr123123";
    unique_name = generate_random_string(10)
    expires_in = 0
    current_dir = path.dirname(path.abspath(__file__))
    credentials_file = path.join(current_dir, 'credentials.txt')
    pool_token_file = path.join(current_dir, 'pool_token.txt')
    tokens_file = path.join(current_dir, '../tokens.json')

    credentials = read_credentials(credentials_file)

    count = 0
    access_token_keys = []
    share_token_keys = []
    for index, credential in enumerate(credentials):
        # 接口有限流。
        sleep_seconds = 15
        print(f"开始休眠 {sleep_seconds} 秒...")
        time.sleep(sleep_seconds)
        print("休眠结束，继续执行后续代码。")

        username, password = credential[0].strip(), credential[1].strip()
        print('Login begin: {}, {}'.format(username, f"{index+1}/{len(credentials)}"))

        access_token = get_access_token(api_url, username, password)
        if access_token:
            access_token_keys.append(access_token)
            share_token = get_share_token(api_url, unique_name, access_token, expires_in)
            if share_token:
                share_token_keys.append(share_token)

    pool_token = read_pool_token(pool_token_file)
    update_pool_token(api_url, share_token_keys, pool_token, pool_token_file)
    # save_tokens(tokens_file, access_token_keys)


def read_credentials(credentials_file):
    with open(credentials_file, 'r', encoding='utf-8') as f:
        credentials = [line.strip().split(',', 1) for line in f if ',' in line]
    return credentials

def get_access_token(api_url, username, password):
    payload = {'username': username, 'password': password}
    resp = requests.post(api_url + '/api/auth/login', data=payload)
    if resp.status_code == 200:
        print('Login success: {}'.format(username))
        return resp.json().get('access_token')
    else:
        err_str = resp.text.replace('\n', '').replace('\r', '').strip()
        print('Login failed: {}, {}'.format(username, err_str))
        return None

def get_share_token(api_url, unique_name, access_token, expires_in):
    data = {'unique_name': unique_name, 'access_token': access_token, 'expires_in': expires_in}
    resp = requests.post(api_url + '/api/token/register', data=data)
    if resp.status_code == 200:
        share_token = resp.json().get('token_key')
        print('share token: {}'.format(share_token))
        return share_token
    else:
        err_str = resp.text.replace('\n', '').replace('\r', '').strip()
        print('share token failed: {}'.format(err_str))
        return None

def read_pool_token(pool_token_file):
    # 如果已有pool token则更新, 没有则生成。
    if path.exists(pool_token_file):
        with open(pool_token_file, 'r', encoding='utf-8') as f:
            pool_token = f.read().strip()
        if(re.compile(r'pk-[0-9a-zA-Z_\-]{43}').match(pool_token)):
            print('已存在: pool token: {}'.format(pool_token))
            return pool_token
        else:
            print('pool token: 格式不正确，将重新生成')
            return ""
    else:
        return ""

def update_pool_token(api_url, share_token_keys, pool_token, pool_token_file):
    filtered_tokens = [token for token in share_token_keys if re.match(r'fk-[0-9a-zA-Z_\-]{43}', token)]
    if not filtered_tokens:
        print('无可用账号，请检查后重试')
        return

    data = {'share_tokens': '\n'.join(filtered_tokens), 'pool_token': pool_token}
    resp = requests.post(api_url + '/api/pool/update', data=data)
    if resp.status_code == 200:
        result = resp.json()
        print('pool token 更新结果: count:{} pool_token:{}'.format(result['count'], result['pool_token']))
        with open(pool_token_file, 'w', encoding='utf-8') as f:
            f.write(result['pool_token'])
    else:
        print('pool token 更新失败')

def save_tokens(tokens_file, access_token_keys):
    tokens_data = {f"user-{i+1}": {"token": token, "shared": True, "show_user_info": False} for i, token in enumerate(access_token_keys)}
    with open(tokens_file, 'w', encoding='utf-8') as f:
        json.dump(tokens_data, f, indent=2)

def generate_random_string(length):
    letters = string.ascii_letters
    return ''.join(random.choice(letters) for _ in range(length))

if __name__ == '__main__':
    run()