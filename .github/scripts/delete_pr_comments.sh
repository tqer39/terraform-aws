#!/bin/bash -u

# $1: オーナー
# $2: リポジトリ
# $3: 環境名
# $4: プルリクエスト番号
# $5: GITHUB_TOKEN

OWNER="$1"
REPOSITORY="$2"
ENV_NAME="$3"
PULL_REQUEST_NUMBER="$4"
GITHUB_TOKEN="$5"
SEARCH_STRING=".*No\ changes.*Target.*${ENV_NAME}/.*"

if [ -z "${GITHUB_TOKEN}" ]; then
  echo "GITHUB_TOKEN is empty."
  exit 0
fi

function _jq() {
  echo "$1" | base64 -di | jq -r "$2"
}

function get_comments() {
  # ページング対応
  export HAS_NEXT_PAGE="true"
  export END_CURSOR=null
  while [ "${HAS_NEXT_PAGE}" = "true" ]; do
    query=$(tr -d '\n' < "./.github/scripts/get_pr_comments.graphql")
    json_payload=$(cat << EOF
{
  "query": "${query}",
  "variables": {
    "owner": "${OWNER}",
    "repository": "${REPOSITORY}",
    "pr_number": ${PULL_REQUEST_NUMBER},
    "end_cursor": ${END_CURSOR}
  }
}
EOF
  )
    echo "[debug] json_payload: ${json_payload}"

    # コメントを取得
    #   コメントに特殊文字があるからかデータが正常な json ではないため
    #   @base64 でエンコードしておき、データを取り出すタイミングでデコードする
    COMMENTS=$(curl -s -X POST -H "Authorization: bearer ${GITHUB_TOKEN}" \
      -H "Content-Type: application/json" -d "${json_payload}" \
      "https://api.github.com/graphql" | jq '@base64')
    # echo "[debug] COMMENTS: ${COMMENTS}"

    if [ -z "${COMMENTS}" ]; then
      echo "COMMENTS is empty."
      exit 0
    fi

    delete_comments "${COMMENTS}"

    # 次のページがあるかどうか
    HAS_NEXT_PAGE=$(echo "${COMMENTS}" | base64 -di | \
      jq -r '.data.repository.pullRequest.comments.pageInfo.hasNextPage')
    echo "[debug] HAS_NEXT_PAGE: ${HAS_NEXT_PAGE}"

    # 次のページがある場合は、次のページのクエリを取得するためのカーソルをセット
    if [ "${HAS_NEXT_PAGE}" = "true" ]; then
      END_CURSOR=$(echo "${COMMENTS}" | base64 -di | \
        jq -r '.data.repository.pullRequest.comments.pageInfo.endCursor')
      echo "[debug] END_CURSOR: ${END_CURSOR}"
    fi
  done
}

# $1: comments
function delete_comments() {
  local COMMENTS="$1"
  len=$(echo "${COMMENTS}" | base64 -di | \
    jq -r '.data.repository.pullRequest.comments.nodes' | jq length)
  echo "[debug] len: ${len}"

  for i in $(seq 0 $((len - 1))); do
    comment=$(echo "${COMMENTS}" | base64 -di | \
      jq -r ".data.repository.pullRequest.comments.nodes[${i}]" | jq '@base64')
    node_id=$(echo "${comment}" | base64 -di | jq -r '.id')
    comment_body=$(echo "${comment}" | base64 -di | jq -r '.body')

    if [[ "${comment_body}" =~ $SEARCH_STRING ]]; then
      echo "node_id: ${node_id}"
      delete_comment "${node_id}"
    fi
  done
}

# $1: node_id
function delete_comment() {
  local node_id="$1"
  query=$(tr -d '\n' < "./.github/scripts/delete_pr_comment.graphql")
  # query=$(echo "${query}" | tr -d '\n') # 改行があるとダメなので削除
  json_payload=$(cat <<EOF
{
  "query": "${query}",
  "variables": {
    "input": {
      "id": "${node_id}"
    }
  }
}
EOF
  )
  # echo "[debug] json_payload: ${json_payload}"

  curl -s -X POST -H "Authorization: bearer ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" -d "${json_payload}" \
    https://api.github.com/graphql
}

get_comments
