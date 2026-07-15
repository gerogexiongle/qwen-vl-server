#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

. "${ROOT_DIR}/scripts/model_profiles.sh"
resolve_model_profile

CANDIDATES=(
  "vllm/vllm-openai:${VLLM_TAG}"
  "docker.m.daocloud.io/vllm/vllm-openai:${VLLM_TAG}"
  "docker.1panel.live/vllm/vllm-openai:${VLLM_TAG}"
)

DOCKER_BUILD_CMD=(docker build)
if [[ -n "${http_proxy:-}" ]]; then
  DOCKER_BUILD_CMD+=(--build-arg "HTTP_PROXY=${http_proxy}")
fi
if [[ -n "${https_proxy:-}" ]]; then
  DOCKER_BUILD_CMD+=(--build-arg "HTTPS_PROXY=${https_proxy}")
fi
if [[ -n "${no_proxy:-}" ]]; then
  DOCKER_BUILD_CMD+=(--build-arg "NO_PROXY=${no_proxy}")
fi
if [[ -n "${PIP_INDEX_URL:-}" ]]; then
  DOCKER_BUILD_CMD+=(--build-arg "PIP_INDEX_URL=${PIP_INDEX_URL}")
fi
if [[ -n "${QWEN_VL_UTILS_VERSION:-}" ]]; then
  DOCKER_BUILD_CMD+=(--build-arg "QWEN_VL_UTILS_VERSION=${QWEN_VL_UTILS_VERSION}")
fi

BASE_IMAGE=""
for candidate in "${CANDIDATES[@]}"; do
  echo ">>> Trying base image: ${candidate}"
  if docker pull "${candidate}"; then
    BASE_IMAGE="${candidate}"
    echo ">>> Using base image: ${BASE_IMAGE}"
    break
  fi
  echo ">>> Pull failed, trying next image source..."
done

if [[ -z "${BASE_IMAGE}" ]]; then
  echo "ERROR: cannot pull vllm/vllm-openai:${VLLM_TAG}" >&2
  echo "Set Docker daemon proxy, or run: BASE_IMAGE=<mirror-image> docker build -t ${IMAGE_NAME} ." >&2
  exit 1
fi

DOCKER_BUILD_CMD+=(
  --build-arg "BASE_IMAGE=${BASE_IMAGE}"
  -t "${IMAGE_NAME}"
  .
)
DOCKER_BUILDKIT=1 "${DOCKER_BUILD_CMD[@]}"

echo ">>> Build completed: ${IMAGE_NAME}"
