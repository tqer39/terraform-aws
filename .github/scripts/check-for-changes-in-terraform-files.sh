#!/bin/bash -u

# $1: デプロイパイプラインのパス
# $2: プルリクエストのヘッドブランチ
echo "\$1: $1"
echo "\$2: $2"

git fetch origin main
git fetch origin "$2"
git switch -C "$2"
CHANGED_FILES="$(git diff --name-only origin/main "$2" | sort -u)"
echo "----------------------------------"
echo "CHANGED_FILES: "
echo "${CHANGED_FILES}"

# 差分がないなら強制終了。処理対象のデプロイパイプラインではないため 1 で返す。
if [ -z "${CHANGED_FILES}" ]; then
  echo "No changed."
  exit 1
fi

# 変更されたファイルがデプロイパイプラインの関連リソースなのかチェックする関数
# 引数
# $1: 変更されたファイルのパス
# $2: デプロイパイプライン
# ----------------------------------
# 戻り値
# 1: 処理対象外
function is_changed () {
  changed_file=$2
  compare_path="$(echo "$2" | sed -e "s/\.\///g")" # "./" を削除

  echo "\$changed_file: ${changed_file}"
  echo "\$compare_path: ${compare_path}/*.*"

  if [[ $2 =~ ${compare_path}/.*\..*$ ]]; then
    echo "デプロイパイプラインで使用しているリソースが変更されたので処理対象です。"
    exit 0
  fi

  tf_files=$(find "${compare_path}" -type f -name "*.tf")

  for tf_file in $tf_files; do
    if [[ "${tf_file}" =~ .*(provider|terraform)\.tf$ ]]; then
      echo "${tf_file}: provider.tf, terraform.tf は対象外。"
      continue
    fi

    module_paths="$(grep -oP 'source\s*=\s*"\K[^"]+' "${tf_file}")"

    if [ -z "${module_paths}" ]; then
      echo "${tf_file}: No modules."
      continue
    fi

    for module_path in $module_paths; do
      cd "${compare_path}" || exit 2
      abs_source_path="$(realpath -e "${module_path}")"
      cd - > /dev/null || exit 2

      # 再起処理で追跡
      is_changed "${changed_file}" "${abs_source_path}"
    done
  done

  return 1
}

for file in $CHANGED_FILES; do
  if [[ "${file}" =~ ^\.github/(actions|workflows)/.*\.yml$ ]]; then
    echo "共通のワークフローが修正されたのでこのデプロイパイプラインは処理対象です。"
    exit 0
  fi

  is_changed "${file}" "$1"
done

# 追跡しきって変更がない場合は 1 で返す。
exit 1
