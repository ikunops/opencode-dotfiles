#!/usr/bin/env python3
"""Vision via Zhipu GLM-4.6v (primary) or MiMo-V2.5 Free (opencode zen fallback)."""
import argparse
import base64
import json
import mimetypes
import os
import sys
import urllib.request
import urllib.error

ZHIPU_URL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
ZHIPU_MODEL = "glm-4.6v"
ZHIPU_FALLBACK = "glm-4v-plus"
ZHIPU_KEY = ""

MIMO_FREE_URL = "https://opencode.ai/zen/v1/chat/completions"
MIMO_FREE_MODEL = "mimo-v2.5-free"
MIMO_GO_URL = "https://opencode.ai/zen/go/v1/chat/completions"
MIMO_GO_MODEL = "mimo-v2.5"
MIMO_UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"

MAX_IMAGE_BYTES = 4 * 1024 * 1024

MIME = {
    ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
    ".webp": "image/webp", ".bmp": "image/bmp", ".gif": "image/gif",
}

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_zhipu_key():
    key = os.environ.get("GLM_VISION_API_KEY", "")
    if key:
        return key
    env_path = os.path.join(SKILL_DIR, ".env")
    if os.path.exists(env_path):
        for line in open(env_path, encoding="utf-8"):
            line = line.strip()
            if line.startswith("GLM_VISION_API_KEY="):
                return line.split("=", 1)[1].strip().strip('"').strip("'")
    return ZHIPU_KEY


def load_mimo_key():
    key = os.environ.get("OPENCODE_GO_API_KEY", "")
    if key:
        return key
    auth_path = os.path.join(os.path.expanduser("~"), ".local", "share", "opencode", "auth.json")
    try:
        with open(auth_path, encoding="utf-8") as f:
            data = json.load(f)
        k = (data.get("opencode-go") or {}).get("key") or ""
        if k:
            return k.strip()
    except Exception:
        pass
    return ""


def load_image(path):
    ext = os.path.splitext(path)[1].lower()
    mime = MIME.get(ext, mimetypes.guess_type(path)[0] or "image/png")
    with open(path, "rb") as f:
        data = f.read()
    if len(data) > MAX_IMAGE_BYTES:
        raise RuntimeError(f"图片过大 ({len(data)//1024//1024}MB > 4MB)，请先压缩")
    return f"data:{mime};base64,{base64.b64encode(data).decode()}"


def call_zhipu(key, model, urls, prompt):
    content = [{"type": "text", "text": prompt}]
    for u in urls:
        content.append({"type": "image_url", "image_url": {"url": u}})
    body = {"model": model, "messages": [{"role": "user", "content": content}], "max_tokens": 2048}
    req = urllib.request.Request(
        ZHIPU_URL,
        data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        data = json.loads(resp.read().decode())
    return data["choices"][0]["message"]["content"]


def call_mimo(key, model, urls, prompt, url):
    content = [{"type": "text", "text": prompt}]
    for u in urls:
        content.append({"type": "image_url", "image_url": {"url": u}})
    body = {"model": model, "messages": [{"role": "user", "content": content}], "max_tokens": 2048}
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json", "User-Agent": MIMO_UA},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        data = json.loads(resp.read().decode())
    msg = data["choices"][0]["message"]
    text = msg.get("content") or ""
    if not text:
        raise RuntimeError("mimo 返回空 content（reasoning 占满输出）")
    return text


def main():
    ap = argparse.ArgumentParser(description="Vision: Zhipu GLM-4.6v -> MiMo-V2.5 Free")
    ap.add_argument("images", help="图片路径，多个用逗号分隔")
    ap.add_argument("prompt", nargs="?", default="描述这张图片的内容",
                    help="问题或描述要求")
    ap.add_argument("--model", default=None, help="强制指定模型（glm-4.6v / glm-4v-plus / mimo-v2.5-free）")
    ap.add_argument("--lang", default=None, help="zh 或 en，覆盖输出语言")
    args = ap.parse_args()

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

    zkey = load_zhipu_key()
    mkey = load_mimo_key()

    last_err = None
    if args.model:
        if args.model.startswith("glm"):
            chain = [(args.model, "zhipu", zkey, ZHIPU_URL)]
        elif args.model == "mimo-v2.5-free":
            chain = [(args.model, "mimo", mkey, MIMO_FREE_URL)]
        elif args.model == "mimo-v2.5":
            chain = [(args.model, "mimo", mkey, MIMO_GO_URL)]
        else:
            chain = []
    else:
        # priority: Zhipu -> MiMo Free (zen, no quota) -> MiMo Go (uses Go quota)
        chain = [(ZHIPU_MODEL, "zhipu", zkey, ZHIPU_URL), (ZHIPU_FALLBACK, "zhipu", zkey, ZHIPU_URL)]
        if mkey:
            chain.append((MIMO_FREE_MODEL, "mimo", mkey, MIMO_FREE_URL))
            chain.append((MIMO_GO_MODEL, "mimo", mkey, MIMO_GO_URL))

    for model, prov, key, url in chain:
        try:
            if prov == "mimo":
                result = call_mimo(key, model, urls, prompt, url)
            else:
                result = call_zhipu(key, model, urls, prompt)
            print(result)
            return
        except urllib.error.HTTPError as e:
            last_err = f"HTTP {e.code}: {e.read().decode()[:200]}"
        except Exception as e:
            last_err = str(e)
        print(f"[vision] {model} ({prov}) 失败: {last_err}，尝试下一个…", file=sys.stderr)

    print(f"[vision] 所有模型失败: {last_err}", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
