# Stable Diffusion WebUI Docker 部署指南

## 快速启动命令
```bash
docker run \
  --name stable-diffusion-webui \
  --gpus '"device=0"' \
  --env NVIDIA_VISIBLE_DEVICES=all \
  --publish 7860:7860 \
  --restart unless-stopped \
  --volume ./inputs:/app/stable-diffusion-webui/inputs \
  --volume ./textual_inversion_templates:/app/stable-diffusion-webui/textual_inversion_templates \
  --volume ./embeddings:/app/stable-diffusion-webui/embeddings \
  --volume ./extensions:/app/stable-diffusion-webui/extensions \
  --volume ./models:/app/stable-diffusion-webui/models \
  --volume ./localizations:/app/stable-diffusion-webui/localizations \
  --volume ./outputs:/app/stable-diffusion-webui/outputs \
  --volume ./repositories:/app/stable-diffusion-webui/repositories \
  registry.cn-hangzhou.aliyuncs.com/sharksking/stable-diffusion-webui:v1.10.1-20250107_100652-test \
  --api --skip-torch-cuda-test --enable-insecure-extension-access --no-half-vae --skip-install
```

---

## 参数详解

### 1. 容器基础配置
- **`--name stable-diffusion-webui`**  
  指定容器名称，便于后续管理（如查看日志、停止服务）。

- **`--restart unless-stopped`**  
  容器异常退出时自动重启（除非手动停止），适合长期运行的服务。

---

### 2. GPU 配置
- **`--gpus '"device=0"'`**  
  指定使用第一块 NVIDIA GPU（设备 ID 从 `0` 开始）。  
  *格式说明：需严格使用双引号包裹单引号（`"device=0"`）。*

- **`--env NVIDIA_VISIBLE_DEVICES=all`**  
  允许容器访问所有 GPU 设备（需配合 `nvidia-container-toolkit` 使用）。

---

### 3. 网络与端口
- **`--publish 7860:7860`**  
  将宿主机的 `7860` 端口映射到容器的 `7860` 端口，访问 `http://宿主机IP:7860` 即可使用 WebUI。

---

### 4. 数据卷挂载
| 宿主机目录                     | 容器目录                                | 用途                   |
|-------------------------------|---------------------------------------|------------------------|
| `./models`                    | `/app/stable-diffusion-webui/models`  | 存放模型文件（`.safetensors`/`.ckpt`） |
| `./outputs`                   | `/app/.../outputs`                   | 生成结果输出目录        |
| `./extensions`                | `/app/.../extensions`                | 扩展插件目录（如 ControlNet） |
| `./embeddings`                | `/app/.../embeddings`                | 嵌入模型存储目录        |
| `./textual_inversion_templates` | `/app/.../textual_inversion_templates` | 文本反转模板目录      |
| `./repositories`              | `/app/.../repositories`              | 代码仓库缓存目录        |

---

### 5. 镜像与启动参数
- **镜像地址**  
  `registry.cn-hangzhou.aliyuncs.com/sharksking/stable-diffusion-webui:v1.10.1-20250107_100652-test`  
  *来自阿里云容器镜像服务的预构建镜像。*

- **启动参数**  
  - `--api`：启用 API 接口（供外部程序调用）。  
  - `--skip-torch-cuda-test`：跳过 CUDA 兼容性检查（加速启动）。  
  - `--enable-insecure-extension-access`：允许安装未经验证的扩展。  
  - `--no-half-vae`：禁用 VAE 模型的半精度计算（解决部分模型崩溃问题）。  
  - `--skip-install`：跳过自动安装依赖（适用于预配置环境）。

---

## 准备工作
### 1. 目录准备
```bash
# 创建所有挂载目录
mkdir -p {models,outputs,extensions,embeddings,textual_inversion_templates}
# 设置权限（UID/GID 需与容器用户一致）
sudo chown -R 1000:1000 {models,outputs,extensions,embeddings,textual_inversion_templates}
```

### 2. 模型放置
将下载的模型文件（如 `model.safetensors`）放入 `./models/Stable-diffusion` 目录。

---

## 常见问题
### Q1：启动时报错 `Permission denied`
- **原因**：挂载目录权限不足。  
- **解决**：  
  ```bash
  sudo chown -R 1000:1000 {models,outputs,extensions,embeddings}
  ```

### Q2：GPU 未被识别
- **验证命令**：  
  ```bash
  docker exec -it stable-diffusion-webui nvidia-smi
  ```
- **解决**：  
  1. 安装最新 NVIDIA 驱动。  
  2. 确保已安装 `nvidia-container-toolkit`。

### Q3：WebUI 无法访问
- **检查端口占用**：  
  ```bash
  netstat -tuln | grep 7860
  ```
- **解决**：更换宿主机端口（如 `--publish 8888:7860`）。

---

## 高级配置
### 多 GPU 支持
```bash
--gpus '"device=0,1"'  # 使用前两块 GPU
```

### 自定义监听地址
```bash
--publish 0.0.0.0:7860:7860  # 允许所有 IP 访问
```

### 查看实时日志
```bash
docker logs -f stable-diffusion-webui
``` 

---

> 更多配置参考 [官方文档](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki)  
> 镜像更新：`docker pull registry.cn-hangzhou.aliyuncs.com/sharksking/stable-diffusion-webui:latest`
