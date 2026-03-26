#!/usr/bin/env bash

set -euo pipefail

if ! command -v bk >/dev/null 2>&1; then
  echo "error: 'bk' is not installed or not in PATH" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
fixtures_dir_rel="Tests/BuildkitePipelineTests/Fixtures/YAML"
fixtures_dir="$repo_root/$fixtures_dir_rel"

if [[ ! -d "$fixtures_dir" ]]; then
  echo "error: fixtures directory not found: $fixtures_dir" >&2
  exit 1
fi

fixtures=()
while IFS= read -r fixture; do
  fixtures+=("$fixture")
done < <(
  cd "$repo_root"
  find "$fixtures_dir_rel" -type f \( -name '*.yaml' -o -name '*.yml' \) | LC_ALL=C sort
)

if (( ${#fixtures[@]} == 0 )); then
  echo "error: no YAML fixtures found in $fixtures_dir" >&2
  exit 1
fi

echo "Validating ${#fixtures[@]} pipeline fixture(s)..."

validate_args=()
for fixture in "${fixtures[@]}"; do
  validate_args+=(--file "$fixture")
done

cd "$repo_root"
bk pipeline validate "${validate_args[@]}"
