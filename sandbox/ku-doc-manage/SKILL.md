---
name: ku-doc-manage-sandbox
description: ku-doc-manage 的沙箱版鉴权说明。仅当 agent 跑在沙箱/隔离环境（如 DuMate、qianfan 桌面工作区，每个会话 $HOME 可能变化、上次缓存的 token 读不到）时使用。内容、写作、表格、命令配方全部沿用主版 ku-doc-manage；本目录只覆盖“每次会话如何拿/灌 UGate token”。
---

# ku-doc-manage（沙箱版鉴权）

本目录是 `ku-doc-manage` 的**沙箱鉴权补丁**，不是独立技能。除认证外的一切——URL 解析、创建/编辑/发布、表格节点、写作与结构要求、错误排查——都以主版 `ku-doc-manage/SKILL.md`、`route.md`、`experiment.md` 为准，本目录不重复。

## 什么时候用沙箱版

满足任一条就按本目录处理认证：

- agent 跑在沙箱或隔离环境，每个新会话的 `$HOME` / 工作目录可能和上次不同。
- 路径里出现 `qianfan_desk_xdg/<workspace>`、`.dumate/`、`credential-seed` 等，表明是 DuMate / 千帆桌面工作区会话。
- 上一会话明明缓存过 token，这个会话却报“没有缓存的 token / 认证失败”。

判断不了时，先按本目录的 `ensure-token.sh` 探测一次：它会打印当前解析到的来源和落点，据此决定。

## 核心问题（为什么主版不够）

KU CLI、`getUgateToken.py`、`enterprise-search/auth.py` 都**写死**读
`$HOME/.config/uuap/.eac_ugate_token_<uuap>`，路径完全由**当前进程的 `$HOME`** 决定。沙箱里每个会话 `$HOME` 可能变、可能和上次缓存不在同一文件系统，于是“缓存过却读不到”。这块二进制改不了，所以沙箱版的做法是：**把 token 存到一个跟随 skill 的持久位置，每次会话开头再 hydrate 回当前 `$HOME`**。

## 每次会话如何拿 key（必做）

每次要跑 KU / 内搜命令前，先 hydrate 一次。`<uuap>` 取自 `SANDBOX_USERNAME`。

```bash
export SANDBOX_USERNAME="<uuap>"
bash "$SKILL_DIR/scripts/ensure-token.sh" "$SANDBOX_USERNAME"
```

`ensure-token.sh` 的解析优先级（持久 → 易变）：

1. `$UUAP_TOKEN_DIR/.eac_ugate_token_<uuap>`——显式覆盖，宿主/启动脚本能设就设，最通用。
2. `$SKILL_DIR/private/.eac_ugate_token_<uuap>`——跟随 skill 目录的持久仓库，跨会话存活。
3. `$HOME/.config/uuap/.eac_ugate_token_<uuap>`——CLI 实际读取位置（hydrate 的最终落点）。

命中任一持久来源就拷进 `$HOME/.config/uuap/`，退出码 0；**全都没有时退出码 3**，这时才需要让用户重新缓存。

## 缓存 / 重新缓存 token

`ensure-token.sh` 返回 3，或 token 失效（真 401/403）时，引导用户在浏览器打开 `https://uuap.baidu.com/agent/token` 复制，确认后用沙箱版缓存脚本——它**同时写持久仓库和本会话缓存**：

```bash
# 用户复制到剪贴板
bash "$SKILL_DIR/scripts/cache-ugate-token.sh" "<uuap>"
# 纯终端 / 沙箱读不到剪贴板，或用户已贴出 token
bash "$SKILL_DIR/scripts/cache-ugate-token.sh" "<uuap>" --stdin
```

写完后下个新会话就能靠 `ensure-token.sh` 从 `private/` hydrate，不必每次都让用户重贴；只有持久仓库也丢了（如沙箱连 skill 目录都每次重建）才需重贴。

## 与主版一致的红线

- 仍是**单一鉴权链路**：只用个人 UGate，不切数字员工 / OpenAPI / 自动降级。
- `SANDBOX_USERNAME` 必须进到真正执行命令的子进程；只传 `--username` 不够。
- 不复述完整 token，不写入仓库 / 文档 / 日志。
- `private/` 存了真 token，**必须 gitignore，绝不提交**。
- 创建/编辑被拒、`canUpdate=false` 是没写权限，不是认证问题，别靠重做认证或切身份解决（详见主版「编辑/创建失败的排查」）。

## 失败处理（沙箱特有）

| 现象 | 真实原因 | 处理 |
|------|---------|------|
| 报“没有缓存的 token / 认证失败”，但你确认以前缓存过 | 本会话 `$HOME` 变了，CLI 读的目录里没有 | 先 `ensure-token.sh` hydrate；返回 3 再让用户重缓存 |
| `ensure-token.sh` 退出码 3 | 持久仓库和 `$HOME` 都没有 token | 用沙箱版 `cache-ugate-token.sh` 重新缓存 |
| hydrate 后仍认证失败 | `SANDBOX_USERNAME` 没进子进程，或用户名拼错（文件名对不上） | 同一行 export 正确 uuap 后重试；核对文件名拼写 |
| 换了工作区 / 沙箱后又读不到 | 不同 workspace 的 skill 目录互相隔离，`private/` 不互通 | 该 workspace 内重缓存一次即可，之后可复用 |
