# enterprise-search route（沙箱版鉴权）

本文件只覆盖沙箱环境下的**认证命令**。知识库搜索、企业内搜、搜人搜群、会议/周报/OKR 等命令配方一律沿用主版 `enterprise-search/route.md`，本文不重复。

## 沙箱认证：每次会话先 hydrate

`auth.py` 写死读 `$HOME/.config/uuap/.eac_ugate_token_<uuap>`，沙箱里每个会话 `$HOME` 可能变。每次搜索前先 hydrate：

```bash
export SANDBOX_USERNAME="<uuap>"
bash "$HOME/.codex/skills/enterprise-search-sandbox/scripts/ensure-token.sh" "$SANDBOX_USERNAME"
```

退出码 0 = 就绪，继续按主版 route 跑搜索脚本；退出码 3 = 无持久来源，去重缓存。

解析优先级：`$UUAP_TOKEN_DIR` → `$SKILL_DIR/private/` → `$HOME/.config/uuap/`（最终落点）。

## 重新缓存（同时写持久仓库 + 本会话）

```bash
bash "$HOME/.codex/skills/enterprise-search-sandbox/scripts/cache-ugate-token.sh" "<uuap>"
bash "$HOME/.codex/skills/enterprise-search-sandbox/scripts/cache-ugate-token.sh" "<uuap>" --stdin
```

## 红线

- 只用个人 UGate，不切数字员工 / OpenAPI。
- `private/` 存真 token，必须 gitignore，绝不提交、不复述完整 token。
