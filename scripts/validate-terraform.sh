#!/usr/bin/env bash
# CI と同じ lockfile を使い、AWS 認証なしで全環境を検証する。
set -euo pipefail
cd "$(dirname "$0")/.."
for config in terraform/envs/*/*/terraform.tf; do
  directory="${config%/terraform.tf}"
  echo "Validating $directory"
  terraform -chdir="$directory" fmt -check -recursive -diff
  terraform -chdir="$directory" init -backend=false -input=false -lockfile=readonly
  terraform -chdir="$directory" validate -no-color
done
