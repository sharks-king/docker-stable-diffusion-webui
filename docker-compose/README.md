# Stable Diffusion WebUI Docker Compose 部署指南

## 概述
本指南详细解释了 `docker-compose.yaml` 文件的配置项，帮助您快速部署 Stable Diffusion WebUI 服务。通过 Docker Compose，可实现一键式环境搭建、资源管理和服务编排。

---

## 配置文件详解

### 1. 镜像配置
```yaml
build:
  context: ../docker-build/   # Dockerfile 所在目录
  dockerfile: Dockerfile      # 指定构建用的 Dockerfile
# image: registry.cn-hangzhou.aliyuncs.com/...  # 预构建镜像（注释状态）
```
- **构建镜像**：默认从 `../docker-build/Dockerfile` 构建新镜像。
- **使用预构建镜像**：取消 `image` 行注释，并注释 `build` 部分可直接使用现有镜像。

---

### 2. 容器基础配置
```yaml
container_name: stable-diffusion-webui  # 容器命名
restart: unless-stopped                 # 异常自动重启
environment:
  - NVIDIA_VISIBLE_DEVICES=all          # 允许访问所有 GPU
ports:
  - 7860:7860                           # 暴露 WebUI 端口
```
- **端口映射**：`主机端口:容器端口`，若需更换主机端口，修改左侧数字（如 `8888:7860`）。
- **GPU 可见性**：`NVIDIA_VISIBLE_DEVICES=all` 确保容器能访问宿主机所有 GPU。

---

### 3. GPU 资源分配
```yaml
deploy:
  resources:
    reservations:
      devices:
        - capabilities: [gpu]
          device_ids: ['0']   # 指定使用第 1 块 GPU
          driver: nvidia      # NVIDIA 驱动
```
- **多 GPU 配置**：修改 `device_ids` 为 `['0,1']` 可使用前两块 GPU。
- **验证 GPU**：运行 `nvidia-smi` 查看 GPU 设备 ID。

---

### 4. 启动命令与参数
```yaml
entrypoint:
  - bash
  - /app/entrypoint.sh     # 主入口脚本
  - '--xformers'           # 显存优化
  - '--listen'             # 允许外部访问
  - '--port' '7860'        # 容器内监听端口

command:
  - '--api'                          # 启用 API
  - '--skip-torch-cuda-test'         # 跳过 CUDA 检测
  - '--enable-insecure-extension-access'  # 允许安装扩展
  - '--no-half-vae'                  # 禁用 VAE 半精度
  - '--skip-install'                 # 跳过依赖安装
```
- **`entrypoint` vs `command`**：
  - `entrypoint`：定义容器启动的主命令（不可覆盖）。
  - `command`：追加额外参数，可动态修改。
- **常用参数**：
  - `--medvram`：中等显存优化模式（适合 6-8GB 显存）。
  - `--lowvram`：低显存模式（适合 4GB 显存）。

---

### 5. 数据卷挂载
```yaml
volumes:
  - ./models:/app/stable-diffusion-webui/models                   # 模型存储
  - ./outputs:/app/stable-diffusion-webui/outputs                 # 生成结果
  - ./extensions:/app/stable-diffusion-webui/extensions           # 扩展插件
  - ./embeddings:/app/stable-diffusion-webui/embeddings           # 嵌入模型
  - ./textual_inversion_templates:/app/.../textual_inversion_templates  # 文本反转模板
```
- **目录准备**：
  ```bash
  mkdir -p {models,outputs,extensions,embeddings}
  chown -R 1000:1000 {models,outputs,extensions,embeddings}
  ```
- **模型放置**：将 `.safetensors` 或 `.ckpt` 文件放入 `./models/Stable-diffusion`。

---

## 快速开始

### 1. 启动服务
```bash
docker compose up -d      # 后台启动
docker compose logs -f    # 查看实时日志
```

### 2. 访问 WebUI
浏览器打开 `http://localhost:7860`（或宿主机 IP:7860）。

### 3. 停止服务
```bash
docker compose down      # 停止并删除容器
docker compose pull     # 更新镜像（使用预构建镜像时）
```

---

## 自定义配置

### 1. 切换 GPU 设备
```yaml
device_ids: ['1']   # 使用第二块 GPU
```

### 2. 启用远程访问
```yaml
ports:
  - "0.0.0.0:7860:7860"  # 允许所有 IP 访问
```

### 3. 扩展开发模式
```yaml
command:
  - '--allow-code'   # 允许执行自定义脚本
```

---

## 常见问题

### Q1：启动时报错 `Permission denied`
- **原因**：挂载目录权限不足。
- **解决**：
  ```bash
  sudo chown -R 1000:1000 ./models ./outputs
  ```

### Q2：WebUI 无法加载模型
- **检查路径**：确认模型文件位于 `./models/Stable-diffusion`。
- **日志排查**：
  ```bash
  docker compose logs | grep "Loading model"
  ```

### Q3：GPU 未生效
- **验证命令**：
  ```bash
  docker exec -it stable-diffusion-webui nvidia-smi
  ```
- **驱动更新**：安装最新 NVIDIA 驱动和 `nvidia-container-toolkit`。

---

> 更多高级配置参考 [官方文档](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki)