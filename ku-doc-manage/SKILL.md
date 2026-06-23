---
name: ku-doc-manage
description: 如流知识库（ku.baidu-int.com）是用户所在公司统一的文档与知识管理平台。用户提到“ku”、“知识库”、“wiki”、“文档”、“表格”、“数据表”，或提供含ku.baidu-int.com、https://ku.baidu-int.com/的url链接时，优先使用本技能；凡是写入、创建、编辑、覆盖、追加或发布 KU 文档正文，必须在开始研究、起草或调用接口前读取本技能正文和 experiment.md，再按 route.md 选择命令。提供29个能力，覆盖文档与数据表的增删改查、权限管理、评论/浏览记录、在线表格导入导出 Excel 等。
---

# 知识库文档与数据表管理 Skill

操作知识库文档与数据表，基于知识库 OpenAPI 官方文档开发，提供 29 个核心能力，覆盖文档管理、权限控制、互动数据、表格导入导出、数据表管理等场景。

## 首要提示

- 写入、创建、编辑、覆盖、追加或发布 KU 文档正文前，先完整读取 `experiment.md`，再开始研究、列大纲、起草内容或调用接口。`experiment.md` 负责内容结构、呈现、写作和验证约束；不能只读本文件或 `route.md` 就直接写正文。
- 写入完成前，再对照 `experiment.md` 开头“特别提示”和“验证与沉淀”复核一次。结构超限、应有表格但没有表格、正文 JSON 为空、内容落在标题节点或隐藏内容里，都不是完成态，必须修正后再发布。
- 再读 `route.md`。`route.md` 不是选择最短路径，短不短无所谓；它索引的是已经沉淀的、能够运行的常用命令，例如读取 Markdown/JSON、查评论、查子文档、创建文档、追加内容、上传附件、插入图片和高风险操作确认；如果里面有可直接复用的命令，优先按它执行。
- 如果运行中发现环境、路径、依赖、认证或参数问题，并形成可复用修正，一定要更新 `route.md`。
- 如果用户指出内容性质、格式、业务风格、写作方式、表格宽度、图片插入风格、文字风格、长度、覆盖/追加策略、信息编造等可沉淀问题，一定要更新 `experiment.md`；`experiment.md` 负责沉淀内容和呈现经验，`route.md` 只负责沉淀可运行命令；只写 mock 示例，不写真实文档名、链接、token、AK/SK。


> 🔧 **安装配置（首次使用必读）**
> 首次使用前添加可执行权限：`chmod +x $SKILL_DIR/bin/ku`

## URL 解析与 ID 提取（必读）

### 普通文档 URL

**知识库 URL 格式**：`https://ku.baidu-int.com/knowledge/{path1}/{path2}/{path3}/{path4}`

| URL 段数 | 类型 | 文档ID | 知识库ID |
|---------|------|--------|----------|
| 4 段 path（文档页） | `https://ku.baidu-int.com/knowledge/A/B/C/D` | `D`（path4） | `C`（path3） |
| 3 段 path（知识库首页） | `https://ku.baidu-int.com/knowledge/A/B/C` | 无 | `C`（path3） |

### 数据表 URL

**数据表 URL 格式识别**：当 URL 包含 `tb=` 和 `type=dst` 参数时，表示数据表页面。

```
示例：https://ku.baidu-int.com/knowledge/A/B/C?tb=dstyEiJENZLcg8i9pC_viwAl8ytdFV2R&type=dst
```

**从 URL 提取数据表 ID 和 视图 ID**：
- `tb` 参数格式：`{dist-id}_{view-id}`
- `dist-id`（数据表 ID）：`tb` 参数中下划线前的部分
- `view-id`（视图 ID）：`tb` 参数中下划线后的部分（以 `viw` 开头）

**数据表 ID 提取示例**：
```
URL: https://ku.baidu-int.com/knowledge/A/B/C?tb=dstyEiJENZLcg8i9pC_viwAl8ytdFV2R&type=dst
dist-id: dstyEiJENZLcg8i9pC  (下划线前的部分)
view-id: viwAl8ytdFV2R  (下划线后的部分)
```

### 字段别名说明

| 字段 | 别名 |
|------|------|
| 文档ID | `doc_id` / `docId` / `doc_guid` / `docGuid` / `doc-id` |
| 知识库ID | `repo_id` / `repository_guid` / `repo_guid` / `repo-id` |

## 重要概念：文档即目录

