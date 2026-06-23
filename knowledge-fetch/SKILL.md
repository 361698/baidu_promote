---
name: knowledge-fetch
description: 根据用户需求从知识源拉取知识到本地。支持iCode DeepWiki/Repository/CR、iCafe卡片、iAPI接口、GitHub仓库、如流群聊天记录、知识方舟知识、数据集等多种知识源。注意：不支持如流知识库(ku)文档，如需使用知识库(ku)文档请使用知识库相关skill。触发场景：(1)用户明确要求拉取/下载知识；(2)在知识方舟readme或配置中发现需要获取的知识链接(icode、iapi、icafe等)；(3)需要获取最新文档内容时。优先级：从知识方舟中识别到的知识优先使用此skill拉取，不要使用WebFetch等其他工具。用在`skill:knowledge-use`之前。如果icafe知识获取失败可以使用icafe-assistant技能重试，如果icode知识获取失败可以使用icode-content-fetcher技能重试。
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(knowbase *), Bash(uuidgen *)
metadata:
  version: "3.0"
---

# Auto Fetch Knowledge

根据用户需求,从各种百度内部知识源拉取知识到本地。
使用场景：当完成用户需求需要获取相关知识内容时使用此skill。用在`skill:knowledge-use`之前。

## 首要提示

- 先读 `route.md`。`route.md` 不是选择最短路径，短不短无所谓；它索引的是已经沉淀的、能够运行的常用命令，例如检查 knowbase 是否存在、检查认证、按群 ID 拉如流群聊历史、按群名或成员线索搜群后再拉取；如果里面有可直接复用的命令，优先按它执行。
- 如果运行中发现环境、路径、依赖、认证、配置字段或 source 参数问题，并形成可复用修正，一定要更新 `route.md`。
- 如果用户指出输出结构、摘要方式、取数范围、信息编造等可沉淀问题，一定要更新 `experiment.md`；只写 mock 示例，不写真实群名、仓库名、链接、token、AK/SK。

**重要说明**：
- 不支持如流知识库(ku)文档，如需使用知识库(ku)文档请使用知识库相关skill
- 如果icafe知识获取失败，可以使用icafe-assistant技能重试
- 如果icode知识获取失败，可以使用icode-content-fetcher技能重试

## 前置检查（必须）

**执行任何命令前，先检查并安装客户端：**

```bash
# 检查是否已安装
which knowbase

# 未安装则执行安装
/bin/bash -c "$(curl -fsSL http://knowbase-client.bj.bcebos.com/knowbase/install.sh)"
```

**检查认证状态：**

```bash
knowbase login status
```

knowbase 支持两种认证模式：`COMATE_AUTH_TOKEN` 环境变量 和 UGate 本地登录。

- 如果已设置 `COMATE_AUTH_TOKEN`，客户端会优先使用环境变量认证。
- 如果未设置 `COMATE_AUTH_TOKEN`，客户端会读取本地 UGate 登录态。
- 如果两种认证都不存在，先引导用户完成认证，不要继续执行知识拉取。

**个人用户使用 UGate 登录：**

```bash
# 1. 访问 https://uuap.baidu.com/agent/token 获取 UGate token
# 2. 只保留真实 JWT token，不要带 “ugate token:” 前缀及其他文字
knowbase login <username> <ugate-token>
```

常用认证命令：

```bash
knowbase login status
knowbase logout
```

## 核心工作流程

### 1. 分析用户需求

先确认认证状态：
```bash
knowbase login status
```
如果显示未登录，优先引导个人用户通过 `knowbase login <username> <ugate-token>` 登录；如果用户运行在内置 token 环境，则确认 `COMATE_AUTH_TOKEN` 已正确设置。

理解用户想要拉取什么类型的知识:
- **iCode DeepWiki** - Wiki文档
- **iCode Repository** - 百度内部代码仓库，repo中包含baidu的代码库，比如baidu/abc/hello-world
- **iCafe Card** - 需求卡片/任务
- **iAPI Doc** - API接口文档
- **GitHub Repository** - GitHub开源代码
- **Infoflow Group Message** - 如流群聊天记录
- **iCode CR** - 代码审核变更内容
- **knowledge book** - 知识方舟知识
- **iDataset** - 数据集,托管在icode或comatestack上的数据集

