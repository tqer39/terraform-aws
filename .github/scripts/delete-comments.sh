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

if [ -z "${GITHUB_TOKEN}" ]; then
  echo "GITHUB_TOKEN is empty."
  exit 0
fi

function _jq() {
  echo "$1" | base64 -di | jq -r "$2"
}

COMMENTS=""

function get_comments() {
  query=$(<"./.github/scripts/get_pr_comments.graphql")

  # 改行があるとダメなので削除
  query=$(echo "${query}" | tr -d '\n')

  json_payload=$(cat << EOF
{
  "query": "${query}",
  "variables": {
    "owner": "${OWNER}",
    "name": "${REPOSITORY}",
    "number": ${PULL_REQUEST_NUMBER}
  }
}
EOF
  )

  # コメントを取得
  COMMENTS=$(curl -s -X POST -H "Authorization: bearer ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" -d "${json_payload}" \
    "https://api.github.com/graphql" | jq '@base64')

  if [ -z "${COMMENTS}" ]; then
    echo "COMMENTS is empty."
    exit 0
  fi
}

function delete_comments() {
  len=$(echo "${COMMENTS}" | base64 -di | \
    jq -r '.data.repository.pullRequest.comments.nodes' | jq length)

  for i in $(seq 0 $((len - 1))); do
    comment=$(echo "${COMMENTS}" | base64 -di | \
      jq -r ".data.repository.pullRequest.comments.nodes[${i}]" | jq '@base64')
    node_id=$(echo "${comment}" | base64 -di | jq -r '.id')
    comment_body=$(echo "${comment}" | base64 -di | jq -r '.body')

    if [[ "${comment_body}" =~ .*No\ changes.*Target.*${ENV_NAME}/.* ]]; then
      echo "node_id: ${node_id}"
      delete_comment "${node_id}"
    fi
  done
}

# $1: node_id
function delete_comment() {
  node_id="$1"
  json_payload=$(cat << EOF
{
  "query": "mutation {
    deleteIssueComment(input: {
      id: \"${node_id}\"}
    ) {
      clientMutationId
    }
  }"
}
EOF
  )

  # Delete the comment
  curl -X POST -H "Authorization: bearer ${GITHUB_TOKEN}" \
    -d "{
      \"query\": \"mutation { deleteIssueComment(input: {id: '${node_id}'}) { clientMutationId } }\"
    }" https://api.github.com/graphql
}

function main() {
  get_comments
  delete_comments
}

main