知识库中**文档和目录是同一个概念**——任何文档都可以拥有子文档。当需要将新文档放入某个"目录"时，`parent_doc_guid` 填写该目录文档的 ID 即可。

## 资源类型识别（三层决策，按顺序执行）

### 第一层：URL 特征（最优先）

| URL 特征 | 类型 | 后续操作集 |
|---------|------|-----------|
| 含 `tb=` 且 `type=dst` 参数 | **数据表** | 字段/记录/视图管理命令 |
| 普通 4 段 path，无上述参数 | 文档或表格（继续第二层判断） | — |

### 第二层：用户意图关键词（URL 无法区分时）

| 用户描述中的关键词 | 类型判断 | 后续操作集 |
|-----------------|---------|-----------|
| 字段、记录、视图、数据表、datasheet | **数据表** | 数据表管理命令 |
| 表格、Excel、导入、导出、sheet | **表格** | `export-sheet` / `import-sheet` |
| 文档内容、编辑、评论、权限、浏览记录、删除文档、复制文档 | **文档** | 文档管理命令 |
| 意图不明确 | 默认 **文档**，失败后降级 | 见第三层 |

### 第三层：失败降级（仅文档↔表格之间）

- 对普通 path URL 执行文档操作时，若返回不支持或文档类型错误 → 降级尝试 `export-sheet`（表格）
- **数据表不参与降级**：数据表已由第一层 URL 精确识别，不会与文档/表格混淆


## Agent 工作流程

1. **写入前置阅读**：如果任务会写入、创建、编辑、覆盖、追加或发布 KU 文档正文，先读取 `experiment.md`，再进行研究、起草、结构设计或接口调用。仅读取、查权限、查评论、查浏览记录的任务可跳过此步。

2. **解析意图**：从用户描述中提取 URL / 文档ID / 知识库ID / 数据表ID

