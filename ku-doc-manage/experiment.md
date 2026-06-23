# ku-doc-manage experiment

## 写入模型

- KU 普通文档可用编辑器 JSON 表达，但 `markdown` 和 `json` 读取的组织方式不同。
- `query-content --protocol markdown` 的正文通常在 `result.text`。
- `query-content --protocol json` 的正文通常在 `result.content`。
- 评论不在正文 JSON 中，用 `query-comments` 单独读取。

## 创建正文

- 不要把 `create-doc --content` 当作最稳正文写入路径；自动化场景可能只创建标题或把正文落到元数据。
- 稳定流程：`create-doc --create-mode empty` -> `edit-content append` -> `publish-doc` -> `query-content` 读回。

## append / cover

- 默认用 `append`：新增小节、补充总结、追加表格、追加图片。
- 替换原文、删除内容、插入到某标题下、修改表格行，必须读 JSON 后定位，使用 `cover`。
- `cover` 前保存备份；只改目标节点；保留无关节点。
- `result.content[0]` 常是标题节点，覆盖正文时不要写入这个节点，避免标题重复出现在正文。
- `edit-content` 后必须 `publish-doc`，否则修改可能停留在草稿。
- `SANDBOX_USERNAME` 必须在实际 KU 子进程环境里设置。只传 `--username` 仍可能触发包装器认证提示或返回开放应用认证错误。
- 自动化脚本不要只看 shell 退出码；KU API 错误可能仍退出码为 0，要检查 JSON 的 `success/status/returnCode`。

## 定位策略

- 优先用标题文本、段落关键短语、表格行文本定位。
- 可结合 `blockId`，但不要只依赖一次观察到的结构。
- 写回后用 markdown 和 json 双读回，确认旧内容消失，新内容在目标位置。

## 表格

- 表格要写 KU `table` 节点，不要退化成代码块。
- `table.data.width` 控制列宽。
- 总宽建议约 `1260`；序号列 `60-90`；普通文本列 `180-320`；图片列 `520-820`。
- 表头灰底要给首行每个 `table-cell.data.backgroundColor` 写入灰色，不要以为 `headless:false` 会自动处理。

## 图片和附件

- 图片先 `upload-attachment` 到目标文档，再用目标文档自己的 `attachId` 生成图片地址。
- 图片节点的 `src` 稳定格式：`https://rte.weiyun.baidu.com/wiki/attach/image/api/imageDownloadAddress?attachId=<attachId>&docGuid=<docGuid>`。
- 跨文档搬图时不要直接复用源文档图片 URL。
- HTML demo 先截图成 PNG，再上传并作为 image 节点插入。
- HTML、Excel、PDF、ZIP 更适合附件卡片。

## 写作偏好

- 产品/需求文档要结论先行，分清“已确定”和“待讨论”。
- 不要为了像 PRD 而堆章节；只写能帮助决策的信息。
- 表格列数服务问题复杂度，能三列讲清楚就不要扩成六列。
- 不确定时写“待确认”，不要把推测写成事实。

## 安全

- 不把 UGate token、Bearer token、AK/SK、真实业务链接写入本文。
- 示例用 mock 占位。
- 用户指出可复用的格式或风格问题时，更新本文；只针对单个文档的事实不要沉淀。
