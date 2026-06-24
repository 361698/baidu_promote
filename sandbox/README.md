# sandbox —— 沙箱版鉴权补丁

本目录是 `ku-doc-manage`、`enterprise-search`、`get-ugate-token` 三个鉴权相关 skill 的**沙箱版**。它们只覆盖一件事：**沙箱/隔离环境下每次会话如何拿/灌 UGate token**。其余内容（写作、表格、命令配方、搜索策略）全部沿用各自的主版，不重复、不分叉。

主版（仓库顶层的 `ku-doc-manage/` 等）保持不变。

## 为什么需要沙箱版

KU CLI、`getUgateToken.py`、`enterprise-search/auth.py` 都写死读
`$HOME/.config/uuap/.eac_ugate_token_<uuap>`，路径由当前进程的 `$HOME` 决定。
沙箱（DuMate / 千帆桌面工作区等）里每个会话 `$HOME` 可能变、可能和上次缓存不在同一文件系统，于是“缓存过却读不到”。

沙箱版的做法：把 token 存到**跟随 skill 的持久位置**（`$SKILL_DIR/private/`，或 `$UUAP_TOKEN_DIR` 覆盖），每次会话开头用 `ensure-token.sh` **hydrate 回当前 `$HOME`**；持久来源也没有时才让用户重新缓存。

## 何时用主版、何时用沙箱版

- 普通终端、HOME 稳定 → 用主版即可。
- 跑在沙箱、会话 `$HOME` 会变、上次缓存读不到 → 装对应的 `-sandbox` 目录，认证按沙箱版走，其余仍读主版。

## 维护约定

- 共享内容（写作、表格、route 配方、experiment 经验）只改主版，沙箱版不复制。
- 只有“拿/灌 token”的逻辑放在沙箱版，主版不动。
- `private/` 和任何 token 文件**绝不提交**（见仓库 `.gitignore`）。
