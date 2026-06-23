# get-ugate-token experiment

## 用户引导

- 先问 UUAP，再让用户打开 token 页面。
- 如果页面没显示 token，多数是浏览器还没过百度网关/SSO。
- 用户把 token 发到聊天里也可以处理，但 agent 不要复述完整 token。
- 成功后只告诉用户已缓存，不展示 token。

## 缓存

- 缓存位置：`~/.config/uuap/.eac_ugate_token_<uuap>`。
- 缓存格式是 JSON，核心字段是 `token`。
- 多用户按 UUAP 分文件，不要覆盖别人的缓存。

## 常见问题

- `aigate-cli` 不存在时，policy 开关不能用，但不影响 token 缓存。
- 如果下游 skill 仍报未认证，先确认 `SANDBOX_USERNAME` 和缓存文件名中的 `<uuap>` 一致。
- 如果 token 已经泄露到不可信环境，建议重新获取或轮换。

## 安全

- route 和 experiment 中只保留 mock 示例。
- 不把 token、AK/SK、Bearer 写入仓库。
