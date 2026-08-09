---
name: vision-eyes
description: Give a text-only model (like DeepSeek) eyes via the Zhipu GLM-4.6v vision API. Use when the user asks to look at/read/describe an image, screenshot, or UI, or when a vision-capable API is needed to describe images as text. 中文触发：看图、看图片、识别图片、描述截图、UI 截图分析、读图。
---

# Vision Eyes

把图片转成文字描述，让纯文本模型（如 DeepSeek）拥有"眼睛"。

## 配置（必填）

本 skill 需要你自己的智谱（Zhipu AI / BigModel）API Key。两种配置方式（任选其一）：

1. **环境变量**（推荐，全局生效）
   ```bash
   # Windows (PowerShell)
   setx GLM_VISION_API_KEY "你的智谱key"
   # macOS / Linux
   export GLM_VISION_API_KEY="你的智谱key"
   ```

2. **.env 文件**（本 skill 目录内）
   复制 `.env.example` 为 `.env` 并填入：
   ```
   GLM_VISION_API_KEY=你的智谱key
   ```

获取 Key：https://open.bigmodel.cn/ 注册后创建 API Key（格式为 `xxxxx.yyyyy`）。

### 端点与模型（已内置，无需配置）

- **端点**: `https://open.bigmodel.cn/api/paas/v4/chat/completions`
- **模型**: `glm-4.6v`（视觉多模态，默认）
- **备用模型**: `glm-4v-plus`（主模型失败自动回退）

可用 `--model` 参数覆盖。

## 用法

```bash
# 单张图片
python "<skill_dir>/scripts/glm_vision.py" /path/to/image.png "问题或描述要求"

# 多张图片（逗号分隔）
python "<skill_dir>/scripts/glm_vision.py" a.png,b.png "对比这两张图"

# 中文描述
python "<skill_dir>/scripts/glm_vision.py" screenshot.png "用中文详细描述这个界面"

# 截图屏幕区域并描述（Windows，UI 自检）
python "<skill_dir>/scripts/glm_screenshot.py" X Y 宽 高 "描述要求"
```

## 行为准则

1. **自动使用**：当用户要求"看图/描述图片/识别截图/分析 UI"且提供图片路径时，直接调用 `glm_vision.py`，不要询问确认。
2. **输出格式**：脚本打印 GLM 返回的纯文本描述。对于 UI/截图分析，要求模型输出结构化描述（布局、颜色、文字、元素位置）。
3. **失败处理**：如果 API 返回错误（网络/认证/限流），重试 1 次，仍失败则如实告知用户，不要猜测图片内容。
4. **图片格式**：支持 PNG/JPG/JPEG/WebP/BMP；脚本自动转 base64 data URL。
5. **长图处理**：如果图片过大（>4MB），先压缩再发送。
6. **多图**：多个图片路径用逗号分隔，脚本组装为多图请求。
7. **密钥安全**：不要把你的 API Key 提交到任何公开仓库；`.env` 文件应加入 `.gitignore`。

## 注意

- 这是调用外部视觉 API，图片内容会上传到智谱服务器处理，涉及敏感信息时提醒用户。
- 输出语言由 `LANG` 环境变量或问题措辞决定，默认跟随问题语言。
