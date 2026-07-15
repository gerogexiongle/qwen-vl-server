ARG BASE_IMAGE=vllm/vllm-openai:v0.7.3
FROM ${BASE_IMAGE}

# This image already contains the CUDA runtime, PyTorch, and vLLM.
# Do not replace it with a bare nvidia/cuda image unless you also install
# the matching Python/vLLM/PyTorch stack yourself.

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ARG QWEN_VL_UTILS_VERSION=0.0.14

ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY} \
    PIP_INDEX_URL=${PIP_INDEX_URL} \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai

WORKDIR /app

COPY scripts/start-vllm.sh /usr/local/bin/start-vllm.sh
RUN chmod +x /usr/local/bin/start-vllm.sh \
    && if command -v uv >/dev/null 2>&1; then \
         uv pip install --system --no-cache "qwen-vl-utils==${QWEN_VL_UTILS_VERSION}"; \
       else \
         python3 -m pip install --no-cache-dir "qwen-vl-utils==${QWEN_VL_UTILS_VERSION}"; \
       fi

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/start-vllm.sh"]
