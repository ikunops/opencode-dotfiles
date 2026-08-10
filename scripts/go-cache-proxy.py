#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
go-cache-proxy: 本地精确缓存代理, 置于 OpenCode CLI 与 OpenCode Go 之间。

作用:
  - 完全相同的请求体 (model + messages + 参数) 命中本地缓存, 直接返回缓存响应,
    不消耗 Go 配额。
  - 流式 (SSE) 请求透传上游, 同时缓冲完整响应用于缓存; 缓存命中时为流式客户端
    合成 OpenAI 格式 SSE 事件。
  - 其余端点 (/v1/models 等) 原样透传。

用法:
  python go-cache-proxy.py [--port 8787] [--upstream https://opencode.ai/zen/go/v1]

配置 OpenCode (opencode.jsonc):
  "provider": { "opencode-go": { "options": { "baseURL": "http://127.0.0.1:8787/v1" } } }

命中统计: http://127.0.0.1:8787/__stats  (GET)
清空缓存: http://127.0.0.1:8787/__clear  (POST)
"""

import argparse
import hashlib
import json
import os
import threading
import time
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CACHE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".cache", "go-cache")
CACHE_MAX_BYTES = int(os.environ.get("GOCACHE_MAX_BYTES", "268435456"))  # 256MB

DEFAULT_UPSTREAM = "https://opencode.ai/zen/go"  # 不含 /v1, 与请求路径拼接
SSE_CHUNK_TOKENS = 200  # 缓存命中时合成 SSE 的分片大小 (按字符计)

_stats = {"hits": 0, "misses": 0, "bytes_saved": 0, "tokens_saved": 0,
          "usd_saved": 0.0, "started": time.time()}
_stats_lock = threading.Lock()

# 估算省下的费用用 (USD per 1M tokens), 缺省按 deepseek-v4-flash 价
_PRICES = {
    "deepseek-v4-flash": (0.14, 0.28),
    "deepseek-v4-pro": (0.435, 0.87),
    "glm-5.2": (1.40, 4.40),
    "glm-5.1": (1.40, 4.40),
    "gpt-5.6-luna": (0.40, 1.80),
    "kimi-k3": (3.00, 15.00),
    "kimi-k2.7-code": (0.95, 4.00),
    "kimi-k2.6": (0.95, 4.00),
    "mimo-v2.5": (0.14, 0.28),
    "mimo-v2.5-pro": (0.435, 0.87),
    "minimax-m3": (0.30, 1.20),
    "minimax-m2.7": (0.30, 1.20),
    "qwen3.8-max": (2.00, 6.00),
    "qwen3.7-max": (2.50, 7.50),
    "qwen3.7-plus": (1.20, 4.80),
    "qwen3.6-plus": (2.00, 6.00),
    "hy3": (0.14, 0.58),
}


def estimate_usd(model: str, usage: dict) -> float:
    pin, pout = _PRICES.get(model, (0.14, 0.28))
    tin = usage.get("prompt_tokens", 0) or 0
    tout = usage.get("completion_tokens", 0) or 0
    return (tin / 1e6) * pin + (tout / 1e6) * pout


def cache_key(body: bytes) -> str:
    """缓存键 = 请求体 hash (不含 stream 字段, 使流式/非流式共享缓存)。"""
    try:
        obj = json.loads(body)
    except Exception:
        return hashlib.sha256(body).hexdigest()
    obj.pop("stream", None)
    canonical = json.dumps(obj, sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


_recent = []  # (key, model, n_messages, len_body) 最近 20 个请求, 用于调试
_recent_lock = threading.Lock()


def note_request(key: str, obj: dict):
    with _recent_lock:
        _recent.append((key, obj.get("model"), len(obj.get("messages") or []), len(json.dumps(obj))))
        del _recent[:-20]


def recent_requests():
    with _recent_lock:
        return list(_recent)


def cache_path(key: str) -> str:
    return os.path.join(CACHE_DIR, key[:2], key + ".json")


def cache_load(key: str):
    p = cache_path(key)
    if not os.path.isfile(p):
        return None
    try:
        with open(p, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def cache_store(key: str, response: dict):
    try:
        os.makedirs(os.path.dirname(cache_path(key)), exist_ok=True)
        tmp = cache_path(key) + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(response, f, ensure_ascii=False)
        os.replace(tmp, cache_path(key))
        _prune_cache()
    except Exception:
        pass


def _prune_cache():
    """按总字节上限清理最旧条目 (近似: 只清理子目录内最旧的 10%)。"""
    try:
        total = 0
        files = []
        for root, _dirs, names in os.walk(CACHE_DIR):
            for n in names:
                if n.endswith(".json"):
                    p = os.path.join(root, n)
                    total += os.path.getsize(p)
                    files.append((os.path.getmtime(p), p))
        if total <= CACHE_MAX_BYTES:
            return
        files.sort()
        for _mtime, p in files[: max(1, len(files) // 10)]:
            try:
                os.remove(p)
            except Exception:
                pass
    except Exception:
        pass


def hit_count(delta: int = 0, saved: int = 0, model: str = "", usage: dict = None):
    with _stats_lock:
        _stats["hits"] += delta
        _stats["bytes_saved"] += saved
        if usage:
            _stats["tokens_saved"] += usage.get("prompt_tokens", 0) or 0
            _stats["tokens_saved"] += usage.get("completion_tokens", 0) or 0
            _stats["usd_saved"] += estimate_usd(model, usage)
        return dict(_stats)


def miss_count(delta: int = 0):
    with _stats_lock:
        _stats["misses"] += delta
        return dict(_stats)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    upstream = DEFAULT_UPSTREAM

    def log_message(self, fmt, *args):
        ts = time.strftime("%H:%M:%S")
        print(f"[{ts}] {self.address_string()} {fmt % args}", flush=True)

    # ---------- 工具 ----------
    def _read_body(self) -> bytes:
        length = int(self.headers.get("Content-Length") or 0)
        if length <= 0:
            return b""
        return self.rfile.read(length)

    def _send_json(self, code: int, obj):
        data = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_error_json(self, code: int, msg: str):
        self._send_json(code, {"error": {"message": msg, "type": "proxy_error"}})

    def _upstream_request(self, method: str, path: str, body: bytes = None,
                          content_type: str = None):
        url = self.upstream.rstrip("/") + path
        headers = {
            "Authorization": self.headers.get("Authorization", ""),
            "User-Agent": self.headers.get("User-Agent") or "opencode",
        }
        if body is not None and content_type:
            headers["Content-Type"] = content_type
        req = urllib.request.Request(url, data=body, method=method, headers=headers)
        try:
            resp = urllib.request.urlopen(req, timeout=300)
            return resp
        except urllib.error.HTTPError as e:
            return e
        except Exception as e:
            raise e

    def _passthrough(self, method: str, path: str, body: bytes = None,
                     content_type: str = None):
        try:
            resp = self._upstream_request(method, path, body, content_type)
        except Exception as e:
            self._send_error_json(502, f"upstream error: {e}")
            return
        payload = resp.read()
        self.send_response(resp.status)
        for k, v in resp.headers.items():
            if k.lower() in ("content-length", "connection", "transfer-encoding"):
                continue
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _emit_sse_chunk(self, chunk: dict):
        data = "data: " + json.dumps(chunk, ensure_ascii=False) + "\n\n"
        self.wfile.write(data.encode("utf-8"))
        self.wfile.flush()

    def _stream_cached(self, resp_json: dict):
        """把缓存的非流式响应合成为 OpenAI SSE 事件流。"""
        msg = resp_json["choices"][0]["message"]
        content = msg.get("content") or ""
        created = int(resp_json.get("created", time.time()))
        cid = resp_json.get("id", "chatcmpl-cache")
        model = resp_json.get("model", "")
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.send_header("X-Go-Cache", "HIT")
        self.end_headers()
        self._emit_sse_chunk({"id": cid, "object": "chat.completion.chunk",
                              "created": created, "model": model,
                              "choices": [{"index": 0, "delta": {"role": "assistant"},
                                           "finish_reason": None}]})
        for i in range(0, len(content), SSE_CHUNK_TOKENS):
            piece = content[i:i + SSE_CHUNK_TOKENS]
            self._emit_sse_chunk({"id": cid, "object": "chat.completion.chunk",
                                  "created": created, "model": model,
                                  "choices": [{"index": 0, "delta": {"content": piece},
                                               "finish_reason": None}]})
        self._emit_sse_chunk({"id": cid, "object": "chat.completion.chunk",
                              "created": created, "model": model,
                              "choices": [{"index": 0, "delta": {},
                                           "finish_reason": "stop"}]})
        self.wfile.write(b"data: [DONE]\n\n")
        self.wfile.flush()
        self.close_connection = True

    def _send_cached_nonstream(self, resp_json: dict):
        data = json.dumps(resp_json, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("X-Go-Cache", "HIT")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    # ---------- 端点 ----------
    def do_GET(self):
        if self.path == "/__stats":
            s = dict(_stats)
            s["hit_rate"] = round(s["hits"] / max(1, s["hits"] + s["misses"]), 4)
            s["usd_saved"] = round(s["usd_saved"], 4)
            s["uptime_s"] = round(time.time() - s["started"])
            self._send_json(200, s)
            return
        if self.path == "/__recent":
            self._send_json(200, {"requests": recent_requests()})
            return
        self._passthrough("GET", self.path)

    def do_POST(self):
        if self.path == "/__clear":
            n = 0
            for root, _dirs, names in os.walk(CACHE_DIR):
                for name in names:
                    if name.endswith(".json"):
                        try:
                            os.remove(os.path.join(root, name))
                            n += 1
                        except Exception:
                            pass
            self._send_json(200, {"cleared": n})
            return
        if self.path != "/v1/chat/completions":
            self._passthrough("POST", self.path, self._read_body(),
                              self.headers.get("Content-Type"))
            return

        body = self._read_body()
        if not body:
            self._send_error_json(400, "empty body")
            return
        try:
            req = json.loads(body)
        except Exception:
            self._send_error_json(400, "invalid JSON")
            return

        is_stream = bool(req.get("stream"))
        key = cache_key(body)
        note_request(key, req)
        cached = cache_load(key)
        if cached:
            usage = cached.get("usage") if isinstance(cached.get("usage"), dict) else None
            hit_count(1, len(json.dumps(cached).encode("utf-8")),
                      model=cached.get("model", ""), usage=usage)
            if is_stream:
                self._stream_cached(cached)
            else:
                self._send_cached_nonstream(cached)
            return

        miss_count(1)
        try:
            resp = self._upstream_request("POST", "/v1/chat/completions", body,
                                          "application/json")
        except Exception as e:
            self._send_error_json(502, f"upstream error: {e}")
            return

        # 上游错误: 透传错误体
        if resp.status != 200:
            payload = resp.read()
            self.send_response(resp.status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return

        if is_stream:
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.send_header("X-Go-Cache", "MISS")
            self.end_headers()
            content = ""
            cid, created, model = "", int(time.time()), ""
            usage = None
            for raw in resp:
                line = raw.decode("utf-8", errors="replace")
                if line.startswith("data: "):
                    data = line[6:].strip()
                    if data == "[DONE]":
                        self.wfile.write(raw)
                        self.wfile.flush()
                        self.close_connection = True
                        break
                    try:
                        chunk = json.loads(data)
                        if not cid:
                            cid = chunk.get("id", "")
                            model = chunk.get("model", "")
                            created = int(chunk.get("created", created))
                        if chunk.get("usage") and isinstance(chunk["usage"], dict):
                            usage = chunk["usage"]
                        for ch in chunk.get("choices", []):
                            delta = ch.get("delta", {})
                            content += delta.get("content") or ""
                            content += delta.get("reasoning_content") or ""
                    except Exception:
                        pass
                self.wfile.write(raw)
                self.wfile.flush()
            cached_resp = {
                "id": cid, "object": "chat.completion", "created": created,
                "model": model,
                "choices": [{"index": 0,
                             "message": {"role": "assistant", "content": content},
                             "finish_reason": "stop"}],
                "usage": usage,
            }
            cache_store(key, cached_resp)
        else:
            payload = resp.read()
            try:
                resp_json = json.loads(payload)
                cache_store(key, resp_json)
            except Exception:
                pass
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("X-Go-Cache", "MISS")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)


def main():
    ap = argparse.ArgumentParser(description="Go cache proxy")
    ap.add_argument("--port", type=int, default=int(os.environ.get("GOCACHE_PORT", "8787")))
    ap.add_argument("--upstream", default=os.environ.get("GOCACHE_UPSTREAM", DEFAULT_UPSTREAM))
    args = ap.parse_args()
    Handler.upstream = args.upstream.rstrip("/")
    os.makedirs(CACHE_DIR, exist_ok=True)
    srv = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"go-cache-proxy listening on 127.0.0.1:{args.port} -> {Handler.upstream}")
    print(f"cache dir: {CACHE_DIR}")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
