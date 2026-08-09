#!/usr/bin/env python3
"""GLM-4.6v vision: describe image(s) as text for text-only models."""
import argparse
import base64
import json
import mimetypes
import os
import sys
import urllib.request
import urllib.error

API_URL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
DEFAULT_MODEL = "glm-4.6v"
FALLBACK_MODEL = "glm-4v-plus"
MAX_IMAGE_BYTES = 4 * 1024 * 1024

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_key():
    key = os.environ.get("GLM_VISION_API_KEY", "")
    if key:
        return key
    env_path = os.path.join(SKILL_DIR, ".env")
    if os.path.exists(env_path):
        for line in open(env_path, encoding="utf-8"):
            line = line.strip()
            if line.startswith("GLM_VISION_API_KEY="):
                return line.split("=", 1)[1].strip().strip('"').strip("'")
    raise RuntimeError(
        "未配置 API Key。请设置环境变量 GLM_VISION_API_KEY，"
        "或在 skill 目录创建 .env 文件：GLM_VISION_API_KEY=<你的智谱 key>"
    )

MIME = {
    ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
    ".webp": "image/webp", ".bmp": "image/bmp", ".gif": "image/gif",
}


def load_image(path):
    ext = os.path.splitext(path)[1].lower()
    mime = MIME.get(ext, mimetypes.guess_type(path)[0] or "image/png")
    with open(path, "rb") as f:
        data = f.read()
    if len(data) > MAX_IMAGE_BYTES:
        raise RuntimeError(f"图片过大 ({len(data)//1024//1024}MB > 4MB)，请先压缩")
    return f"data:{mime};base64,{base64.b64encode(data).decode()}"


def call_api(key, model, urls, prompt):
    content = [{"type": "text", "text": prompt}]
    for u in urls:
        content.append({"type": "image_url", "image_url": {"url": u}})
    body = {
        "model": model,
        "messages": [{"role": "user", "content": content}],
        "max_tokens": 2048,
    }
    req = urllib.request.Request(
        API_URL,
        data=json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        data = json.loads(resp.read().decode())
    return data["choices"][0]["message"]["content"]


def main():
    ap = argparse.ArgumentParser(description="GLM-4.6v vision image description")
    ap.add_argument("images", help="图片路径，多个用逗号分隔")
    ap.add_argument("prompt", nargs="?", default="描述这张图片的内容",
                    help="问题或描述要求")
    ap.add_argument("--model", default=None, help="覆盖模型")
    ap.add_argument("--lang", default=None, help="zh 或 en，覆盖输出语言")
    args = ap.parse_args()

    try:
        key = load_key()
    except RuntimeError as e:
        print(f"[vision] {e}", file=sys.stderr)
        sys.exit(1)
    model = args.model or DEFAULT_MODEL

    try:
        urls = [load_image(p.strip()) for p in args.images.split(",") if p.strip()]
    except Exception as e:
        print(f"[vision] 读取图片失败: {e}", file=sys.stderr)
        sys.exit(1)

    prompt = args.prompt
    if args.lang == "zh" and not any(c in prompt for c in "中文描述详细"):
        prompt = "请用中文回答。\n\n" + prompt
    elif args.lang == "en":
        prompt = "Please respond in English.\n\n" + prompt

    last_err = None
    for m in (model, FALLBACK_MODEL) if model == DEFAULT_MODEL else (model,):
        try:
            result = call_api(key, m, urls, prompt)
            print(result)
            return
        except urllib.error.HTTPError as e:
            last_err = f"HTTP {e.code}: {e.read().decode()[:200]}"
        except Exception as e:
            last_err = str(e)
        if m == model:
            print(f"[vision] {model} 失败({last_err})，尝试备用模型…", file=sys.stderr)
    print(f"[vision] 所有模型失败: {last_err}", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
