#!/bin/sh
set -eu

echo ">>> Host nvidia-smi"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "WARN: nvidia-smi is not available in this shell."
fi

echo
echo ">>> Docker runtimes"
docker info --format 'Runtimes={{json .Runtimes}} DefaultRuntime={{json .DefaultRuntime}}'

if ! docker info --format '{{json .Runtimes}}' | grep -q nvidia; then
  echo "WARN: Docker does not list the nvidia runtime. Install/configure NVIDIA Container Toolkit before starting vLLM."
fi

echo
echo ">>> Docker GPU smoke test"
CUDA_CHECK_IMAGE="${CUDA_CHECK_IMAGE:-docker.m.daocloud.io/nvidia/cuda:12.1.1-base-ubuntu22.04}"
docker run --rm --gpus all --entrypoint nvidia-smi "${CUDA_CHECK_IMAGE}"
