#!/usr/bin/env python3
"""Export SQL query records from a MySQL general log."""

import re
import sys
from collections import defaultdict
from pathlib import Path


LOG_RECORD = re.compile(
    r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?"
    r"(?:Z|[+-]\d{2}:\d{2})?\s+(\d+)\s+([A-Za-z]+)\s+(.*)$"
)
INTERNAL_QUERY = re.compile(
    r"^(?:select @@version_comment\b|set names\b|"
    r"set global (?:general_log|general_log_file|log_output)\b)",
    re.IGNORECASE,
)
TARGET_SCHEMA = "sales_norm_lab2"


def strip_leading_comments(query: str) -> str:
    query = query.strip()
    while query.startswith("--") or query.startswith("#") or query.startswith("/*"):
        if query.startswith("/*"):
            end = query.find("*/")
            if end == -1:
                return query
            query = query[end + 2 :].lstrip()
        else:
            newline = query.find("\n")
            if newline == -1:
                return query
            query = query[newline + 1 :].lstrip()
    return query


def is_internal_query(query: str) -> bool:
    return bool(INTERNAL_QUERY.match(strip_leading_comments(query)))


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: python sql/filter_log.py <general-log> <actions-log>",
            file=sys.stderr,
        )
        return 2

    source = Path(sys.argv[1])
    target = Path(sys.argv[2])
    entries: list[tuple[str, str, list[str]]] = []

    for line in source.read_text(encoding="utf-8-sig", errors="replace").splitlines():
        match = LOG_RECORD.match(line)
        if match:
            thread_id, command, _ = match.groups()
            entries.append((thread_id, command.lower(), [line]))
        elif entries and line.strip():
            entries[-1][2].append(line)

    kept: list[str] = []
    active_threads: set[str] = set()
    pending_database_creates: dict[str, list[list[str]]] = defaultdict(list)

    for thread_id, command, lines in entries:
        match = LOG_RECORD.match(lines[0])
        argument = match.group(3).strip() if match else ""
        normalized_query = strip_leading_comments(argument)
        if normalized_query.startswith(("--", "#", "/*")):
            continue

        if command in {"quit", "close"}:
            active_threads.discard(thread_id)
            pending_database_creates.pop(thread_id, None)
            continue

        if command not in {"query", "execute"}:
            continue

        if re.search(
            rf"\bcreate\s+database(?:\s+if\s+not\s+exists)?\s+`?{re.escape(TARGET_SCHEMA)}`?\b",
            normalized_query,
            re.IGNORECASE,
        ):
            pending_database_creates[thread_id].append(lines)
            continue

        if re.match(rf"^use\s+`?{re.escape(TARGET_SCHEMA)}`?\s*;?\s*$", normalized_query, re.IGNORECASE):
            if thread_id not in active_threads:
                for pending in pending_database_creates.pop(thread_id, []):
                    kept.extend(pending)
            active_threads.add(thread_id)
            kept.extend(lines)
            continue

        if re.match(r"^use\b", normalized_query, re.IGNORECASE):
            active_threads.discard(thread_id)
            pending_database_creates.pop(thread_id, None)
            continue

        if (
            thread_id in active_threads
            and not is_internal_query(argument)
        ):
            kept.extend(lines)

    if not kept:
        print(
            f"No SQL actions for {TARGET_SCHEMA} found in {source}",
            file=sys.stderr,
        )
        return 1

    target.write_text("\n".join(kept) + "\n", encoding="utf-8", newline="\n")
    print(f"Wrote {len(kept)} lines to {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
