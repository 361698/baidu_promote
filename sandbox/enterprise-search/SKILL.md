---
name: enterprise-search-sandbox
description: enterprise-search 的沙箱版鉴权说明。仅当 agent 跑在沙箱/隔离环境（如 DuMate、qianfan 桌面工作区，每个会话 $HOME 可能变化、上次缓存的 token 读不到）时使用。搜索关键词策略、输出要求、命令配方全部沿用主版 enterprise-search；本目录只覆盖“每次会话如何拿/灌 UGate token”。
---

# enterprise-search（沙箱版鉴权）

本目录是 `enterprise-search` 的**沙箱鉴权补丁**，不是独立技能。搜索策略、搜人搜群、会议/周报/OKR、输出与沉淀要求一律以主版 `enterprise-search/SKILL.md`、`route.md`、`experiment.md` 为准，本目录不重复。

## 什么时候用沙箱版

与 ku-doc-manage 沙箱版一致：会话 `$HOME` 可能变、路径含 `qianfan_desk_xdg/<workspace>` 或 `.dumate/`、上次缓存过 token 这次却读不到。`enterprise-search/scripts/auth.py` 同样写死读 `$HOME/.config/uuap/.eac_ugate_token_<uuap>`，所以同样需要每次会话先 hydrate。

## 每次会话如何拿 key（必做）

任何搜索脚本前先 hydrate：

```bash
export SANDBOX_USERNAME="<uuap>"
bash "$SKILL_DIR/scripts/ensure-token.sh" "$SANDBOX_USERNAME"
```

解析优先级：`$UUAP_TOKEN_DIR` → `$SKILL_DIR/private/` → `$HOME/.config/uuap/`（最终落点）。退出码 0 = 就绪；退出码 3 = 无持久来源，去重缓存。

## 重新缓存（同时写持久仓库 + 本会话）

```bash
bash "$SKILL_DIR/scripts/cache-ugate-token.sh" "<uuap>"          # 剪贴板
bash "$SKILL_DIR/scripts/cache-ugate-token.sh" "<uuap>" --stdin  # stdin
```

## 红线

- 只用个人 UGate，不切数字员工 / OpenAPI。
- `SANDBOX_USERNAME` 必须进到执行搜索脚本的子进程。
- 不复述完整 token；`private/` 必须 gitignore，绝不提交。