**注意**：不支持如流知识库(ku)文档，如需使用请使用ku-doc-manage skill

### 2. 链接解析
如果用户需求中包含链接信息, 则直接使用`knowbase download <链接>`进行知识下载。如果包含多个链接，则多次执行`knowbase download <链接>`。
支持的链接类型有：
- iCode Repository: https://console.cloud.baidu-int.com/devops/icode/repos/<repo>/tree/<branch>
- iAPI Document: https://iapi.baidu-int.com/web/project/<projectId>[/apis/<apiId>]
- iCafe Card: https://console.cloud.baidu-int.com/devops/icafe/issue/<issueId>/show
- iCafe Planbox: https://console.cloud.baidu-int.com/devops/icafe/space/<space>/planbox/<planId>/issue
- iCode CR Diff: https://console.cloud.baidu-int.com/devops/icode/repos/<repo>/reviews/<changeNumber>
- iDataset (iCode): https://console.cloud.baidu-int.com/devops/icode/datasets/<repo>/tree/<branch>[/<dirpath>]
- iDataset (iCode blob): https://console.cloud.baidu-int.com/devops/icode/datasets/<repo>/blob/<branch>/<filepath>
- iDataset (ComateStack): https://console.cloud.baidu-int.com/comatestack/app/<appname>/tree/<branch>[/<dirpath>]
- iDataset (ComateStack blob): https://console.cloud.baidu-int.com/comatestack/app/<appname>/blob/<branch>/<filepath>

