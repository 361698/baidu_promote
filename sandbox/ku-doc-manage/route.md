# ku-doc-manage route（沙箱版鉴权）

本文件只覆盖沙箱环境下的**认证命令**。文档读取、创建、编辑、表格、附件、高风险操作等所有命令配方一律沿用主版 `ku-doc-manage/route.md`，本文不重复。

## 沙箱认证：每次会话先 hydrate

KU CLI 写死读 `$HOME/.config/uuap/.eac_ugate_token_<uuap>`，而沙箱里每个会话 `$HOME` 可能变。每次跑 KU/内搜前先 hydrate：

```bash
export SANDBOX_USERNAME="<uuap>"
bash "$HOME/.codex/skills/ku-doc-manage-sandbox/scripts/ensure-token.sh" "$SANDBOX_USERNAME"
```

退出码 0 = token 已在本会话就绪，可继续跑主版 route 里的命令。退出码 3 = 没有任何持久来源，去下一步重缓存。

解析优先级：`$UUAP_TOKEN_DIR` → `$SKILL_DIR/private/` → `$HOME/.config/uuap/`（最终落点）。

## 重新缓存（同时写持久仓库 + 本会话）

`ensure-token.sh` 返回 3 或真 401/403 时，用户在浏览器打开 `https://uuap.baidu.com/agent/token` 复制后：

```bash
# 剪贴板
bash "$HOME/.codex/skills/ku-doc-manage-sandbox/scripts/cache-ugate-token.sh" "<uuap>"
# stdin（沙箱读不到剪贴板，或用户已贴出 token）
bash "$HOME/.codex/skills/ku-doc-manage-sandbox/scripts/cache-ugate-token.sh" "<uuap>" --stdin
```

写完后下个新会话靠 `ensure-token.sh` 从 `private/` hydrate，不必每次重贴。

## 典型一条龙

```bash
export SANDBOX_USERNAME="<uuap>"
SK="$HOME/.codex/skills/ku-doc-manage-sandbox"
# 1) 准备 token：先 hydrate，失败再提示用户重缓存
bash "$SK/scripts/ensure-token.sh" "$SANDBOX_USERNAME" || echo "需要用户重新缓存 token"
# 2) token 就绪后，照主版 route 跑读/写命令（KU 直调主版 bin/ku）
KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"
"$KU" query-user-info --username "$SANDBOX_USERNAME"
```

## 红线

- 仍只用个人 UGate，不切数字员工 / OpenAPI / 自动降级。
- `private/` 存真 token，必须 gitignore，绝不提交、不复述完整 token。
- 创建/编辑被拒、`canUpdate=false` 是权限问题不是认证问题，别靠重做认证解决。
