# get-ugate-token route

## 获取并缓存 UGate

询问用户 UUAP：

```text
请输入你的百度 UUAP，也就是邮箱前缀，例如 zhangsan。
```

让用户打开：

```text
https://uuap.baidu.com/agent/token
```

如果页面没有显示 token，先完成百度网关/SSO 登录并刷新。

用户可以把整页内容或纯 JWT 发到聊天里。agent 运行：

```bash
cd "$HOME/.codex/skills/get-ugate-token"
USER_MESSAGE="ugate token: <用户复制的内容或纯JWT>" python3 getUgateToken.py "<uuap>"
```

检查缓存：

```bash
test -f "$HOME/.config/uuap/.eac_ugate_token_<uuap>" && echo "UGate cached"
```

读取缓存 token：

```bash
python3 "$HOME/.codex/skills/get-ugate-token/getUgateToken.py" "<uuap>"
```

强制刷新：

```bash
cd "$HOME/.codex/skills/get-ugate-token"
USER_MESSAGE="刷新ugate" python3 getUgateToken.py "<uuap>"
```

## 授权开关

这些命令依赖本机存在 `aigate-cli`：

```bash
USER_MESSAGE="开启ugate授权" python3 getUgateToken.py "<uuap>"
USER_MESSAGE="关闭ugate授权" python3 getUgateToken.py "<uuap>"
USER_MESSAGE="开启邮箱授权" python3 getUgateToken.py "<uuap>"
USER_MESSAGE="关闭邮箱授权" python3 getUgateToken.py "<uuap>"
```

## 维护

如果 token 页面文案、缓存格式、脚本输出或授权命令发生变化，更新本文件。不要写入真实 token。
