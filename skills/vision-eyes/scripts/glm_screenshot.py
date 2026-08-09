#!/usr/bin/env python3
"""Screenshot a window region and describe it with GLM-4.6v (UI self-check)."""
import argparse
import base64
import json
import os
import subprocess
import sys
import tempfile
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import glm_vision as g

PS_SCRIPT = r'''
param([int]$X,[int]$Y,[int]$W,[int]$H,[string]$Out)
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap $W, $H
$gr = [System.Drawing.Graphics]::FromImage($bmp)
$gr.CopyFromScreen($X, $Y, 0, 0, $bmp.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$gr.Dispose(); $bmp.Dispose()
'''


def screenshot(x, y, w, h, out):
    ps = os.path.join(tempfile.gettempdir(), "shot.ps1")
    with open(ps, "w", encoding="utf-8") as f:
        f.write(PS_SCRIPT)
    subprocess.run(
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ps,
         "-X", str(x), "-Y", str(y), "-W", str(w), "-H", str(h), "-Out", out],
        check=True)


def main():
    ap = argparse.ArgumentParser(description="Screenshot + GLM vision describe")
    ap.add_argument("x", type=int)
    ap.add_argument("y", type=int)
    ap.add_argument("w", type=int)
    ap.add_argument("h", type=int)
    ap.add_argument("prompt", nargs="?", default="用中文详细描述这个界面",
                    help="描述要求")
    args = ap.parse_args()

    out = os.path.join(tempfile.gettempdir(), "glm-shot.png")
    try:
        screenshot(args.x, args.y, args.w, args.h, out)
    except Exception as e:
        print(f"[vision] 截图失败: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        urls = [g.load_image(out)]
    except Exception as e:
        print(f"[vision] 读取截图失败: {e}", file=sys.stderr)
        sys.exit(1)

    # Reuse glm_vision's provider chain (Zhipu -> MiMo Free -> MiMo Go)
    try:
        zkey = g.load_zhipu_key()
        mkey = g.load_mimo_key()
        chain = [(g.ZHIPU_MODEL, "zhipu", zkey, g.ZHIPU_URL),
                 (g.ZHIPU_FALLBACK, "zhipu", zkey, g.ZHIPU_URL)]
        if mkey:
            chain.append((g.MIMO_FREE_MODEL, "mimo", mkey, g.MIMO_FREE_URL))
            chain.append((g.MIMO_GO_MODEL, "mimo", mkey, g.MIMO_GO_URL))
        last_err = None
        for model, prov, key, url in chain:
            try:
                if prov == "mimo":
                    result = g.call_mimo(key, model, urls, args.prompt, url)
                else:
                    result = g.call_zhipu(key, model, urls, args.prompt)
                print(result)
                return
            except Exception as e:
                last_err = str(e)
        raise RuntimeError(last_err or "所有模型失败")
    except Exception as e:
        print(f"[vision] 视觉识别失败: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
