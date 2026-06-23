# 知识拉取配置规范

## 完整配置结构

```yaml
# 配置版本号，固定值
version: "1.0"

# meta配置
meta:
  projectId: "xxx" # 36字符的uuid
  version: "1.0.0" # 三位版本号
  description: "知识配置说明"
  owner: "demo@example.com"

# 知识存储配置
storage:
  basePath: "~/knowledge" # 知识拉取下来保存的目录

# 知识源配置
sources:
  - type: "..." # 知识类型
    enabled: true # 是否启用
    filters: [...] # 筛选条件
    output: {...} # 输出配置

# 知识使用说明入口文件
entrypoint:
  type: "rule" # 固定值
```

## 知识源类型配置

### 1. iCode DeepWiki

```yaml
- type: "icode_deepwiki"
  enabled: true
  filters:
    - repo: "baidu/team/my-service" # 代码库模块
      branch: "master" # 分支
```

### 2. iCode Repository
非常重要：特别针对百度内部代码仓库，repo中包含baidu的代码库，比如baidu/abc/hello-world
```yaml
- type: "icode_repo"
  enabled: true
  filters:
    - repo: "baidu/team/my-service" # 代码库模块
      branch: "master" # 分支
      depth: "1" # -1表示克隆所有提交, 1表示最近一次
```

### 3. iCafe Card

```yaml
- type: "icafe_card"
  enabled: true
  filters:
    - space: "PROJ-123" # 空间
      owner: ["zhangsan", "lisi"] # 负责人
      status: ["新建", "开发中", "已完成"] # 流程状态
      types: ["Story", "Task", "Bug"] # 类型
      keyword: "关键字" # 关键字（用户明确说了再指定）
      startTimeDate: "2026-01-01" # 开始时间,格式YYYY-MM-DD
      endTimeDate: "2026-02-04" # 结束时间,格式YYYY-MM-DD
      issueIds: ["dev-partner-220", "dev-partner-221"] # 具体的卡片序号列表
  output:
    needConvert: true
    fields: # 固定值
      - keyPath: "title" # 固定值
        description: "标题" # 固定值
      - keyPath: "detail" # 固定值
        description: "内容" # 固定值
    format: "md"
```

**状态可选值**: 全部、新建、已开始、已评审、待开发、开发中、进行中、质检中、训练中、开发完成、待测试、测试中、测试完成、已发布、已完成、已回顾、关闭

**类型可选值**: 全部、项目、Epic、Feature、Story、Task、Bug、Tech Feature、Tech Task、Bug(线上)、非研发任务、Prompt Story、Prompt Task、GenAI Data Story、GenAI Data Task、TODO

### 4. iAPI Interface

```yaml
- type: "iapi_doc"
  enabled: true
  filters:
    - projectId: "366675" # 项目id
      apiId: ["4785904"] # apiId（若指定了apiId则忽略projectId）
  output:
    exportType: "md" # 接口导出形式：md或swagger，默认是swagger
```

### 5. GitHub Repository

```yaml
- type: "github_repo"
  enabled: true
  filters:
    - repoHttpUrl: "https://github.com/username/repo.git"
      branch: "master"
      depth: "1" # -1表示克隆所有提交
```

### 6. Ku Document

```yaml
- type: "ku_doc"
  enabled: true
  filters:
    - repositoryGuid: "B8wSneaLSC" # 文档所属知识库ID
      parentDocGuid: "OQAehZAod_HVHC" # 父文档ID
      urls: [] # 文档URL列表（不为空时忽略repositoryGuid、parentDocGuid）
  output:
    exportType: "md" # 固定值
```

### 7. Infoflow Group Message

```yaml
- type: "infoflow_group_message"
  enabled: true
  filters:
    - groupId: "12459409" # 如流群id，必填
      startTimeStamp: 1770110182000 # 毫秒级时间戳，可为空，默认返回最近30天数据
      endTimeStamp: 1770110282000 # 毫秒级时间戳，可为空，默认返回最近30天数据
  output:
    exportType: "md" # 固定值
```

### 8. icode CR 变更

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

### 9. 知识方舟知识

```yaml
- type: "knowledge_book" #知识类型
  enabled: true # 是否启用
  filters: # 知识获取筛选条件
    # 方式1：通过 knowledgebookUuid + knowledgeType 获取 readme
    - knowledgebookUuid: "xxx" # 知识方舟uuid
      knowledgeType: "readme" # 指定知识类型为 readme（不应与 tagNames/directoryNames 同时使用）
    # 方式2：通过标签或目录过滤
    - knowledgebookUuid: "xxx" # 知识方舟uuid
      tagNames: ["标签名称1"] # 可选，知识方舟标签名称列表
      directoryNames: ["目录名称1"] # 可选，知识方舟目录名称列表
  usage: # 使用说明
    type: "rule" # 说明类型:rule、skill
    content: "" # rule内容
```

### 10. 数据集

```yaml
- type: "idataset" #知识类型
  enabled: true # 是否启用
  filters: # 知识获取筛选条件
    - repo: "idataset/ds-xxx/xxx" # 必填，数据集repo
      branch: "master" # 必填，数据集分支
      directoryNames: ["目录1", "目录2"] # 可选，指定目录，不指定则下载所有文件
      commitTimeStart: "2025-07-06 17:44:58" # 可选，提交时间起点，北京时间
      commitTimeEnd: "2025-07-06 18:44:58" # 可选，提交时间终点，北京时间
  usage: # 使用说明
    type: "rule" # 说明类型:rule、skill
    content: "" # rule内容
```


## 配置示例

### 示例1: 拉取iCafe卡片

```yaml
version: "1.0"
meta:
  projectId: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  version: "1.0.0"
  description: "拉取开发中的Story和Task"
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
        types: ["Story", "Task"]
        startTimeDate: "2026-01-01"
        endTimeDate: "2026-02-04"
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

### 示例2: 拉取baidu/xxx/xxx代码仓库

```yaml
version: "1.0"
meta:
  projectId: "b2c3d4e5-f6a7-8901-bcde-f12345678901"
  version: "1.0.0"
  description: "拉取项目代码仓库"
  owner: "lisi@baidu.com"

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

### 示例3: 拉取知识方舟 README

```yaml
version: "1.0"
meta:
  projectId: "c3d4e5f6-a7b8-9012-cdef-123456789012"
  version: "1.0.0"
  description: "拉取知识方舟及其子知识方舟的 README 文档"
  owner: "wangwu@baidu.com"

storage:
  basePath: "~/knowledge"

sources:
  - type: "knowledge_book"
    enabled: true
    filters:
      - knowledgebookUuid: "your-knowledge-book-uuid"
        knowledgeType: "readme"
    usage:
      type: "rule"
      content: "此配置用于获取知识方舟及其子知识方舟的 README 文档"

entrypoint:
  type: "rule"
```

**说明**：
- 此配置会自动获取主知识方舟和所有子知识方舟的 readme
- 文件保存格式：`知识方舟名称-readme.md`
- 子知识方舟会自动识别并递归获取
