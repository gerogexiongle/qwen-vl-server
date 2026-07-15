#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

. "${ROOT_DIR}/scripts/model_profiles.sh"
resolve_model_profile

HF_CACHE_DIR="${HF_CACHE_DIR:-${ROOT_DIR}/hf_cache}"
GPU_DEVICE="${GPU_DEVICE:-0}"
HOST_PORT="${HOST_PORT:-18000}"
CONTAINER_PORT="${CONTAINER_PORT:-8000}"
SHM_SIZE="${SHM_SIZE:-8g}"

check_cuda_version() {
  if [[ "${SKIP_CUDA_REQUIRE_CHECK:-0}" == "1" ]]; then
    return 0
  fi

  if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "WARN: nvidia-smi not found; skip host CUDA version precheck." >&2
    return 0
  fi

  local host_cuda
  host_cuda="$(nvidia-smi 2>/dev/null | sed -n 's/.*CUDA Version: \([0-9.]*\).*/\1/p' | head -n 1)"
  if [[ -z "${host_cuda}" ]]; then
    echo "WARN: cannot parse CUDA Version from nvidia-smi; skip host CUDA version precheck." >&2
    return 0
  fi

  local lowest
  lowest="$(printf '%s\n%s\n' "${REQUIRED_CUDA_VERSION}" "${host_cuda}" | sort -V | head -n 1)"
  if [[ "${lowest}" != "${REQUIRED_CUDA_VERSION}" ]]; then
    cat >&2 <<EOF
ERROR: Host NVIDIA driver reports CUDA ${host_cuda}, but ${IMAGE_NAME} requires CUDA >= ${REQUIRED_CUDA_VERSION}.
The official vLLM image is blocked by NVIDIA Container Toolkit before vLLM starts.

Fix options:
  1. Upgrade the host NVIDIA driver so nvidia-smi reports CUDA >= ${REQUIRED_CUDA_VERSION}.
  2. Use a custom CUDA 11.x inference image instead of the official vLLM image.

Do not use NVIDIA_DISABLE_REQUIRE=1 as a real fix; it only skips the hook check and CUDA may still fail at runtime.
EOF
    exit 1
  fi
}

if [[ ! -d "${MODEL_DIR}" ]]; then
  echo "ERROR: MODEL_DIR does not exist: ${MODEL_DIR}" >&2
  echo "Run: MODEL_NAME=${MODEL_PROFILE_KEY} sh scripts/download_model.sh" >&2
  echo "Or export MODEL_DIR=/path/to/model." >&2
  exit 1
fi

mkdir -p "${HF_CACHE_DIR}"
check_cuda_version

echo ">>> Model profile: ${MODEL_PROFILE_KEY}"
echo ">>> Model repo: ${MODEL_REPO_ID}"
echo ">>> Model dir: ${MODEL_DIR}"
echo ">>> Served model name: ${SERVED_MODEL_NAME}"
echo ">>> vLLM image: ${IMAGE_NAME}"

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run -d \
  --name "${CONTAINER_NAME}" \
  --gpus "\"device=${GPU_DEVICE}\"" \
  --ipc=host \
  --shm-size "${SHM_SIZE}" \
  -p "${HOST_PORT}:${CONTAINER_PORT}" \
  -v "${MODEL_DIR}:/models/current:ro" \
  -v "${HF_CACHE_DIR}:/root/.cache/huggingface" \
  -e "NVIDIA_VISIBLE_DEVICES=${GPU_DEVICE}" \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  -e HF_HOME=/root/.cache/huggingface \
  -e TRANSFORMERS_CACHE=/root/.cache/huggingface \
  -e "VLLM_ENABLE_CUDA_COMPATIBILITY=${VLLM_ENABLE_CUDA_COMPATIBILITY:-0}" \
  -e "MODEL_NAME=${MODEL_PROFILE_KEY}" \
  -e MODEL_PATH=/models/current \
  -e "SERVED_MODEL_NAME=${SERVED_MODEL_NAME}" \
  -e VLLM_HOST=0.0.0.0 \
  -e "VLLM_PORT=${CONTAINER_PORT}" \
  -e "DTYPE=${DTYPE:-half}" \
  -e "MAX_MODEL_LEN=${MAX_MODEL_LEN}" \
  -e "GPU_MEMORY_UTILIZATION=${GPU_MEMORY_UTILIZATION}" \
  -e "LIMIT_IMAGES_PER_PROMPT=${LIMIT_IMAGES_PER_PROMPT:-5}" \
  -e "LIMIT_VIDEOS_PER_PROMPT=${LIMIT_VIDEOS_PER_PROMPT:-5}" \
  -e "TENSOR_PARALLEL_SIZE=${TENSOR_PARALLEL_SIZE:-1}" \
  -e "ENFORCE_EAGER=${ENFORCE_EAGER:-0}" \
  -e "TRUST_REMOTE_CODE=${TRUST_REMOTE_CODE:-0}" \
  -e "EXTRA_VLLM_ARGS=${EXTRA_VLLM_ARGS}" \
  -e "http_proxy=${http_proxy:-}" \
  -e "https_proxy=${https_proxy:-}" \
  -e "no_proxy=${no_proxy:-localhost,127.0.0.1,192.168.0.0/16,172.31.0.0/16,10.0.0.0/8}" \
  -e "HTTP_PROXY=${http_proxy:-}" \
  -e "HTTPS_PROXY=${https_proxy:-}" \
  -e "NO_PROXY=${no_proxy:-localhost,127.0.0.1,192.168.0.0/16,172.31.0.0/16,10.0.0.0/8}" \
  --restart always \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  "${IMAGE_NAME}"

echo ">>> Started ${CONTAINER_NAME}"
echo ">>> API: http://<server-ip>:${HOST_PORT}/v1/chat/completions"
