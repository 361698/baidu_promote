---
name: ali-todo-manager
description: 管理部署在阿里云 Dumate Hub 上的 Todo Key Desk 云端待办。Use when the user wants Codex to create, list, update, hide/cross out, restore, delete, or clear hidden todo items through the cloud API, including multi-line todos, due dates, owner ID scoped task data, and key-based access with X-Todo-Key.
---

# Ali Todo Manager

## Overview

Use the bundled script to manage the cloud todo store behind Todo Key Desk. The API is keyed by a shared key, but all todo data is isolated by `ownerId`; never operate without an explicit owner ID or a user-confirmed default.

Public page:

```text
http://47.79.98.36/static/todo-key-desk/index.html
```

Cloud API base:

```text
http://47.79.98.36/api/todos
```

Default key:

```text
20010927
```

## Required Inputs

- `ownerId`: user/task namespace. This is the per-user data boundary.
- `key`: use `20010927` unless the user gives a replacement. The script sends it as `X-Todo-Key`.
- `content`: required only when adding or replacing todo content. Multi-line text is supported.
- `dueDate`: optional `YYYY-MM-DD` string.

## Use the Script

Prefer `scripts/todo_api.py` for all API calls instead of hand-writing curl. It validates inputs and keeps the request shape stable.

```bash
python3 scripts/todo_api.py --owner-id pan list --include-hidden
python3 scripts/todo_api.py --owner-id pan add --content $'第一行\n第二行' --due-date 2026-07-02
python3 scripts/todo_api.py --owner-id pan hide --todo-id 12
python3 scripts/todo_api.py --owner-id pan restore --todo-id 12
python3 scripts/todo_api.py --owner-id pan update --todo-id 12 --content '改后的内容' --due-date 2026-07-03
python3 scripts/todo_api.py --owner-id pan delete --todo-id 12
python3 scripts/todo_api.py --owner-id pan clear-hidden
```

Optional flags:

- `--base-url`: override the API base, default `http://47.79.98.36/api/todos`.
- `--key`: override the access key, default reads `TODO_KEY`, then falls back to `20010927`.
- `--json`: print raw JSON instead of a readable summary.

## Behavior Rules

- Treat “叉掉” as `hide`; hidden items are excluded from the default active list.
- “恢复” maps to `restore`.
- “删除已叉掉” maps to `clear-hidden`; confirm with the user before bulk deleting if they did not explicitly ask for it.
- Direct `delete` permanently removes a single todo. Use it when the user asks to delete a specific item.
- Keep owner IDs exact. Do not normalize `pan` and `Pan` together.
- For ambiguous references such as “删掉那个”, list todos first, then choose the matching item if obvious; otherwise ask a short clarification.

## API Shape

- `GET /api/todos?ownerId=<id>&includeHidden=1` lists todos.
- `POST /api/todos` with `{ownerId, content, dueDate}` creates a todo.
- `POST /api/todos/<todoId>` with `{ownerId, content?, dueDate?, hidden?}` updates a todo.
- `POST /api/todos/<todoId>/delete` with `{ownerId}` deletes one todo.
- `POST /api/todos/hidden` with `{ownerId}` deletes all hidden todos for that owner.

All calls require header `X-Todo-Key: <key>`.
