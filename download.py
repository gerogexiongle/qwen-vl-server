import os

from huggingface_hub import snapshot_download


REPO_ID = os.getenv(
    "MODEL_REPO_ID",
    os.getenv("MODEL_REPO", "Qwen/Qwen2.5-VL-3B-Instruct"),
)
LOCAL_DIR = os.getenv(
    "MODEL_LOCAL_DIR",
    os.getenv("MODEL_DIR", "./models/Qwen2.5-VL-3B-Instruct"),
)
TOKEN = os.getenv("HUGGINGFACE_TOKEN")


downloaded_path = snapshot_download(
    repo_id=REPO_ID,
    local_dir=LOCAL_DIR,
    local_dir_use_symlinks=False,
    token=TOKEN,
)

print(f"Model downloaded to {downloaded_path}")
