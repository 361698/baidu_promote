# knowledge-fetch experiment

## 定位

- `knowledge-fetch` 拉知识到本地，不负责编辑 KU 文档。
- KU 文档读取和编辑走 `ku-doc-manage`。
- 如流群聊历史走 `infoflow_group_message`，不是如流机器人 AK/SK。

## 认证经验

- `COMATE_AUTH_TOKEN` 优先级高，适合一次性拉取任务。
- 使用环境变量时，任务结束后 `unset COMATE_AUTH_TOKEN`。
- 本地 UGate 登录适合个人长期使用，但失败时先看 `knowbase login status`。
- 官方安装脚本可能依赖 `wget`；缺失时先补依赖，不要误判为 knowbase 不可用。

## 如流群聊

- 群聊 source 需要 `groupId`，不是群名。
- 群名、人名、机器人名只是检索线索；先用 `enterprise-search` 的 `address_search.py --type group` 找 `gid`。
- 不填时间范围通常表示最近窗口；需要确定性输出时显式填毫秒时间戳。
- 常见失败是当前身份不在群、机器人不在群、token 无效或无权限。

## 输出处理

- 先打开 `knowledge_usage_readme.md` 看产物结构。
- 再读取具体 source 目录里的 Markdown。
- 汇总群聊时按时间顺序保留说话人、时间、核心结论，不要把闲聊全部复制。

## 安全

- 不把 `COMATE_AUTH_TOKEN`、UGate、AK/SK 写入配置模板或沉淀文档。
- 示例 groupId、repo、owner 全部用 mock。
