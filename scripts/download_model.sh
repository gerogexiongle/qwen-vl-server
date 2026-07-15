#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

. "${ROOT_DIR}/scripts/model_profiles.sh"
resolve_model_profile

mkdir -p "$(dirname "${MODEL_LOCAL_DIR}")"

echo ">>> Model repo: ${MODEL_REPO_ID}"
echo ">>> Target dir: ${MODEL_LOCAL_DIR}"
echo ">>> Model name: ${MODEL_PROFILE_KEY}"

if ! "${PYTHON_BIN}" -c 'import huggingface_hub' >/dev/null 2>&1; then
  echo "ERROR: Python package 'huggingface_hub' is not installed." >&2
  echo "Install it first: ${PYTHON_BIN} -m pip install -U huggingface_hub" >&2
  exit 1
fi

export MODEL_REPO_ID MODEL_LOCAL_DIR
"${PYTHON_BIN}" "${ROOT_DIR}/download.py"

echo ">>> Done."
