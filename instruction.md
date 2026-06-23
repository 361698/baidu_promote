# baidu_promote 安装与验收指令

## 1. 开头一次性收集信息

开始安装前，先一次性问清用户需要补充的信息，不要一边输出安装结果一边继续追问下一步。这样用户能把准备工作一次做完，后续 agent 只负责执行、校验和汇总。

如果当前 agent 环境提供“反问”“表单”“request user input”之类的用户输入入口，优先用这个入口在开头一次性收集；没有这种入口时，用普通对话一次性列出问题。

需要一次性收集：

- 希望安装哪些 skill。推荐默认全装：`ku-doc-manage`、`enterprise-search`、`get-ugate-token`、`knowledge-fetch`。
- 百度 UUAP，也就是邮箱前缀，例如 `zhangsan`。
- UGate token 页面内容，或用户确认“已复制到剪贴板”。页面是 `https://uuap.baidu.com/agent/token`。如果页面没有显示 token，提醒用户先完成百度网关/SSO 登录并刷新。
- onetool 个人 Token。只有安装或验收 `knowledge-fetch` 时需要；页面是 `https://console.cloud.baidu-int.com/onetool/auth-manage/my-services`，让用户点击“复制个人 Token”。
- 如流群号。只有安装或验收 `knowledge-fetch` 时需要；如果用户没有可测群号，先跳过群聊拉取验收，并在最后说明。
- 欢迎文档里的感谢对象和推荐加入的群聊信息。用户不提供时，感谢对象可用 UUAP，群聊信息可用用户提供的如流群号。

话术可以简洁一点：

```text
我建议默认把四个都装上：ku-doc-manage、enterprise-search、get-ugate-token、knowledge-fetch。
它们配合起来很有用：可以读写 KU/如流文档、创建和编辑文档、做企业内搜、搜人搜群、把群聊历史拉到本地。比如后续要做项目资料整理、根据群聊沉淀文档、找历史资料、把结果写回 KU，这几个会连成一条完整链路。
为避免后面反复打断，我先一次性问齐：
1. 你要全部安装，还是只安装其中几个？如果你没有特别偏好，我就按全部安装处理。
2. 你的百度 UUAP 是什么？
3. 请打开 https://uuap.baidu.com/agent/token，复制页面内容；如果页面没有 token，先完成百度网关/SSO 登录并刷新。
4. 如果要安装 knowledge-fetch，请打开 https://console.cloud.baidu-int.com/onetool/auth-manage/my-services，复制个人 Token。
5. 如果要验收群聊拉取，请给一个可测试的如流群号，并确认 dodo 已在群里。
6. 欢迎文档里要感谢谁、提示加入哪个群？如果不填，我会用你的 UUAP 和上面的群号。

你可以一次性把这些信息发给我；token 也可以只复制到剪贴板后告诉我“已复制”。
```

如果用户没有明确选择，按“全部安装”执行。

## 2. 安装 skill

按当前 agent 的 skill 安装方式安装用户选择的 skill。不要把整个 `baidu_promote` 仓库作为一层 skill 安装；要把下面这些 skill 目录分别直接放进当前 agent 的 skills 目录：

- `ku-doc-manage`
- `enterprise-search`
- `get-ugate-token`
- `knowledge-fetch`

如果目标目录已经存在同名 skill，先备份同名目录，再安装新目录。安装后确认每个 skill 目录下至少有：

- `SKILL.md`

其中 `ku-doc-manage`、`enterprise-search`、`knowledge-fetch` 需要有 `route.md` 和 `experiment.md`；`get-ugate-token` 只负责缓存 token，不需要 `route.md` 或 `experiment.md`。

## 3. skill 与依赖矩阵

