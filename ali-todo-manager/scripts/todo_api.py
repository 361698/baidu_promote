#!/usr/bin/env python3
"""Manage Todo Key Desk cloud todos."""
import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

DEFAULT_BASE_URL = "http://47.79.98.36/api/todos"
DEFAULT_KEY = "20010927"


def request(base_url, key, path="", payload=None, query=None):
    url = base_url.rstrip("/") + path
    if query:
        url += "?" + urllib.parse.urlencode(query)
    data = None
    headers = {"X-Todo-Key": key}
    method = "GET"
    if payload is not None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json; charset=utf-8"
        method = "POST"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            body = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        try:
            detail = json.loads(body).get("error") or body
        except Exception:
            detail = body
        raise SystemExit(f"API error {exc.code}: {detail}")
    except urllib.error.URLError as exc:
        raise SystemExit(f"Network error: {exc}")
    return json.loads(body) if body else {}


def summarize_todo(todo):
    marker = "×" if todo.get("hidden") else " "
    due = todo.get("dueDate") or "无日期"
    content = (todo.get("content") or "").replace("\n", " / ")
    return f"[{marker}] #{todo.get('id')} {due}  {content}"


def print_result(data, raw=False):
    if raw:
        print(json.dumps(data, ensure_ascii=False, indent=2))
        return
    if "todo" in data:
        print(summarize_todo(data["todo"]))
    if "deleted" in data:
        print(f"deleted: {data['deleted']}")
    todos = data.get("todos")
    if todos is not None:
        if not todos:
            print("No todos.")
        else:
            for todo in todos:
                print(summarize_todo(todo))


def build_parser():
    parser = argparse.ArgumentParser(description="Manage Todo Key Desk cloud todos")
    parser.add_argument("--base-url", default=os.getenv("TODO_BASE_URL", DEFAULT_BASE_URL))
    parser.add_argument("--key", default=os.getenv("TODO_KEY", DEFAULT_KEY))
    parser.add_argument("--owner-id", required=True, help="Per-user todo namespace")
    parser.add_argument("--json", action="store_true", help="Print raw JSON")
    sub = parser.add_subparsers(dest="command", required=True)
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--json", action="store_true", default=argparse.SUPPRESS, help="Print raw JSON")

    p = sub.add_parser("list", parents=[common], help="List todos")
    p.add_argument("--include-hidden", action="store_true")

    p = sub.add_parser("add", parents=[common], help="Create a todo")
    p.add_argument("--content", required=True)
    p.add_argument("--due-date", default="")

    p = sub.add_parser("update", parents=[common], help="Update content and/or date")
    p.add_argument("--todo-id", required=True, type=int)
    p.add_argument("--content")
    p.add_argument("--due-date")

    p = sub.add_parser("hide", parents=[common], help="Cross out / hide a todo")
    p.add_argument("--todo-id", required=True, type=int)

    p = sub.add_parser("restore", parents=[common], help="Restore a hidden todo")
    p.add_argument("--todo-id", required=True, type=int)

    p = sub.add_parser("delete", parents=[common], help="Permanently delete one todo")
    p.add_argument("--todo-id", required=True, type=int)

    sub.add_parser("clear-hidden", parents=[common], help="Permanently delete all hidden todos for owner")
    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    owner = args.owner_id
    if args.command == "list":
        data = request(args.base_url, args.key, query={"ownerId": owner, "includeHidden": "1" if args.include_hidden else "0"})
    elif args.command == "add":
        data = request(args.base_url, args.key, payload={"ownerId": owner, "content": args.content, "dueDate": args.due_date})
    elif args.command == "update":
        payload = {"ownerId": owner}
        if args.content is not None:
            payload["content"] = args.content
        if args.due_date is not None:
            payload["dueDate"] = args.due_date
        if len(payload) == 1:
            raise SystemExit("Nothing to update: pass --content and/or --due-date")
        data = request(args.base_url, args.key, f"/{args.todo_id}", payload=payload)
    elif args.command == "hide":
        data = request(args.base_url, args.key, f"/{args.todo_id}", payload={"ownerId": owner, "hidden": True})
    elif args.command == "restore":
        data = request(args.base_url, args.key, f"/{args.todo_id}", payload={"ownerId": owner, "hidden": False})
    elif args.command == "delete":
        data = request(args.base_url, args.key, f"/{args.todo_id}/delete", payload={"ownerId": owner})
    elif args.command == "clear-hidden":
        data = request(args.base_url, args.key, "/hidden", payload={"ownerId": owner})
    else:
        raise SystemExit("Unknown command")
    print_result(data, args.json)


if __name__ == "__main__":
    main()
