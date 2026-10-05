#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_file="${repo_root}/Home.md"
target_file="${repo_root}/README.md"

if [[ ! -f "${source_file}" ]]; then
  echo "Missing source file: ${source_file}" >&2
  exit 1
fi

cp "${source_file}" "${target_file}"
