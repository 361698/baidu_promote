# 知识拉取 Skill 使用说明

## 概述

`knowledge-fetch` 是一个用于从知识源拉取知识到本地的 Agent Skill。支持 iCode DeepWiki/Repository/CR、iCafe 卡片、iAPI 接口、GitHub 仓库、知识方舟知识、数据集等多种知识源。用在 `skill:knowledge-use` 之前。

## 功能特性

| 功能模块 | 支持的操作 |
|------|--------|
| iCafe 卡片 | 拉取 Story、Task、Bug 等类型的卡片 |
| iCode DeepWiki | 拉取 Wiki 文档 |
| iCode Repository | 拉取百度内部代码仓库 |
| iCode CR Diff | 拉取代码评审变更内容 |
| iAPI Doc | 拉取 API 接口文档 |
| GitHub Repository | 拉取 GitHub 开源代码 |
| Infoflow Group Message | 拉取如流群聊天记录 |
| Knowledge Book | 拉取知识方舟知识 |
| iDataset | 拉取数据集文件 |

## 前置条件

### 1. 认证
当前支持两种认证方式：
- `COMATE_AUTH_TOKEN` 环境变量认证 
- UGate 本地登录认证

优先使用 `COMATE_AUTH_TOKEN`环境变量认证，未设置 `COMATE_AUTH_TOKEN` 时，才会读取本地 UGate 登录态。

#### 方式一：COMATE_AUTH_TOKEN 环境变量
需要设置 `COMATE_AUTH_TOKEN` 环境变量用于身份认证。
token 获取方式：
1. 登录 [onetool 平台](https://console.cloud.baidu-int.com/onetool/auth-manage/my-services)
2. 点击右上角的**复制个人 Token**
3. 设置 token 环境变量
```bash
export COMATE_AUTH_TOKEN="your-auth-token"
knowbase login status
```
如果认证成功，会显示：
```text
认证模式: comate (环境变量)
```

#### 方式二：UGate 本地登录
适用于个人用户。先访问以下页面获取 UGate token：
```text
https://uuap.baidu.com/agent/token
```
复制 token 后，只保留真实 JWT token，不要带 `ugate token:` 前缀及其他文字，然后执行：
```bash
knowbase login <username> <ugate-token>
knowbase login status
```
如果认证成功，会显示：
```text
认证模式: ugate (本地 Token)
```

登出本地 UGate 登录态：
```bash
knowbase logout
```

如需从 Comate 环境变量模式切换到 UGate 模式，先执行：
```bash
unset COMATE_AUTH_TOKEN
```

### 2. 客户端安装

Skill 会自动检测并安装 knowbase 客户端。如需手动安装：

```bash
/bin/bash -c "$(curl -fsSL http://knowbase-client.bj.bcebos.com/knowbase/install.sh)"
```

## 使用方法

### 触发方式

在 Ducc 中使用以下方式触发此 Skill：
- `/knowledge-fetch`
- 或在对话中描述知识拉取需求，AI 会自动识别并使用此 Skill

### 使用示例

#### 示例 1：拉取 iCafe 卡片

**用户输入：**
> 帮我拉取本周我负责的开发中的 Story

**AI 执行：**
1. 获取当前用户名
2. 获取用户最近访问的空间列表
3. 生成配置文件并执行拉取
4. 返回执行结果

#### 示例 2：拉取代码仓库

**用户输入：**
> 帮我拉取 knowbase-client 项目的代码

**AI 执行：**
1. 生成配置文件
2. 执行 `knowbase -c` 命令
3. 返回拉取结果

#### 示例 3：从链接直接下载

**用户输入：**
> 下载这个文档 https://ku.baidu-int.com/knowledge/xxx

**AI 执行：**
1. 直接使用 `knowbase download <链接>` 下载
2. 返回下载结果

## 支持的链接类型

| 知识源 | 链接格式 |
|--------|----------|
| iCode Repository | `https://console.cloud.baidu-int.com/devops/icode/repos/<repo>/tree/<branch>` |
| iAPI Document | `https://iapi.baidu-int.com/web/project/<projectId>[/apis/<apiId>]` |
| iCafe Card | `https://console.cloud.baidu-int.com/devops/icafe/issue/<issueId>/show` |
| iCafe Planbox | `https://console.cloud.baidu-int.com/devops/icafe/space/<space>/planbox/<planId>/issue` |
| iCode CR Diff | `https://console.cloud.baidu-int.com/devops/icode/repos/<repo>/reviews/<changeNumber>` |
| iDataset (iCode) | `https://console.cloud.baidu-int.com/devops/icode/datasets/<repo>/tree/<branch>[/<dirpath>]` |
| iDataset (ComateStack) | `https://console.cloud.baidu-int.com/comatestack/app/<appname>/tree/<branch>[/<dirpath>]` |

## 配置文件结构

```yaml
version: "1.0"

meta:
  projectId: "{生成36字符UUID}"
  version: "1.0.0"
  description: "{描述用户需求}"
  owner: "{用户邮箱}"

storage:
  basePath: "~/knowledge"

sources:
  # 根据需求添加知识源配置

entrypoint:
  type: "rule"
```

## 常见问题

### Q1: 如何拉取知识方舟的全部知识？

使用 knowledge-book 类型配置，通过 `tagNames` 或 `directoryNames` 过滤来获取知识方舟中的知识。

### Q2: iCafe 卡片筛选条件有哪些？

支持 space、owner、status、types、startTimeDate、endTimeDate 等筛选条件。

### Q3: 配置文件路径有什么要求？

推荐存储在 `~/.knowledge/configs/` 目录，使用绝对路径或正确的相对路径。

### Q4: 认证失败怎么办？

原因是Token 无效或过期。
先执行 `knowbase login status` 查看当前认证模式；如果是 `COMATE_AUTH_TOKEN` 模式，检查或重新设置环境变量；
如果是 UGate 模式，重新获取 token 后执行 `knowbase login <username> <ugate-token>`。

### Q5: 显示未登录怎么办？

原因是未设置 `COMATE_AUTH_TOKEN`，且本地没有有效 UGate 登录态。
使用 `export COMATE_AUTH_TOKEN="your-token"`，或访问 `https://uuap.baidu.com/agent/token` 获取 UGate token 后执行 `knowbase login <username> <ugate-token>`

### Q6: UGate 登录失败或 token 无效?

原因是复制的内容不是纯 JWT token，或 token 已过期。从 `https://uuap.baidu.com/agent/token` 重新复制 token，只保留真实 JWT token，不要带 `ugate token:` 前缀或其他说明文字。