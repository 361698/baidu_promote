---
name: get-ugate-token-sandbox
description: get-ugate-token 的沙箱版说明。仅当 agent 跑在沙箱/隔离环境（每个会话 $HOME 可能变化、上次缓存的 token 读不到）时使用。token 解析、授权开关沿用主版 get-ugate-token；本目录只覆盖“如何把 token 持久化到跟随 skill 的位置，并在每次会话 hydrate 回当前 $HOME”。
---

# get-ugate-token（沙箱版）

本目录是 `get-ugate-token` 的**沙箱补丁**，不是独立技能。token 提取、`ugate token: xxx` 识别、授权开关等一律以主版 `get-ugate-token/SKILL.md` 和 `getUgateToken.py` 为准。

## 沙箱里的问题

主版 `getUgateToken.py` 把 token 写到 `Path.home()/.config/uuap/.eac_ugate_token_<uuap>`。沙箱里每个会话 `$HOME` 可能变，下个会话 `Path.home()` 指向别处就读不到，表现为“缓存过却没有 token”。

## 沙箱做法：双写 + hydrate

- **缓存时双写**：用本目录 `cache-ugate-token.sh`，把 token 同时写
  - `$SKILL_DIR/private/.eac_ugate_token_<uuap>`（跟随 skill 的持久仓库，跨会话存活）
  - `$HOME/.config/uuap/.eac_ugate_token_<uuap>`（本会话立即可用）

  ```bash
  bash "$SKILL_DIR/cache-ugate-token.sh" "<uuap>"          # 剪贴板
  bash "$SKILL_DIR/cache-ugate-token.sh" "<uuap>" --stdin  # stdin / 用户已贴出 token
  ```

  也可以继续用主版 `getUgateToken.py` 取 token，但那只写 `$HOME`；沙箱建议优先用本目录脚本以便持久化。

- **每次新会话先 hydrate**：用 `ensure-token.sh` 把 token 从持久仓库灌回当前 `$HOME`，供 KU CLI / 内搜读取。

  ```bash
  bash "$SKILL_DIR/ensure-token.sh" "<uuap>"
  ```

  解析优先级：`$UUAP_TOKEN_DIR` → `$SKILL_DIR/private/` → `$HOME/.config/uuap/`。退出码 0 = 就绪；退出码 3 = 无持久来源，需让用户重新粘贴 token 缓存。

## 红线

- 所有 token 永久有效但仍按个人身份使用，不切机器人。
- 不复述完整 token；`private/` 必须 gitignore，绝不提交。
- 不同 workspace 的 skill 目录互相隔离，`private/` 只能在同一 workspace 多次会话间复用；跨 workspace 需各自缓存一次。
