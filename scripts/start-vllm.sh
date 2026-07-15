#!/usr/bin/env bash
set -euo pipefail

MODEL_PATH="${MODEL_PATH:-/models/current}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-Qwen2.5-VL-3B-Instruct}"
VLLM_HOST="${VLLM_HOST:-0.0.0.0}"
VLLM_PORT="${VLLM_PORT:-8000}"
DTYPE="${DTYPE:-half}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-4096}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.90}"
LIMIT_IMAGES_PER_PROMPT="${LIMIT_IMAGES_PER_PROMPT:-5}"
LIMIT_VIDEOS_PER_PROMPT="${LIMIT_VIDEOS_PER_PROMPT:-5}"
TENSOR_PARALLEL_SIZE="${TENSOR_PARALLEL_SIZE:-1}"

args=(
  vllm serve "${MODEL_PATH}"
  --host "${VLLM_HOST}"
  --port "${VLLM_PORT}"
  --dtype "${DTYPE}"
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}"
  --max-model-len "${MAX_MODEL_LEN}"
  --served-model-name "${SERVED_MODEL_NAME}"
  --tensor-parallel-size "${TENSOR_PARALLEL_SIZE}"
  --limit-mm-per-prompt "image=${LIMIT_IMAGES_PER_PROMPT},video=${LIMIT_VIDEOS_PER_PROMPT}"
)

if [[ "${TRUST_REMOTE_CODE:-0}" == "1" || "${TRUST_REMOTE_CODE:-false}" == "true" ]]; then
  args+=(--trust-remote-code)
fi

if [[ "${ENFORCE_EAGER:-0}" == "1" || "${ENFORCE_EAGER:-false}" == "true" ]]; then
  args+=(--enforce-eager)
fi

if [[ -n "${EXTRA_VLLM_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  extra_args=(${EXTRA_VLLM_ARGS})
  args+=("${extra_args[@]}")
fi

echo ">>> Starting vLLM:"
printf ' %q' "${args[@]}"
echo

exec "${args[@]}"
