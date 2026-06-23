# enterprise-search experiment

## 认证

- 所有脚本依赖 `SANDBOX_USERNAME` 或 `BAIDU_CC_USERNAME`。
- UGate 缓存文件是 `~/.config/uuap/.eac_ugate_token_<uuap>`。
- 缓存不存在时，先走 `get-ugate-token`。

## 搜索策略

- 搜索请求尽量短，保留核心实体和时间词。
- 需要详情时先搜索再 fetch，不要直接构造详情参数。
- 周报、OKR、会议等结果可能有同名人，输出前核对 `uuap`、日期、标题。
- 企业内搜摘要足够时不要强行 fetch，减少权限和接口错误。

## 群聊历史

- 搜群只拿 `gid`，不拉消息。
- 拉群聊历史需要 `knowledge-fetch` 的 `infoflow_group_message` source。
- 搜群认证用 UGate；拉历史常用 `COMATE_AUTH_TOKEN`。

## 输出风格

- 搜索结果要给出标题、来源、时间、作者/人员、可用链接或 ID。
- 不确定匹配哪个人或群时，先列候选并说明差异。
- 不要把搜索结果里的私密 token、内部凭据写入沉淀文档。
