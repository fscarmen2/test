#!/usr/bin/python3
# -*- coding: utf8 -*-
"""
说明: 环境变量`KOY_EB`账号密码`-`分割，多账户用&隔开[例如：aaa-bbb&ccc-ddd]
cron: 20 */6 * * *
new Env('koyeb-自动登陆');
"""
import json
import requests
import os
from sendNotify import send
import time

List = []


def login(usr, pwd):
    session = requests.Session()
    login_url = 'https://app.koyeb.com/v1/account/login'
    headers = {
    	'origin': 'https://app.koyeb.com',
        'referer': 'https://app.koyeb.com/auth/signin',
        'content-type': 'application/json',
        'user-agent': 'Mozilla/5.0 (Linux; Android 10; PBEM00) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.52 Mobile Safari/537.36'
    }
    data = {
        'email': usr,
        'password': pwd
    }
    res = session.post(login_url, headers=headers, data=json.dumps(data))
    if res.status_code == 200:
        status = res.json()
        token = status.get('token').get('id')
        check_url = 'https://app.koyeb.com/v1/account/profile'
        check_head = {
            'authorization': f'Bearer {token}',
            'referer': 'https://app.koyeb.com/auth/signin',
            'user-agent': 'Mozilla/5.0 (Linux; Android 10; PBEM00) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.52 Mobile Safari/537.36'

        }
        resp = session.get(check_url, headers=check_head)
        if resp.status_code == 200:
            info = resp.json()
            List.append(f"账号`{info.get('user').get('name')}`登陆成功")
            List.append(f"ID：{info.get('user').get('id')}")
            List.append(f"注册日期：{info.get('user').get('created_at')}")
    else:
        List.append('账号登陆失败: 账号或密码错误')


if __name__ == '__main__':
    i = 0
    if 'KOY_EB' in os.environ:
        users = os.environ['KOY_EB'].split('&')
        for x in users:
            i += 1
            name, pwd = x.split('-')
            List.append(f'===> [账号{str(i)}]Start <===')
            login(name, pwd)
            List.append(f'===> [账号{str(i)}]End <===\n')
            time.sleep(1)
        tt = '\n'.join(List)
        print(tt)
        send('koyeb', tt)
    else:
        print('未配置环境变量')
        send('koyeb', '未配置环境变量')