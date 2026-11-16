#!/usr/bin/env bash
# CI と同じ lockfile を使い、AWS 認証なしで全環境を検証する。
set -euo pipefail
cd "$(dirname "$0")/.."
if (( $# )); then
  directories=("$@")
else
  directories=()
  for config in terraform/envs/*/*/terraform.tf; do
    directories+=("${config%/terraform.tf}")
  done
fi
# 対象の誤指定を全件確認してから Terraform を起動する。
for directory in "${directories[@]}"; do
  if [[ ! "$directory" =~ ^terraform/envs/[^./][^/]*/[^./][^/]*$ || ! -f "$directory/terraform.tf" ]]; then
    echo "検証対象の環境ディレクトリが不正です: $directory" >&2
    exit 2
  fi
done
# 同じ固定版を全環境で再取得しないよう、ローカルのキャッシュを共有する。
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$PWD/.standards/cache/terraform-plugins}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
for directory in "${directories[@]}"; do
  echo "Validating $directory"
  terraform -chdir="$directory" fmt -check -recursive -diff
  terraform -chdir="$directory" init -backend=false -input=false -lockfile=readonly
  terraform -chdir="$directory" validate -no-color
done
