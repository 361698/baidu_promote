# get-ugate-token experiment

## 定位

`get-ugate-token` 只负责获取、解析、缓存 UGate token，并可辅助管理授权开关；它不负责业务数据读写。

## 传参要求

- 先问 UUAP，再让用户打开 token 页面。
- token 页面地址是 `https://uuap.baidu.com/agent/token`。
- 如果页面没显示 token，多数是浏览器还没过百度网关/SSO，让用户完成登录后刷新。
- 用户把 token 发到聊天里也可以处理，但 agent 不要复述完整 token。
- 缓存位置是 `~/.config/uuap/.eac_ugate_token_<uuap>`。
- 多用户按 UUAP 分文件，不要覆盖别人的缓存。
- 如果下游 skill 仍报未认证，先确认 `SANDBOX_USERNAME` 和缓存文件名中的 `<uuap>` 一致。

## 内容要求

本 skill 不生成业务内容。需要对用户说明时，保持简短：只说已缓存、缺少 token、token 页面未登录、缓存文件不存在等状态，不输出 token 本身。

## 常见问题

- `aigate-cli` 不存在时，policy 开关不能用，但不影响 token 缓存。
- 如果 token 已经泄露到不可信环境，建议重新获取或轮换。
- 如果用户换了 UUAP，要重新缓存，不要复用旧用户名的缓存文件。

## 验证与沉淀

- 运行后确认缓存文件存在。
- 下游 KU/企业搜索仍失败时，把可复用的缓存路径、用户名、环境变量排查经验更新到本文或 `route.md`。

## 安全边界

- route 和 experiment 中只保留 mock 示例。
- 不把 token、AK/SK、Bearer 写入仓库。
