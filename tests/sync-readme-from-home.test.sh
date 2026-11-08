#!/usr/bin/env bash
set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
target_script="${repo_root}/scripts/sync-readme-from-home.sh"

pass_count=0
fail_count=0

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [[ "${expected}" != "${actual}" ]]; then
    echo "FAIL: ${msg} (expected '${expected}', got '${actual}')" >&2
    fail_count=$((fail_count + 1))
    return 1
  else
    echo "PASS: ${msg}"
    pass_count=$((pass_count + 1))
    return 0
  fi
}

assert_file_exists() {
  local file="$1"
  local msg="$2"
  if [[ ! -f "${file}" ]]; then
    echo "FAIL: ${msg} (file '${file}' does not exist)" >&2
    fail_count=$((fail_count + 1))
    return 1
  else
    echo "PASS: ${msg}"
    pass_count=$((pass_count + 1))
    return 0
  fi
}

assert_file_content_equals() {
  local expected_file="$1"
  local actual_file="$2"
  local msg="$3"
  if ! cmp -s "${expected_file}" "${actual_file}"; then
    echo "FAIL: ${msg} ('${expected_file}' and '${actual_file}' differ)" >&2
    fail_count=$((fail_count + 1))
    return 1
  else
    echo "PASS: ${msg}"
    pass_count=$((pass_count + 1))
    return 0
  fi
}

echo "=== Running tests for scripts/sync-readme-from-home.sh ==="

# Test 1: Script exists and is executable
assert_file_exists "${target_script}" "Script exists"

# Setup temporary sandbox
sandbox_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${sandbox_dir}"
}
trap cleanup EXIT
# Mirror the script directory structure in sandbox
mkdir -p "${sandbox_dir}/scripts"
cp "${target_script}" "${sandbox_dir}/scripts/sync-readme-from-home.sh"
chmod +x "${sandbox_dir}/scripts/sync-readme-from-home.sh"

# Test 2: Error when Home.md is missing
(
  cd "${sandbox_dir}"
  rm -f Home.md README.md
  output=$(bash scripts/sync-readme-from-home.sh 2>&1)
  exit_code=$?
  assert_equals "1" "${exit_code}" "Exits with code 1 when Home.md is missing"
  if [[ "${output}" == *"Missing source file: ${sandbox_dir}/Home.md"*	]]; then
    echo "PASS: Stderr contains expected error message"
  else
    echo "FAIL: Stderr missing expected error message (got: '${output}')" >&2
    return 1
  fi
  if [[ ! -f README.md ]]; then
    echo "PASS: README.md is not created when Home.md is missing"
  else
    echo "FAIL: README.md was created when Home.md was missing" >&2
    return 1
  fi)
if [[ $? -eq 0 ]]; then
  pass_count=$((pass_count + 2))
else
  fail_count=$((fail_count + 1))
fi

# Test 3: Happy path - Home.md copied to README.md
(
  cd "${sandbox_dir}"
  echo "# Test Documentation Header" > Home.md
  echo "Some content to sync." >> Home.md
  rm -f README.md

  output=$(bash scripts/sync-readme-from-home.sh 2>&1)
  exit_code=$?

  assert_equals "0" "${exit_code}" "Exits with code 0 on successful copy"
  assert_file_exists "${sandbox_dir}/README.md" "README.md created successfully"
  assert_file_content_equals "${sandbox_dir}/Home.md" "${sandbox_dir}/README.md" "README.md matches Home.md content exactly")
if [[ $? -eq 0 ]]; then
  pass_count=$((pass_count + 3))
else
  fail_count=$((fail_count + 1))
fi

# Test 4: Overwrite - existing README.md is updated when Home.md changes
(
  cd "${sandbox_dir}"
  echo "# Old README Content" > README.md
  echo "# Updated Documentation" > Home.md
  echo "Brand new lines." >> Home.md

  output=$(bash scripts/sync-readme-from-home.sh 2>&1)
  exit_code=$?

  assert_equals "0" "${exit_code}" "Exits with code 0 on overwriting existing README.md"
  assert_file_content_equals "${sandbox_dir}/Home.md" "${sandbox_dir}/README.md" "README.md overwritten with new Home.md content")
if [[ $? -eq 0 ]]; then
  pass_count=$((pass_count + 2))
else
  fail_count=$((fail_count + 1))
fi

# Test 5: Can be executed from any working directory
(
  cd /tmp
  output=$(bash "${sandbox_dir}/scripts/sync-readme-from-home.sh" 2>&1)
  exit_code=$?

  assert_equals "0" "${exit_code}" "Exits with code 0 when invoked from external directory"
  assert_file_content_equals "${sandbox_dir}/Home.md" "${sandbox_dir}/README.md" "Sync works when called from arbitrary current working directory")
if [[ $? -eq 0 ]]; then
  pass_count=$((pass_count + 2))
else
  fail_count=$((fail_count + 1))
fi

# Test 6: Works with special characters
(
  cd "${sandbox_dir}"
  echo "special chars: * & @ # ! % ^ ( )" > Home.md

  output=$(bash scripts/sync-readme-from-home.sh 2>&1)
  exit_code=$?

  assert_equals "0" "${exit_code}" "Exits with code 0 on special characters in content"
  assert_file_content_equals "${sandbox_dir}/Home.md" "${sandbox_dir}/README.md" "Preserves special characters verbatim")
if [[ $? -eq 0 ]]; then
  pass_count=$((pass_count + 2))
else
  fail_count=$((fail_count + 1))
fi

# Test 7: Empty Home.md handling
(
  cd "${sandbox_dir}"
  : > Home.md
  rm -f README.md

  output=$(bash scripts/sync-readme-from-home.sh 2>&1)
  exit_code=$?

  assert_equals "0" "${exit_code}" "Exits with code 0 on empty Home.md"
  assert_file_exists "${sandbox_dir}/README.md" "README.md created for empty Home.md"
  assert_file_content_equals "${sandbox_dir}/Home.md" "${sandbox_dir}/README.md" "Empty README.md matches empty Home.md")
if [[ $? -eq 0 ]]; then
  pass_count=$((pass_count + 3))
else
  fail_count=$((fail_count + 1))
fi

echo "=== Test Summary ==="
echo "Passed: ${pass_count}"
echo "Failed: ${fail_count}"

if [[ ${fail_count} -gt 0 ]]; then
  false
fi
