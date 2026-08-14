---
name: vision-eyes
description: Give a text-only model (like DeepSeek) eyes via Zhipu GLM-4v-flash free vision API (glm-4.6v / mimo-v2.5 / kimi-k3 fallback). Use when the user asks to look at/read/describe an image, screenshot, or UI, or when a vision-capable API is needed to describe images as text. 中文触发：看图、看图片、识别图片、描述截图、UI 截图分析、读图。
---

# Vision Eyes

把图片转成文字描述，让纯文本模型（如 DeepSeek）拥有"眼睛"。

## 配置

- **主模型**: 智谱 GLM-4v-flash（免费，key 在本 skill 的 `.env`，可用环境变量 `GLM_VISION_API_KEY` 覆盖）
- **端点**: `https://open.bigmodel.cn/api/paas/v4/chat/completions`
- **备用**: mimo-v2.5（Go，$0.14/M，比 kimi-k3 便宜 21 倍）/ kimi-k3（Go，key 自动读取 `~/.local/share/opencode/auth.json` 的 opencode-go key）

## 识别链路（自动回退）

按优先级依次尝试，前一个失败自动用下一个：

1. **智谱 GLM-4v-flash**（免费，识图最强）→ 备用 `glm-4.6v`（免费，推理型需较大 max_tokens）
2. **mimo-v2.5（opencode-go）**（$0.14/M，识图与 kimi-k3 相当）
3. **kimi-k3（opencode-go）**（$3/M，兜底）
4. **MiMo-V2.5 Free**（免费，不消耗 Go 配额）

可用 `--model` 强制指定（`kimi-k3` / `glm-4v-flash` / `glm-4.6v` / `mimo-v2.5` / `mimo-v2.5-free`）。

## 用法

```bash
# 单张图片
python "<skill_dir>/scripts/glm_vision.py" /path/to/image.png "问题或描述要求"

# 多张图片（逗号分隔）
python "<skill_dir>/scripts/glm_vision.py" a.png,b.png "对比这两张图"

# 中文描述
python "<skill_dir>/scripts/glm_vision.py" screenshot.png "用中文详细描述这个界面"
```

## 行为准则

1. **自动使用**：当用户要求"看图/描述图片/识别截图/分析 UI"且提供图片路径时，直接调用 `glm_vision.py`，不要询问确认。
2. **输出格式**：脚本打印 GLM 返回的纯文本描述。对于 UI/截图分析，要求模型输出结构化描述（布局、颜色、文字、元素位置）。
3. **失败处理**：如果 API 返回错误（网络/认证/限流），重试 1 次，仍失败则如实告知用户，不要猜测图片内容。
4. **图片格式**：支持 PNG/JPG/JPEG/WebP/BMP；脚本自动转 base64 data URL。
5. **长图处理**：如果图片过大（>4MB），先压缩再发送。
6. **多图**：多个图片路径用逗号分隔，脚本组装为多图请求。
7. **与悬浮窗集成**：本项目也用于 Go 用量悬浮窗的 UI 自检（截图 → 视觉描述 → 验证渲染）。

## 注意

- 这是调用外部视觉 API，图片内容会上传到智谱服务器处理，涉及敏感信息时提醒用户。
- 输出为中文或英文由 `LANG` 环境变量或问题措辞决定，默认跟随问题语言。
