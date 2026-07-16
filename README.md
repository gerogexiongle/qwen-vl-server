# Qwen VL OpenAI 接口服务

这个服务用 Docker + vLLM 暴露 OpenAI-compatible API：

```text
POST http://<server-ip>:18000/v1/chat/completions
```

启动时通过 `MODEL_NAME` 切换模型，便于做同一套服务的对比测试。

## 支持模型

| `MODEL_NAME` | Hugging Face repo | 默认 served model | 默认 vLLM |
| --- | --- | --- | --- |
| `qwen25-vl-3b` | `Qwen/Qwen2.5-VL-3B-Instruct` | `Qwen2.5-VL-3B-Instruct` | `v0.7.3` |
| `qwen35-4b` | `Qwen/Qwen3.5-4B` | `Qwen3.5-4B` | `latest` |
| `qwen3-vl-4b` | `Qwen/Qwen3-VL-4B-Instruct` | `Qwen3-VL-4B-Instruct` | `v0.11.0` |

别名也支持：`qwen2.5-vl-3b-instruct`、`qwen3.5-4b`、`qwen3-vl-4b-instruct`、完整 repo 名等。

## 机器要求

推荐训练机器当前是：

```text
Driver 530.30.02 / CUDA 12.1 / Tesla T4 x2
GPU 0: 2MiB / 15360MiB used
GPU 1: 2MiB / 15360MiB used
```

T4 不支持 `bfloat16`，所以默认 `DTYPE=half`。

gpu-04 这个环境已经支持 `qwen25-vl-3b`：它使用 `vllm/vllm-openai:v0.7.3`，该路径要求 CUDA 12.1，和当前驱动匹配。

Qwen3.5/Qwen3-VL 是另一条路径：它们需要更新版本 vLLM。官方 `vllm/vllm-openai:v0.11.0-x86_64` 镜像元数据里声明 `NVIDIA_REQUIRE_CUDA=cuda>=12.8`，所以 gpu-04 当前 `CUDA Version: 12.1` 不能直接跑官方 Qwen3 profile。脚本会按 `REQUIRED_CUDA_VERSION=12.8` 提前拦住，避免 Docker NVIDIA hook 阶段才失败。要在 gpu-04 上跑 Qwen3 profile，需要升级驱动让 `nvidia-smi` 显示 CUDA 12.8+，或做一个 CUDA 12.1 兼容的自定义 vLLM 镜像。

## GPU 检查

```bash
cd /data/xiongle/qwen-vl-server
chmod +x scripts/*.sh
sh scripts/gpu_check.sh
```

如果默认 CUDA 12.1 检查镜像拉不到，可以指定已有镜像：

```bash
CUDA_CHECK_IMAGE=qwen-vl-vllm-v0.7.3 sh scripts/gpu_check.sh
```

## 下载模型

下载方式对齐 `text2vec_mini`：根目录 [download.py](/data/xiongle/qwen-vl-server/download.py:1) 只用 `huggingface_hub.snapshot_download()`，变量名也是 `MODEL_REPO_ID`、`MODEL_LOCAL_DIR`、`HUGGINGFACE_TOKEN`。

```bash
cd /data/xiongle/qwen-vl-server
python3 -m pip install -U huggingface_hub

MODEL_NAME=qwen25-vl-3b sh scripts/download_model.sh
MODEL_NAME=qwen35-4b sh scripts/download_model.sh
MODEL_NAME=qwen3-vl-4b sh scripts/download_model.sh
```

默认下载目录：

```text
/data/xiongle/qwen-vl-server/models/Qwen2.5-VL-3B-Instruct
/data/xiongle/qwen-vl-server/models/Qwen3.5-4B
/data/xiongle/qwen-vl-server/models/Qwen3-VL-4B-Instruct
```

如果 Hugging Face 直连慢：

```bash
export HF_ENDPOINT=https://hf-mirror.com
MODEL_NAME=qwen3-vl-4b sh scripts/download_model.sh
```

## 构建镜像

构建脚本会根据 `MODEL_NAME` 选择默认 `VLLM_TAG` 和镜像名。

```bash
# Qwen2.5-VL
MODEL_NAME=qwen25-vl-3b ./scripts/docker_build.sh

# Qwen3.5
MODEL_NAME=qwen35-4b ./scripts/docker_build.sh

# Qwen3-VL
MODEL_NAME=qwen3-vl-4b ./scripts/docker_build.sh
```

默认镜像名：

```text
qwen-vl-vllm-v0.7.3
qwen-vl-vllm-latest
qwen-vl-vllm-v0.11.0
```

## 启动服务

