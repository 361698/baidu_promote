# baidu-promote 安装与打通

这个仓库保留官方 skill 主体，只额外增加路由和经验层：

- `route.md`：最短命令表，先从这里找读写命令。
- `experiment.md`：可复用经验，记录格式、风格、坑位和修正策略。
- `SKILL.md`：仍是 skill 触发入口，已提示优先使用 `route.md` 和 `experiment.md`。

## 安装

把需要的 skill 文件夹复制到当前 agent 的 skills 目录：

```bash
mkdir -p "$HOME/.codex/skills"
cp -R /path/to/baidu-promote/ku-doc-manage "$HOME/.codex/skills/"
cp -R /path/to/baidu-promote/enterprise-search "$HOME/.codex/skills/"
cp -R /path/to/baidu-promote/get-ugate-token "$HOME/.codex/skills/"
cp -R /path/to/baidu-promote/knowledge-fetch "$HOME/.codex/skills/"
```

Claude Code 可把目标目录换成：

```bash
$HOME/.claude/skills
```

安装后先读每个 skill 的 `route.md`，再执行命令。

## 依赖打通

### UUAP

先询问用户百度 UUAP，也就是邮箱前缀，例如 `zhangsan`。

### UGate

`ku-doc-manage` 和 `enterprise-search` 依赖 UGate。

让用户打开：

```text
https://uuap.baidu.com/agent/token
```

如果页面没有显示 token，让用户先完成百度网关/SSO 登录，再刷新页面。用户可以把 token 页面内容发到聊天里，也可以复制后由 agent 从剪贴板读取；无论哪种方式，agent 都不要复述完整 token，不要写入仓库或文档。

引导用户时不要让命令长时间等待输入。正确节奏是：先让用户打开页面并复制或发送 token，等用户回复后，agent 再运行缓存命令。

缓存命令：

```bash
cd "$HOME/.codex/skills/get-ugate-token"
USER_MESSAGE="ugate token: <用户复制的页面内容或纯JWT>" python3 getUgateToken.py "<uuap>"
```

缓存文件位置：

```text
~/.config/uuap/.eac_ugate_token_<uuap>
```

### KU CLI

`ku-doc-manage/bin/ku` 会按平台下载真正的 KU 二进制。首次使用前：

```bash
chmod +x "$HOME/.codex/skills/ku-doc-manage/bin/ku"
```

之后所有 KU 命令都带上：

```bash
export SANDBOX_USERNAME="<uuap>"
```

### 企业搜索

企业搜索只需要 Python3、UGate 缓存和 `SANDBOX_USERNAME`：

```bash
export SANDBOX_USERNAME="<uuap>"
cd "$HOME/.codex/skills/enterprise-search"
python3 scripts/ku_search.py --word "关键词" --page 1 --page-size 10
```

### knowbase

`knowledge-fetch` 依赖 `knowbase` 客户端，用于拉 iCode、iCafe、iAPI、知识方舟、如流群聊历史等知识源。

安装：

```bash
/bin/bash -c "$(curl -fsSL http://knowbase-client.bj.bcebos.com/knowbase/install.sh)"
```

如果安装脚本因为缺少 `wget` 失败，先补齐 `wget`，或使用已安装的 knowbase 二进制。不要只拷贝单个 `bin/knowbase`，它运行时还依赖旁边的版本文件。

`knowledge-fetch` 推荐使用 `COMATE_AUTH_TOKEN`：

```text
https://console.cloud.baidu-int.com/onetool/auth-manage/my-services
```

让用户点击“复制个人 Token”，agent 在当前 shell 临时设置：

```bash
export COMATE_AUTH_TOKEN="<用户复制的Bearer token>"
knowbase login status
```

运行完成后：

```bash
unset COMATE_AUTH_TOKEN
```

## 维护规则

如果读写失败是因为命令、路径、依赖、认证、参数不对，并且修正方式可复用，更新对应 skill 的 `route.md`。

如果用户指出读写格式、写作风格、内容长短、表格结构、覆盖/追加策略、信息编造等问题，并且经验可复用，更新对应 skill 的 `experiment.md`。

不要把用户具体文档名、真实链接、真实群名、token、AK/SK 写进 `route.md` 或 `experiment.md`。需要示例时使用 mock 占位。
