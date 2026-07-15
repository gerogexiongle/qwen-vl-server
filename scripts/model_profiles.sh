#!/bin/sh

resolve_model_profile() {
  MODEL_NAME="${MODEL_NAME:-qwen25-vl-3b}"
  model_key="$(printf '%s' "${MODEL_NAME}" | tr '[:upper:]' '[:lower:]')"

  case "${model_key}" in
    qwen25-vl-3b|qwen2.5-vl-3b|qwen2.5-vl-3b-instruct|qwen/qwen2.5-vl-3b-instruct)
      MODEL_PROFILE_KEY="qwen25-vl-3b"
      PROFILE_MODEL_REPO_ID="Qwen/Qwen2.5-VL-3B-Instruct"
      PROFILE_MODEL_DIR="${ROOT_DIR}/models/Qwen2.5-VL-3B-Instruct"
      PROFILE_SERVED_MODEL_NAME="Qwen2.5-VL-3B-Instruct"
      PROFILE_VLLM_TAG="v0.7.3"
      PROFILE_REQUIRED_CUDA_VERSION="12.1"
      PROFILE_MAX_MODEL_LEN="4096"
      PROFILE_GPU_MEMORY_UTILIZATION="0.90"
      PROFILE_EXTRA_VLLM_ARGS=""
      ;;
    qwen35-4b|qwen3.5-4b|qwen3.5|qwen/qwen3.5-4b)
      MODEL_PROFILE_KEY="qwen35-4b"
      PROFILE_MODEL_REPO_ID="Qwen/Qwen3.5-4B"
      PROFILE_MODEL_DIR="${ROOT_DIR}/models/Qwen3.5-4B"
      PROFILE_SERVED_MODEL_NAME="Qwen3.5-4B"
      PROFILE_VLLM_TAG="latest"
      PROFILE_REQUIRED_CUDA_VERSION="12.8"
      PROFILE_MAX_MODEL_LEN="4096"
      PROFILE_GPU_MEMORY_UTILIZATION="0.90"
      PROFILE_EXTRA_VLLM_ARGS="--reasoning-parser qwen3"
      ;;
    qwen3-vl-4b|qwen3-vl-4b-instruct|qwen3vl-4b|qwen/qwen3-vl-4b-instruct)
      MODEL_PROFILE_KEY="qwen3-vl-4b"
      PROFILE_MODEL_REPO_ID="Qwen/Qwen3-VL-4B-Instruct"
      PROFILE_MODEL_DIR="${ROOT_DIR}/models/Qwen3-VL-4B-Instruct"
      PROFILE_SERVED_MODEL_NAME="Qwen3-VL-4B-Instruct"
      PROFILE_VLLM_TAG="v0.11.0"
      PROFILE_REQUIRED_CUDA_VERSION="12.8"
      PROFILE_MAX_MODEL_LEN="4096"
      PROFILE_GPU_MEMORY_UTILIZATION="0.90"
      PROFILE_EXTRA_VLLM_ARGS=""
      ;;
    *)
      echo "ERROR: unsupported MODEL_NAME=${MODEL_NAME}" >&2
      echo "Supported: qwen25-vl-3b, qwen35-4b, qwen3-vl-4b" >&2
      return 1
      ;;
  esac

  MODEL_REPO_ID="${MODEL_REPO_ID:-${PROFILE_MODEL_REPO_ID}}"
  MODEL_LOCAL_DIR="${MODEL_LOCAL_DIR:-${MODEL_DIR:-${PROFILE_MODEL_DIR}}}"
  MODEL_DIR="${MODEL_DIR:-${MODEL_LOCAL_DIR}}"
  SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-${PROFILE_SERVED_MODEL_NAME}}"
  VLLM_TAG="${VLLM_TAG:-${PROFILE_VLLM_TAG}}"
  REQUIRED_CUDA_VERSION="${REQUIRED_CUDA_VERSION:-${PROFILE_REQUIRED_CUDA_VERSION}}"
  MAX_MODEL_LEN="${MAX_MODEL_LEN:-${PROFILE_MAX_MODEL_LEN}}"
  GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-${PROFILE_GPU_MEMORY_UTILIZATION}}"
  EXTRA_VLLM_ARGS="${EXTRA_VLLM_ARGS:-${PROFILE_EXTRA_VLLM_ARGS}}"
  IMAGE_NAME="${IMAGE_NAME:-qwen-vl-vllm-${VLLM_TAG}}"
  CONTAINER_NAME="${CONTAINER_NAME:-qwen_vl_server}"
}