每次只改 `MODEL_NAME` 即可切换模型；脚本会解析模型目录、served name、镜像名、CUDA 要求。下面使用 gpu-04 的 15GB T4 实测配置：关闭 CUDA Graph，并降低 KV Cache 和多模态输入的显存占用。

```bash
cd /data/xiongle/qwen-vl-server

MODEL_NAME=qwen25-vl-3b \
GPU_DEVICE=0 \
HOST_PORT=18000 \
GPU_MEMORY_UTILIZATION=0.80 \
ENFORCE_EAGER=1 \
LIMIT_IMAGES_PER_PROMPT=1 \
LIMIT_VIDEOS_PER_PROMPT=1 \
./scripts/docker_run.sh
```

切到 Qwen3-VL：

```bash
MODEL_NAME=qwen3-vl-4b \
GPU_DEVICE=0 \
HOST_PORT=18000 \
GPU_MEMORY_UTILIZATION=0.80 \
ENFORCE_EAGER=1 \
LIMIT_IMAGES_PER_PROMPT=1 \
LIMIT_VIDEOS_PER_PROMPT=1 \
./scripts/docker_run.sh
```

切到 Qwen3.5：

```bash
MODEL_NAME=qwen35-4b \
GPU_DEVICE=0 \
HOST_PORT=18000 \
GPU_MEMORY_UTILIZATION=0.80 \
ENFORCE_EAGER=1 \
LIMIT_IMAGES_PER_PROMPT=1 \
LIMIT_VIDEOS_PER_PROMPT=1 \
./scripts/docker_run.sh
```

启动后接口：

```text
http://<server-ip>:18000/v1/chat/completions
```

请求里的 `model` 字段用当前 served model 名，例如：

```json
{"model": "Qwen3-VL-4B-Instruct"}
```

## Compose

`docker compose` 不会自动解析 `MODEL_NAME` profile。使用 compose 时复制 `.env.example` 后，需要同步修改这些值：

```bash
cp .env.example .env
```

切 Qwen3-VL 示例：

```text
MODEL_NAME=qwen3-vl-4b
MODEL_REPO_ID=Qwen/Qwen3-VL-4B-Instruct
MODEL_DIR=/data/xiongle/qwen-vl-server/models/Qwen3-VL-4B-Instruct
SERVED_MODEL_NAME=Qwen3-VL-4B-Instruct
IMAGE_NAME=qwen-vl-vllm-v0.11.0
VLLM_TAG=v0.11.0
REQUIRED_CUDA_VERSION=12.8
```

然后：

```bash
docker compose up -d --build
docker logs -f qwen_vl_server
```

## 常用参数

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `MODEL_NAME` | `qwen25-vl-3b` | 启动/下载/构建时的模型 profile；gpu-04 当前确认支持这个 profile |
| `GPU_DEVICE` | `0` | 物理 GPU 编号 |
| `HOST_PORT` | `18000` | 宿主机端口 |
| `DTYPE` | `half` | T4 必须用 half/fp16 |
| `MAX_MODEL_LEN` | `4096` | 降低可减少显存 |
| `GPU_MEMORY_UTILIZATION` | `0.90` | 共享机器建议降到 `0.70~0.85` |
| `ENFORCE_EAGER` | `0` | 15GB T4 建议设为 `1`，避免 CUDA Graph 预热时 OOM |
| `LIMIT_IMAGES_PER_PROMPT` | `5` | 单请求图片数上限 |
| `LIMIT_VIDEOS_PER_PROMPT` | `5` | 单请求视频数上限 |
| `EXTRA_VLLM_ARGS` | profile 默认 | Qwen3.5 默认加 `--reasoning-parser qwen3` |

## 验证

文本请求：

```bash
curl -s http://127.0.0.1:18000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "Qwen2.5-VL-3B-Instruct",
    "messages": [
      {"role": "user", "content": "你好，简单介绍一下你自己"}
    ],
    "max_tokens": 128
  }'
```

图片请求：

```bash
curl -s http://127.0.0.1:18000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "Qwen3-VL-4B-Instruct",
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "image_url", "image_url": {"url": "https://modelscope.oss-cn-beijing.aliyuncs.com/resource/qwen.png"}},
          {"type": "text", "text": "图里有什么文字？"}
        ]
      }
    ],
    "max_tokens": 256
  }'
```

## 参考

- Qwen3.5-4B: https://huggingface.co/Qwen/Qwen3.5-4B
- Qwen3-VL-4B-Instruct: https://huggingface.co/Qwen/Qwen3-VL-4B-Instruct
- vLLM Docker: https://docs.vllm.ai/en/stable/deployment/docker/