3. **识别资源类型**：按照 [资源类型识别](#资源类型识别) 章节的三层决策规则判断类型，
   确定后续使用文档、表格还是数据表的操作集。

4. **确定目标知识库**（写入操作需要）：
   - 用户提供了 URL → 从 URL 提取 repo-id
   - 未提供 → 自动调用 `ku query-user-info` 获取个人知识库

5. **读取 references 文档**：根据子命令读取对应的 `references/*.md`，了解参数细节和业务规则

6. **二次确认检查**（高风险操作）：
   以下操作在每次执行前**必须**使用 `AskUserQuestion` 工具向用户进行二次确认：

   | 操作 | 确认场景 | 风险提示 |
   |------|---------|---------|
   | `move-doc`（移动文档） | 任何移动操作 | 你正在移动文档，此操作可能打乱原有目录结构，且移动后无法自动恢复到原位置，请确认你已核对目标位置无误 |
   | `delete-doc`（删除文档） | 任何删除操作 | 你正在删除文档，请确认你已备份或不再需要该文档 |
   | `change-scope`（修改公开范围） | scope=public-read（公开可读）或 scope=public-edit（公开可编辑） | 你正在将文档设为公开，公开后公司全员可见，存在信息泄露风险，请确认文档不包含敏感信息 |

   **确认提示示例**：
   ```
   AskUserQuestion(questions=[
       {
           "question": "⚠️ 您即将将文档公开设置为【公开可读】，公司内部人员均可访问此文档。此操作存在信息泄露风险，是否确定继续？",
           "header": "风险确认",
           "options": [
               {"label": "确认继续", "description": "我已了解风险，继续执行操作"},
               {"label": "取消操作", "description": "放弃此次修改"}
           ],
           "multiSelect": false
       }
   ])
   ```

7. **编辑模式选择**（执行 `edit-content` 时）：默认 `mdsl` 局部编辑；用户明确"全文覆盖"用 `cover`，"追加小节"用 `append`。
   **新建文档首条正文、完整正式文档写回必须用编辑器 JSON + `cover`，不要用 `append`，也不要把 Markdown 原文当正文写入**（否则 `create-mode empty` 残留空卡片，或 Markdown 表格在 KU 中显示成 `|` 管道符纯文本）。**表格必须写完整 `table` 节点**（`data.width` 长度=列数、每个 `table-cell.data` 带 `rowspan/colspan:1`，否则 Web 端空白不渲染）。可运行配方与表格 mock 见 `route.md`。

8. **发布前复核**：执行写入或发布前，再检查 `experiment.md` 的特别提示、结构门禁、表格要求和验证要求。拟写顶级章节超过限制、适合表格的信息仍是散文、正文 JSON 只有标题/空卡片、表格不是 `table` 节点时，先改稿或改 JSON，不要发布。

9. **执行命令**：`$SKILL_DIR/bin/ku <subcommand> [options]`

10. **编辑后发布**（执行 `edit-content` 后必做）：
   编辑成功（returnCode=200）后调用 `publish-doc --doc-id <文档ID> --username <用户名>` 发布，否则其他用户在预览态看不到修改。

11. **处理结果与智能降级**：
   - 检查响应是否包含"文档类型不支持"错误
   - 从错误消息中提取真实类型（在线表格/数据表表夹/数据表）
   - 自动调用对应的导出或数据表管理命令
   - 向用户展示关键信息（如创建成功的文档 URL / 数据表记录）


## CLI 子命令速查

### 文档管理类

| 子命令 | 说明 | 必填参数 | 常用可选参数 | 详细文档 |
|--------|------|---------|------------|---------|
| `query-content` | 查询文档内容 | `--doc-id` 或 `--url`（二选一） | `--protocol`（json/markdown/html/aihtml/mdhtml，默认markdown）、`--show-doc-info`、`--version-id`（指定版本ID） | [query_content.md](./references/query_content.md) |
| `query-repo` | 查询知识库文档列表 | `--repo-id` | `--parent-doc-id`（查子目录）、`--page-num`、`--page-size`、`--order-by`、`--show-creator`、`--show-publisher` | [query_repo.md](./references/query_repo.md) |
| `create-doc` | 创建文档 | 无（默认写入个人知识库） | `--repo-id`、`--username`、`--title`、`--content`、`--md-file`（从本地文件读取）、`--parent-doc-id`、`--create-mode`（empty/content默认/copy）、`--template-doc-id`（mode=copy时必填）、`--set-top`、`--process-images`（默认true）、`--base-dir` | [create_doc.md](./references/create_doc.md) |
| `edit-content` | 编辑文档正文 | `--doc-id`、`--username` | `--editor-mode`（默认mdsl局部编辑，可选append/cover）、`--operations`（append/cover模式）、`--operation`（mdsl模式） | [edit_content.md](./references/edit_content.md)，局部编辑请参考 [mdsl_edit_agent.md](./references/mdsl_edit_agent.md) |
| `copy-doc` | 复制文档 | `--doc-id` | `--target-repo-id`（目标知识库）、`--parent-doc-id`（目标目录）、`--new-title` | [copy_doc.md](./references/copy_doc.md) |
| `move-doc` | 移动文档 | `--doc-id`、`--target-repo-id`、`--username`（默认当前用户） | `--parent-doc-id`（目标父目录）、`--adjacent-doc-id`（目标相邻文档）、`--upper`（是否移动到上方） | [move_doc.md](./references/move_doc.md) |
| `delete-doc` | 删除文档 | `--doc-id`、`--username`（默认当前用户） | — | [delete_doc.md](./references/delete_doc.md) |
| `query-version` | 查询文档历史版本列表 | `--doc-id` 或 `--url`（二选一） | `--page-num`、`--page-size` | [query_version.md](./references/query_version.md) |

### 权限管理类

| 子命令 | 说明 | 必填参数 | 常用可选参数 | 详细文档 |
|--------|------|---------|------------|---------|
| `query-permission` | 查询用户对文档的权限 | `--doc-id` + `--usernames`（逗号分隔） | — | [query_permission.md](./references/query_permission.md) |
| `add-member` | 添加文档成员 | `--doc-id` + `--usernames`（逗号分隔） | `--role`（DocReader只读默认/DocMember可编辑/DocAdmin管理员） | [add_member.md](./references/add_member.md) |
| `update-member` | 更新成员角色 | `--doc-id` + `--username` + `--role` | — | [update_member.md](./references/update_member.md) |
| `change-scope` | 修改文档公开范围 | `--doc-id` + `--scope`（public-read/public-edit/private） | — | [change_scope.md](./references/change_scope.md) |

### 互动数据 & 用户信息类

| 子命令 | 说明 | 必填参数 | 常用可选参数 | 详细文档 |
|--------|------|---------|------------|---------|
| `query-comments` | 查询文档评论（含批注） | `--doc-id` | `--page-num`、`--page-size`、`--no-bottom`（跳过底部评论）、`--no-side`（跳过划线评论） | [query_comments.md](./references/query_comments.md) |
| `create-comment` | 创建文档评论/批注 | `--doc-id`、`--username`、`--text`（或 `--content`） | `--comment-type`（side/划线评论默认/bottom/bottom-reply/side-reply）、`--reply-comment-guid`、`--root-comment-guid`、`--quote-text`（划线引用文本）、`--room-type` | [create_comment.md](./references/create_comment.md) |
| `query-recent-view` | 查询文档浏览记录 | `--doc-id` | `--begin-time`（毫秒时间戳）、`--end-time`、`--page-num`、`--page-size` | [query_recent_view.md](./references/query_recent_view.md) |
| `query-recent-doc` | 查询我最近浏览/编辑的文档 | `--action`（recent-view=最近浏览，recent-edit=最近编辑） | `--begin-time`（毫秒时间戳）、`--end-time`、`--page-num`、`--page-size`（最大20） | [query_recent_doc.md](./references/query_recent_doc.md) |
| `query-flowchart` | 导出流程图数据 | `--doc-id` | `--flowchart-id`（不传时自动从文档JSON中探查所有流程图） | [query_flowchart.md](./references/query_flowchart.md) |
| `query-user-info` | 查询用户信息（含个人知识库ID） | 无 | `--username`（不传则读取环境变量当前用户） | [query_user_info.md](./references/query_user_info.md) |

## 表格操作说明

> ⚠️ **重要限制**：本 SKILL 的表格功能**不支持直接编辑**在线表格内容。

**可用能力**：
- `export-sheet`：导出在线表格为 Excel 文件
- `import-sheet`：导入 Excel 文件为在线表格

**用户意图识别与处理**：

| 用户需求 | Agent 处理方式 |
|---------|--------------|
| **读取表格内容** / 查看表格数据 / 获取表格数据 | 直接执行 `export-sheet` 导出为 Excel，使用读取工具分析内容 |
| **编辑表格内容** / 修改表格数据 | 直接执行：`export-sheet` 导出 → Agent 编辑 → `import-sheet` 导入 |
| **创建新表格** | 直接创建 Excel 文件，然后 `import-sheet` 导入 |

### 表格导入导出类

| 子命令 | 说明 | 必填参数 | 常用可选参数 | 详细文档 |
|--------|------|---------|------------|---------|
| `export-sheet` | 导出在线表格为 Excel（用于读取内容） | `--doc-id` 或 `--url`（二选一） | — | [export_sheet.md](./references/export_sheet.md) |
| `import-sheet` | 导入 Excel 为在线表格（用于创建/更新表格） | `--repo-id` + `--file` | `--parent-doc-id`（目标目录）、`--title`（表格名称） | [import_sheet.md](./references/import_sheet.md) |

## 数据表管理说明

数据表（Datasheet）是知识库提供的在线表格功能，支持字段管理、记录管理、视图管理等完整能力。

### 数据表字段管理类

| 子命令 | 说明 | 必填参数 | 常用可选参数 | 详细文档 |
|--------|------|---------|------------|---------|
| `get-datasheet-fields` | 获取数据表字段列表 | `--dist-id` | — | [get_datasheet_fields.md](./references/get_datasheet_fields.md) |
| `add-datasheet-field` | 添加数据表字段 | `--dist-id`、`--type`、`--name` | `--property`（字段属性 JSON） | [add_datasheet_field.md](./references/add_datasheet_field.md) |
| `del-datasheet-field` | 删除数据表字段 | `--dist-id`、`--field-id` | — | [del_datasheet_field.md](./references/del_datasheet_field.md) |

### 数据表记录管理类

| 子命令 | 说明 | 必填参数 | 常用可选参数 | 详细文档 |
|--------|------|---------|------------|---------|
| `get-datasheet-records` | 获取数据表记录（支持分页、筛选、排序） | `--dist-id` | `--view-id`、`--page-num`、`--page-size`、`--max-records`、`--record-ids`、`--filter`、`--sort`、`--fields` | [get_datasheet_records.md](./references/get_datasheet_records.md) |
| `add-datasheet-records` | 添加数据表记录（支持批量） | `--dist-id`、`--view-id`、`--records` | — | [add_datasheet_record.md](./references/add_datasheet_record.md) |
| `update-datasheet-records` | 更新数据表记录（支持批量） | `--dist-id`、`--view-id`、`--records` | — | [update_datasheet_record.md](./references/update_datasheet_record.md) |
| `delete-datasheet-records` | 删除数据表记录（支持批量，最多10条） | `--dist-id`、`--record-ids` | — | [delete_datasheet_record.md](./references/delete_datasheet_record.md) |

### 数据表视图与创建类

| 子命令 | 说明 | 必填参数 | 常用可选参数 | 详细文档 |
|--------|------|---------|------------|---------|
| `get-datasheet-views` | 获取数据表视图列表 | `--dist-id` | — | [get_datasheet_views.md](./references/get_datasheet_views.md) |
| `create-datasheet` | 在数据表夹下创建新数据表 | `--doc-id`（数据表URL中的文档ID） | `--username`、`--name` | [create_datasheet.md](./references/create_datasheet.md) |

## 认证说明

**单一鉴权链路：只用本机 UGate token，不要走数字员工 / OpenAPI / 自动降级。**

KU CLI 读取本机 UGate 缓存文件：

```text
~/.config/uuap/.eac_ugate_token_<uuap>
```

`<uuap>` 取自 `SANDBOX_USERNAME`（或 `BAIDU_CC_USERNAME`）。这两个环境变量必须设在真正执行 KU 子进程的那一层 shell 里；只传 `--username` 不够，缓存文件名靠环境变量定位。读写用同一个人身份，不存在“个人读不了就切机器人”的降级——切了反而会把可写的个人身份换成只读的机器人身份，导致创建/编辑被拒。

首次使用或 token 失效时，引导用户在本机普通浏览器打开：

```text
https://uuap.baidu.com/agent/token
```

如果页面没有 `ugate token: ...`，先让用户过百度网关/SSO 再刷新。等用户明确说“已复制”或直接给出 token 后，再运行本地脚本缓存（脚本只读一次，不要让它空等剪贴板，也不要复述/落盘完整 token）：

```bash
# 用户复制到剪贴板
bash "$SKILL_DIR/scripts/cache-ugate-token.sh" "<uuap>"
# 纯终端/沙箱或用户已在聊天里贴出 token，用 stdin
bash "$SKILL_DIR/scripts/cache-ugate-token.sh" "<uuap>" --stdin
```

运行前自检（确认工具文件与缓存就绪）：

```bash
SANDBOX_USERNAME="<uuap>" bash "$SKILL_DIR/scripts/check-deps.sh"
```

正常调用示例：

```bash
export SANDBOX_USERNAME="<uuap>"
$SKILL_DIR/bin/ku query-content --doc-id WKoT7ltTnjU1oW
```

## 编辑/创建失败的排查

KU API 报错经常被误判成“认证失败”，从而错误地去切身份或重做认证。先按下表对症，**不要一遇到失败就重新认证或换数字员工**。注意很多 API 错误 shell 退出码仍是 0，要看输出 JSON 的 `success`/`status`/`returnCode`。

| 现象 | 真实原因 | 处理 |
|------|---------|------|
| 提示认证失败 / 走到认证提示，但缓存文件存在 | `SANDBOX_USERNAME` 没进到执行命令的子进程 | 在同一行 `export SANDBOX_USERNAME=<uuap>` 后再调用，别切身份、别重做认证 |
| 真 401 / 403 | 本机 UGate token 失效 | 重新缓存 token（上面的脚本），仍只用个人 UGate，不要降级到机器人 |
| 创建/编辑/发布被拒、`canUpdate=false`、无权限 | 不是认证问题，是对该知识库没写权限（多见于团队库/他人库） | 告知用户需要该库写权限；`--username` 不能提权，换库或让管理员加权限 |
| `edit-content` 成功但页面看不到改动 | 只存了草稿 | 补跑 `publish-doc --doc-id <docId> --username <uuap>` |
| 新建文档正文上方多出空白卡片 / 正文只剩标题 / Markdown 内容进了标题隐藏内容 / Markdown 表格显示成 `|` 纯文本 / 表格不渲染 | 首条正文用了 `append`，或 `create-doc --content/--md-file` 写入不稳定，或把 Markdown 原文写成段落，或 `table` 节点缺 `data` | 新建/完整文档用编辑器 JSON + `cover`；Markdown 表格必须转成完整 `table` 节点（见 `route.md`），读回 JSON 核对正文节点 |
| 404 文档不存在 | 文档已删或 ID 错 | 核对 ID/URL，勿反复重试 |
| 5xx 服务端错误 | 服务端临时故障 | 稍后再试 |

## API 详细文档索引

查看 [references/API_INDEX.md](./references/API_INDEX.md) 获取完整 API 列表。每个子命令的详细参数、响应格式、业务规则均在 `references/` 目录对应文件中。
