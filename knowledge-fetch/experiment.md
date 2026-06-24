# knowledge-fetch experiment

## 定位

`knowledge-fetch` 是只读拉取 skill，用于把知识源拉到本地，不负责编辑 KU 文档。KU 文档读取和编辑走 `ku-doc-manage`。

## 传参要求

- 如流群聊历史走 `infoflow_group_message`，不是如流机器人 AK/SK。
- 群聊 source 需要 `groupId`，不是群名；群名、人名、机器人名只是检索线索。
- 用户只说群名时，先查本 skill 的 `index.md`（群名↔群号索引）拿群号；命中就直接用。每当通过拉取、内搜或用户告知识别到新的或有更新的“群名+群号”，追加/更新进 `index.md`，只存群名和群号。
- 用户已给群 ID 时，不强制先搜群；能校验 dodo 在群内就先校验，无法校验时可直接尝试拉取，并把权限/机器人错误解释清楚。
- 用户要求看所有相关群聊时，先用 `enterprise-search` 搜群，筛选 dodo 在群内或用户确认 dodo 在群内的群，再逐个拉取。
- 需要确定性输出时显式填毫秒时间戳；未指定时默认用上周或用户口径，不要随意扩大范围。
- `COMATE_AUTH_TOKEN` 适合一次性拉取任务；让用户打开 `https://console.cloud.baidu-int.com/onetool/auth-manage/my-services`，点击“复制个人 Token”，把复制结果发给 agent 或复制到剪贴板后告知 agent。agent 只在当前 shell 临时设置，任务结束要 `unset COMATE_AUTH_TOKEN`。
- 如果没有 onetool 个人 Token，先引导用户去上述页面获取；不要把“本地登录”写成默认兜底路径，群聊历史是否能拉取以实测认证和权限返回为准。
- 官方安装脚本可能依赖 `wget`；缺失时先补依赖，不要误判为 knowbase 不可用。

## 内容要求

- 本 skill 只读，不负责生成或改写源内容。
- 拉取完成后保留原始产物路径和文件结构。

## 输出处理

- 先打开 `knowledge_usage_readme.md` 看产物结构。
- 再读取具体 source 目录里的 Markdown。
- 常见失败是当前身份不在群、机器人不在群、token 无效或无权限；回复时说明需要把 dodo 拉进群或补齐权限。

## 验证与沉淀

- 如果 `infoflow_group_message` 的配置字段、默认时间范围、输出路径或权限错误处理发生变化，更新 `route.md`。
- 用户指出输出路径、文件结构、取数范围或权限解释不清时，把可复用规则更新到本文。

## 安全边界

- 不把 `COMATE_AUTH_TOKEN`、UGate、AK/SK 写入配置模板或沉淀文档。
- 示例 groupId、repo、owner 全部用 mock。