**注意**：不支持如流知识库(ku)文档链接(https://ku.baidu-int.com/knowledge/xxx/xxx/<repositoryGuid>/<docGuid>)，如需使用请使用知识库相关skill

否则执行3.生成配置文件。

### 3. 生成配置文件

根据需求生成唯一命名的配置文件,遵循以下规则:

#### 配置文件命名规范

配置文件必须唯一命名,使用时间戳或描述性名称:
- `knowledge-config-{timestamp}.yaml`
- `icafe-cards-{date}.yaml`
- `repo-{project-name}.yaml`

#### 必需配置项

每个配置文件必须包含:

```yaml
version: "1.0"

meta:
  projectId: "{生成36字符UUID}"
  version: "1.0.0"
  description: "{描述用户需求}"
  owner: "{用户邮箱或从环境获取}"

storage:
  basePath: "~/knowledge"

sources:
  # 根据需求添加知识源配置

entrypoint:
  type: "rule"
```

#### UUID生成

使用bash命令生成UUID:
```bash
uuidgen | tr '[:upper:]' '[:lower:]'
```

### 4. 配置知识源

根据用户需求添加相应的知识源配置。详细配置规范见 [config-schema.md](references/config-schema.md)。

#### iCafe卡片特殊处理

当配置iCafe卡片源时:

**如果用户明确指定卡片序号**:
```yaml
- type: "icafe_card"
  enabled: true
  filters:
    - issueIds: ["dev-partner-220", "dev-partner-221"]
  output:
    needConvert: true
    fields:
      - keyPath: "title"
        description: "标题"
      - keyPath: "detail"
        description: "内容"
    format: "md"
```

**如果用户未指定卡片序号**:

1. 当前用户名: !`knowbase getuser`
2. 获取用户最近访问的空间列表: `knowbase icafe spaces $(当前用户名)`
3. 从空间列表中选择space(不用询问用户确认)
4. 根据用户需求设置其他筛选条件(status, types, startTimeDate, endTimeDate等)

示例:
```yaml
- type: "icafe_card"
  enabled: true
  filters:
    - space: "dev-partner"  # 从获取的空间列表中选择
      owner: ["zhangsan"]
      status: ["开发中", "已完成"]
      types: ["Story", "Task"]
      startTimeDate: "2026-01-01" # 开始时间,格式YYYY-MM-DD
      endTimeDate: "2026-02-04" # 结束时间,格式YYYY-MM-DD
  output:
    needConvert: true
    fields:
      - keyPath: "title"
        description: "标题"
      - keyPath: "detail"
        description: "内容"
    format: "md"
```

#### 其他知识源快速参考

**iCode DeepWiki**:
```yaml
- type: "icode_deepwiki"
  enabled: true
  filters:
    - repo: "baidu/team/project"
      branch: "master"
```

**iCode Repository**:
特别针对百度内部代码仓库，repo中包含baidu的代码库，比如baidu/abc/hello-world
```yaml
- type: "icode_repo"
  enabled: true
  filters:
    - repo: "baidu/abc/hello-world"
      branch: "master"
      depth: "1"  # 1=最近一次提交, -1=所有提交
```

**iAPI Doc**:
```yaml
- type: "iapi_doc"
  enabled: true
  filters:
    - projectId: "366675"
      apiId: ["4785904"]  # 可选,指定时忽略projectId
  output:
    exportType: "md"  # md或swagger
```

**GitHub Repository**:
```yaml
- type: "github_repo"
  enabled: true
  filters:
    - repoHttpUrl: "https://github.com/user/repo.git"
      branch: "master"
      depth: "1"
```

**Infoflow Group Message**:
```yaml
- type: "infoflow_group_message"
  enabled: true
  filters: # 知识获取筛选条件
    - groupId: "12459409" # 如流群id，必填
  output: # 知识输出内容定义
    exportType: "md"
```

**icode CR 变更**
```yaml
- type: "icode_cr_diff" #知识类型
  enabled: true # 是否启用
  filters: # 知识获取筛选条件
    - urls: [ "https://console.cloud.baidu-int.com/devops/icode/repos/baidu/xxx/xxx/reviews/xxx/*" ] # CR链接列表
  output: # 知识输出内容定义
    exportType: "md" # 接口导出形式，当前只支持md
  usage: # 使用说明
    type: "rule" # 说明类型:rule
    content: "" # rule内容
```

**知识方舟知识**
```yaml
- type: "knowledge_book" #知识类型
  enabled: true # 是否启用
  filters: # 知识获取筛选条件
    # 方式1：获取 readme（不应与 tagNames/directoryNames 同时使用）
    - knowledgebookUuid: "xxx" # 知识方舟uuid
      knowledgeType: "readme" # 指定知识类型为 readme
    # 方式2：通过标签或目录过滤
    - knowledgebookUuid: "xxx" # 知识方舟uuid
      tagNames: ["标签名称1"] # 可选
      directoryNames: ["目录名称1"] # 可选
  usage: # 使用说明
    type: "rule" # 说明类型:rule、skill
    content: "" # rule内容
```

**特别说明**：
- 当指定 `knowledgeType: "readme"` 时，系统会：
  1. 获取该知识方舟中 `knowledgeType=readme` 的知识
  2. 自动查找该知识方舟中的子知识方舟（`knowledgeType=config` 且 `knowledgeSource=knowledge_book` 的知识项）
  3. 获取所有子知识方舟中的 readme 知识
- 文件命名规则：`知识方舟名称-readme.md`（例如：`我的知识方舟-readme.md`）
- **注意**：`knowledgeType` 不应与 `tagNames` 或 `directoryNames` 同时使用

**数据集**
```yaml
- type: "idataset" #知识类型
  enabled: true # 是否启用
  filters: # 知识获取筛选条件
    - repo: "idataset/ds-xxx/xxx" # 必填，数据集repo
      branch: "master" # 必填，数据集分支
      directoryNames: ["目录1", "目录2"] # 可选，数据集目录
      commitTimeStart: "2025-07-06 17:44:58" # 可选，提交时间起点，北京时间
      commitTimeEnd: "2025-07-06 18:44:58" # 可选，提交时间终点，北京时间
  usage: # 使用说明
    type: "rule" # 说明类型:rule、skill
    content: "" # rule内容
```

### 5. 写入配置文件

将生成的配置写入唯一命名的YAML文件:
- 使用Write工具创建文件
- 推荐路径: `~/.knowledge/config-{描述}-{timestamp}.yaml`

### 6. 执行拉取命令

使用Bash工具执行knowbase命令:
```bash
knowbase -c {配置文件路径}
```

### 7. 验证结果

检查命令执行结果:
- 成功: 知识已拉取到 `~/knowledge` 目录
- 失败: 检查错误信息,可能需要调整配置

### 8. 针对用户请求下载xxx知识方舟全部知识的特殊处理

当用户请求下载某个知识方舟的全部知识时，执行以下步骤：

#### 步骤一：拉取知识方舟全部知识并检测 readme

首先拉取该知识方舟的全部知识：
```bash
knowbase -c {配置文件路径}
```

检测是否包含 readme：

拉取完成后，通过 `knowledge_usage_readme.md` 获取知识方舟名称：
```bash
# 读取 knowledge_usage_readme.md 获取知识方舟名称
cat {storage.basePath}/knowledge_usage_readme.md
```

从文件内容中提取知识方舟名称，然后检查是否存在 readme 文件：
```bash
# 检查是否存在该知识方舟的 readme 文件
ls {storage.basePath}/knowledge_book/custom/{知识方舟名称}-readme.md
```

- **如果包含 readme**：执行步骤二，解析 readme 并下载其中引用的知识
- **如果不包含 readme**：流程结束，无需执行步骤二

#### 步骤二：解析 readme，下载包含的知识

读取 readme 文件，识别其中包含的知识链接，根据以下规则处理：

**情况1：是我们支持的数据源**

（1）如果是支持的链接格式，直接用 `knowbase download` 下载：
- iCode Repository: `https://console.cloud.baidu-int.com/devops/icode/repos/<repo>/tree/<branch>`
- iAPI Document: `https://iapi.baidu-int.com/web/project/<projectId>[/apis/<apiId>]`
- iCafe Card: `https://console.cloud.baidu-int.com/devops/icafe/issue/<issueId>/show`
- iCafe Planbox: `https://console.cloud.baidu-int.com/devops/icafe/space/<space>/planbox/<planId>/issue`
- iCode CR Diff: `https://console.cloud.baidu-int.com/devops/icode/repos/<repo>/reviews/<changeNumber>`
- iDataset (iCode): `https://console.cloud.baidu-int.com/devops/icode/datasets/<repo>/tree/<branch>[/<dirpath>]`
- iDataset (ComateStack): `https://console.cloud.baidu-int.com/comatestack/app/<appname>/tree/<branch>[/<dirpath>]`

**注意**：不支持如流知识库(ku)文档链接，如需使用请使用知识库相关skill

```bash
knowbase download "https://console.cloud.baidu-int.com/devops/icode/repos/..."
knowbase download "https://console.cloud.baidu-int.com/devops/icode/datasets/..."
knowbase download "https://console.cloud.baidu-int.com/comatestack/app/..."
```

（2）如果不是链接格式（而是知识方舟内的引用，如 `[文档名称](knowledgebook:uuid:xxx)` 形式），则根据配置说明生成配置文件执行 `knowbase -c xxx.yaml` 下载。

**情况2：不是我们支持的数据源**

直接忽略，不进行下载。

#### 步骤三：完整性验证

确保所有引用的知识都已成功拉取：

```bash
# 查看最终拉取的所有文件
tree {storage.basePath} -L 3
```

**重要提示**：
- 强制要求：必须检测是否包含 readme，若包含，需要解析 readme 中的引用进行递归拉取
- readme 中可能包含iCode 仓库、iCafe 卡片等多种类型，务必全部识别并拉取
- 支持的链接类型使用 `knowbase download`，不支持的链接类型忽略
- 知识方舟内的引用需要生成配置文件拉取
- 通过 knowledge_usage_readme.md 获取知识方舟名称，确保精确定位 readme 文件
- readme 文件格式：`{知识方舟名称}-readme.md`
- 注意：不支持如流知识库(ku)文档，如需使用请使用知识库相关skill

## 配置管理

### 配置文件位置

推荐将配置文件存储在:
- `~/.knowledge/configs/` - 配置文件目录
- 或用户当前工作目录

### 多配置文件管理

同一会话中可能生成多个配置文件:
- 每个配置文件必须有唯一名称
- 执行命令时确保使用正确的配置文件路径
- 可以在配置文件名中包含描述性信息方便识别

## 完整示例

### 示例1: 拉取本周的iCafe卡片

**用户请求**: "帮我拉取本周我负责的开发中的Story"

**执行步骤**:
1. 当前用户名: !`knowbase getuser`
2. 获取用户最近访问的空间列表: `knowbase icafe spaces $(当前用户名)`
3. 生成UUID: `uuidgen | tr '[:upper:]' '[:lower:]'`
4. 创建配置文件 `~/.knowledge/icafe-current-week.yaml`:

```yaml
version: "1.0"
meta:
  projectId: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  version: "1.0.0"
  description: "拉取本周开发中的Story"
  owner: "zhangsan@baidu.com"

storage:
  basePath: "~/knowledge"

sources:
  - type: "icafe_card"
    enabled: true
    filters:
      - space: "dev-partner"
        owner: ["zhangsan"]
        status: ["开发中"]
        types: ["Story"]
        startTimeDate: "2026-01-01" # 本周开始时间
        endTimeDate: "2026-02-04" # 本周结束时间
    output:
      needConvert: true
      fields:
        - keyPath: "title"
          description: "标题"
        - keyPath: "detail"
          description: "内容"
      format: "md"

entrypoint:
  type: "rule"
```

5. 执行: `knowbase -c ~/.knowledge/icafe-current-week.yaml`

### 示例2: 拉取代码仓库

**用户请求**: "帮我拉取knowbase-client项目的代码"

**执行步骤**:
1. 生成UUID
2. 创建配置文件 `~/.knowledge/repo-knowbase-client.yaml`:

```yaml
version: "1.0"
meta:
  projectId: "b2c3d4e5-f6a7-8901-bcde-f12345678901"
  version: "1.0.0"
  description: "拉取knowbase-client代码仓库"
  owner: "user@baidu.com"

storage:
  basePath: "~/knowledge"

sources:
  - type: "icode_repo"
    enabled: true
    filters:
      - repo: "baidu/devops-ai/knowbase-client"
        branch: "master"
        depth: "1"

entrypoint:
  type: "rule"
```

3. 执行: `knowbase -c ~/.knowledge/repo-knowbase-client.yaml`

## 常见问题处理

### 认证失败或未登录

先执行：
```bash
knowbase login status
```

根据输出处理：
- `认证模式: comate (环境变量)`：当前走 `COMATE_AUTH_TOKEN`，如 token 无效需要重新设置环境变量。
- `认证模式: ugate (本地 Token)`：当前走 UGate 本地登录态。
- `认证状态: 未登录`：需要设置 `COMATE_AUTH_TOKEN` 或执行 `knowbase login <username> <ugate-token>`。

注意：只要 `COMATE_AUTH_TOKEN` 存在，就会优先使用环境变量；如需测试或使用 UGate，先执行 `unset COMATE_AUTH_TOKEN`。

### iCafe卡片查询为空

可能原因:
- 筛选条件过于严格
- 时间范围不包含符合条件的卡片
- 用户没有访问权限

解决方法:
- 放宽筛选条件
- 调整timeRange
- 确认space访问权限

### 配置文件路径问题

确保使用绝对路径或正确的相对路径:
- 推荐使用 `~/.knowledge/` 目录
- 或使用完整绝对路径

## 参考资源

完整配置规范和所有知识源类型的详细配置说明,请参考 [config-schema.md](references/config-schema.md)。
