#!/usr/bin/env bash
set -euo pipefail
# Arguments: repository-relative root, base commit/ref, head commit/ref.
# Exit status: 0 affected, 1 unaffected, 2 error. History must exist locally.
exec python3 "$(dirname "$0")/terraform_matrix.py" --check "$1" "$2" "$3"