| skill | 用途 | 依赖 |
|---|---|---|
| `get-ugate-token` | 缓存 UGate，供其他 skill 调百度内部接口 | ① Python3；② 用户 UUAP；③ UGate token 页面内容 |
| `ku-doc-manage` | KU/如流知识库文档读取、创建、编辑、发布、删除、评论、权限、附件、表格、数据表 | ① UGate 缓存；② `SANDBOX_USERNAME`；③ KU CLI 可执行 |
| `enterprise-search` | 企业内搜、知识库搜索、搜人、搜群、会议、周报、OKR | ① Python3；② UGate 缓存；③ `SANDBOX_USERNAME` |
| `knowledge-fetch` | 拉 iCode、iCafe、iAPI、知识方舟、如流群聊历史到本地 | ① knowbase 客户端；② onetool 个人 Token；③ 目标知识源的必要参数 |

## 4. 按依赖完成打通

### ① Python3

第一步：检查当前机器是否能运行 Python3。

第二步：如果 Python3 不可用，按当前系统的常规方式安装或切换到可用的 Python3。

第三步：需要运行 Python 脚本的 skill，先用最小命令确认脚本能启动，再继续做真实请求。

### ② 用户 UUAP

第一步：询问用户百度 UUAP，也就是邮箱前缀，例如 `zhangsan`。

第二步：后续所有 KU 和企业搜索命令都在实际子进程环境里设置 `SANDBOX_USERNAME=<uuap>`。

第三步：不要只在说明里记录 UUAP，也不要只传 `--username` 后省略 `SANDBOX_USERNAME`，否则部分工具可能仍会认证失败。

### ③ UGate token 页面内容

第一步：优先使用开头一次性收集到的 UGate token 页面内容或剪贴板内容；如果缺失，再引导用户打开：

```text
https://uuap.baidu.com/agent/token
```

第二步：告诉用户如果页面没有显示 token，说明浏览器还没过百度网关/SSO，需要先完成登录，再刷新页面。

第三步：用户可以把 token 页面内容发到聊天里，也可以复制到剪贴板后告诉 agent。agent 不要复述完整 token，不要把 token 写入仓库、文档或日志摘要。

第四步：不要启动一个命令长时间等待用户输入。正确节奏是：开头先让用户打开页面并复制或发送 token，等用户回复后，再统一运行缓存动作。

第五步：使用 `get-ugate-token` 完成 UGate 缓存，并确认本机出现对应的 UGate 缓存文件。

### ④ UGate 缓存

第一步：确认本机已有当前 UUAP 的 UGate 缓存。

第二步：如果没有，回到“③ UGate token 页面内容”完成缓存。

第三步：需要 UGate 的 skill 在运行前都先确认当前命令带着正确的 `SANDBOX_USERNAME`。

### ⑤ KU CLI

第一步：确认 `ku-doc-manage` 已安装，并确认 KU CLI 可执行。

第二步：用 `ku-doc-manage` 查询当前用户信息，确认能拿到用户信息和个人知识库信息。

第三步：如果失败，先读 `ku-doc-manage/route.md`，修正路径、权限、认证或参数；可复用修正写回 `route.md`。

### ⑥ 企业搜索脚本

第一步：确认 `enterprise-search` 已安装。

第二步：用一个普通关键词跑一次知识库搜索或企业内搜，确认能返回结构化结果。

第三步：如果失败，先读 `enterprise-search/route.md`；可复用修正写回 `route.md`。

### ⑦ knowbase 客户端

第一步：检查本机是否已有 `knowbase`。如果命令不在 PATH，不要立即判定未安装；先探测用户目录下是否有完整 knowbase 安装目录，并优先用完整路径直调。

第二步：如果没有完整 knowbase，按官方安装方式安装。若安装脚本因为缺少 `wget` 失败，先补齐 `wget`，或安装完整 knowbase 目录。不要只拷贝单个 `bin/knowbase`，它运行时还依赖旁边的版本文件。

第三步：确认 `knowbase login status` 能运行，并能识别当前认证状态。

### ⑧ onetool 个人 Token

第一步：如果要拉如流群聊历史，优先使用开头一次性收集到的 onetool 个人 Token；如果缺失，再让用户打开：

```text
https://console.cloud.baidu-int.com/onetool/auth-manage/my-services
```

第二步：让用户点击“复制个人 Token”。用户可以把复制结果发到聊天里，也可以复制到剪贴板后告诉 agent；agent 不要复述完整 token，不要把 token 写入仓库、文档或日志摘要。

第三步：agent 只在当前 shell 临时设置 `COMATE_AUTH_TOKEN`，再用 knowbase 检查认证状态。

第四步：运行结束后清理当前 shell 里的 `COMATE_AUTH_TOKEN`。

### ⑨ 目标知识源的必要参数

第一步：优先使用开头一次性收集到的必要参数。例如群聊历史需要群号或可搜索到群号的线索，代码仓库需要仓库和分支，知识库文档需要 URL 或 docGuid。

第二步：如果参数能通过已安装 skill 搜到，先搜索再拉取，不要靠猜。

第三步：如果权限不足，把错误原因简洁告诉用户，并说明需要用户补充权限、加入群、添加机器人或更换 token。

## 5. 最小验收用例

做完后，请按照用户安装的 skill 选择下面测试用例。

### `get-ugate-token`

- 让用户提供 UUAP，并引导用户打开 UGate token 页面。
- 等用户复制或发送 token 后，由 agent 完成本机缓存。
- 验证当前 UUAP 的 UGate 缓存已存在。

### `ku-doc-manage`

- 在用户个人知识库创建一篇欢迎文档。标题可以是 `欢迎使用 baidu_promote` 或用户指定标题。
- 文档开头高亮感谢支持对象；感谢对象来自开头收集的信息，未提供时用用户 UUAP。
- 文档中提示用户可以加入开头收集到的如流群聊；没有群号时写“可在后续补充群聊信息”，不要编造群号。
- 下面给用户推荐一首闽南、粤语或国语老歌，并用自然、友好的方式介绍这首歌。
- 必须通过互联网搜索获取与这首老歌演唱会相关的真实图片，再插入文档；不要使用 mock 图片、本机临时生成图片或无关占位图。
- 用一个 2 列表格展示这首歌的演唱会内容：第一列是一句话介绍，第二列是互联网搜索到的演唱会图片。表格首行置灰。
- 发布后读回，确认标题、正文、文档链接、表格和真实图片都存在。

### `enterprise-search`

- 用知识库搜索检索 `hello world`，确认能搜到刚创建的测试文档或相关结果。
- 用企业内搜检索一个普通关键词，确认能返回结构化搜索结果。
- 如果用户愿意测试搜群，用一个群名或成员名线索搜索群，确认能拿到群号。

### `knowledge-fetch`

- 使用开头收集到的可测试如流群号，并确认 `dodo` 已被拉进这个群。
- 如果开头没有拿到群号，先跳过该验收项，并在最终结果中说明缺少群号。
- 使用 knowbase 拉取这个群的一段群聊历史。
- 验证本地生成知识使用说明文件和群聊 Markdown 文件；如果失败，返回明确的权限或认证错误。

## 6. 维护规则

如果读写失败是因为命令、路径、依赖、认证、参数不对，并且修正方式可复用，更新对应读写型 skill 的 `route.md`；`get-ugate-token` 这类纯缓存 skill 没有 `route.md`，直接更新 `SKILL.md` 或脚本。

如果用户指出内容性质、格式、业务风格、写作方式、表格宽度、图片插入风格、文字风格、内容长短、表格结构、覆盖/追加策略、信息编造等问题，并且经验可复用，更新对应 skill 的 `experiment.md`。`route.md` 关注命令怎么跑通，`experiment.md` 关注内容和呈现怎么符合业务要求。

不要把用户具体文档名、真实链接、真实群名、token、AK/SK 写进 `route.md` 或 `experiment.md`。需要示例时使用 mock 占位。
