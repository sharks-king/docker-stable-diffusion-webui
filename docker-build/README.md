# Stable Diffusion WebUI Docker 构建指南

## 项目概述
本项目提供了基于 Docker 的 Stable Diffusion WebUI 环境构建方案，包含自动化的依赖安装和配置，支持 GPU 加速。镜像基于 `pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime`，预装了必要的系统依赖和 Python 环境。

---

## 前提条件
1. **Docker 环境**：确保已安装 Docker 和 `docker buildx` 插件。
2. **NVIDIA 支持**（GPU 模式）：
   - 安装 NVIDIA 驱动和 `nvidia-container-toolkit`。
   - 运行前添加 `--gpus all` 参数以启用 GPU。
3. **目录权限**：挂载目录需归属用户 `1000` 和组 `1000`（见下方[重要提示](#重要提示)）。

---

## 快速开始

### 1. 构建镜像
```bash
# 语法：./build.sh <自定义后缀>
./build.sh experimental
```
- 镜像标签格式：`stable-diffusion-webui:v1.10.1-<日期>-<自定义后缀>`。
- 使用 `--push` 自动推送镜像到仓库（需提前登录 Docker Registry）。

### 2. 运行容器
```bash
docker run -d \
  --gpus all \
  -p 7860:7860 \
  -v /path/to/models:/app/stable-diffusion-webui/models \
  -v /path/to/outputs:/app/stable-diffusion-webui/outputs \
  stable-diffusion-webui:v1.10.1-20231001_1430-experimental
```
- `--listen`: 允许外部访问 WebUI。
- `--xformers`: 启用显存优化（需 GPU 支持）。
---

## 配置文件详解

### Dockerfile 解析
```dockerfile
# ========================================================
# Stable Diffusion WebUI 定制化 Dockerfile
# 基础镜像配置
# ========================================================
# 使用官方 PyTorch 镜像，包含 CUDA 12.4 和 cuDNN 9 运行时支持
# 镜像选择原因：提供 GPU 加速所需的完整深度学习环境
FROM pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime

# ========================================================
# 系统级环境变量配置
# ========================================================
# 禁用 apt-get 交互提示（自动化构建关键配置）
ENV DEBIAN_FRONTEND=noninteractive
# 允许容器访问所有 NVIDIA GPU 设备（需配合 nvidia-docker 使用）
ENV NVIDIA_VISIBLE_DEVICES=all
# Python 虚拟环境路径配置（解决非 root 用户权限问题）
ENV PATH="/app/.local/bin:${PATH}"

# ========================================================
# 系统依赖安装阶段
# ========================================================
# 安装系统级依赖：
# - Git：代码仓库克隆
# - Python 3.10：通过 deadsnakes PPA 安装指定版本
# - GPU 相关库：libgl1-mesa-dev, libcusparse11 等
# - 其他工具：aria2（多线程下载）, xdg-utils（文件操作）
RUN apt update \
    && apt install git software-properties-common -y \
    && add-apt-repository ppa:deadsnakes/ppa -y \
    && apt install -y python3 python3-pip python3-venv git wget libgl1-mesa-dev libglib2.0-0 libsm6 libxrender1 libxext6 libgoogle-perftools4 libtcmalloc-minimal4 libcusparse11 xdg-utils bc aria2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ========================================================
# 用户权限配置阶段
# ========================================================
# 创建非 root 用户 sduser (UID 1000) 和用户组 sdgroup (GID 1000)
# 重要：挂载的本地目录需保持相同 UID/GID 以避免权限问题
RUN addgroup --gid 1000 sdgroup \
    && useradd --home-dir /app --shell /bin/bash --uid 1000 --gid 1000 --password "*" --create-home sduser \
    && ln -s /app /home/sduser \
    && chown -R sduser:sdgroup /app 

# 强制设置 /app 目录权限（双重保障）
RUN chown -R 1000:1000 /app

# ========================================================
# 用户上下文切换
# ========================================================
# 切换到非特权用户执行后续操作（安全最佳实践）
USER sduser
# 设置工作目录为 /app/stable-diffusion-webui
WORKDIR /app

# ========================================================
# 代码仓库克隆阶段（带重试机制）
# ========================================================
# 使用 until 循环实现自动重试克隆，解决网络不稳定的常见问题
# 关键仓库列表：
# 1. AUTOMATIC1111 官方 WebUI
# 2. Stability-AI 的官方模型仓库
# 3. 资源文件仓库（界面素材等）
RUN until git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui; do sleep 1; done \
    && until git clone "https://github.com/Stability-AI/stablediffusion.git" "/app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai"; do sleep 1; done \
    && until git clone "https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets"  "/app/stable-diffusion-webui/repositories/stable-diffusion-webui-assets"; do sleep 1; done \
    && until git clone "https://github.com/Stability-AI/generative-models.git" "/app/stable-diffusion-webui/repositories/generative-models"; do sleep 1; done \
    && until git clone  "https://github.com/crowsonkb/k-diffusion.git" "/app/stable-diffusion-webui/repositories/k-diffusion"; do sleep 1; done \
    && until git clone  "https://github.com/salesforce/BLIP.git" "/app/stable-diffusion-webui/repositories/BLIP"; do sleep 1; done

# ========================================================
# Python 环境配置阶段
# ========================================================
WORKDIR /app/stable-diffusion-webui
# 创建虚拟环境并修改配置：
# 1. 允许使用系统级 site-packages（减少重复安装）
# 2. 安装关键加速库 xformers
RUN python3 -m venv venv \
    && sed -i 's/include-system-site-packages = false/include-system-site-packages = true/' venv/pyvenv.cfg \
    && pip install packaging xformers \
    && pip install -r requirements.txt

# ========================================================
# 构建时环境初始化技巧
# ========================================================
# 临时禁用 launch.py 的启动函数以避免构建时启动服务
# 步骤解析：
# 1. 注释 start() 调用
# 2. 执行环境初始化（模型下载等）
# 3. 恢复 start() 函数
# 4. 重置 git 修改（保持仓库干净）
RUN sed -i -e 's/    start()/    #start()/g' launch.py \
    && python3 launch.py --skip-torch-cuda-test \
    && sed -i -e 's/    #start()/    start()/g' launch.py \
    && git reset --hard

# ========================================================
# 容器运行时配置
# ========================================================
# 暴露 WebUI 默认端口
EXPOSE 7860
# 复制自定义启动脚本（entrypoint.sh）
COPY ./entrypoint.sh /app/entrypoint.sh
# 设置默认启动命令（可被 docker run 参数覆盖）
ENTRYPOINT ["/bin/bash","/app/entrypoint.sh", "--xformers", "--listen", "--port", "7860"]
```
#### Dockerfile 关键设计
- **权限隔离**：通过非 root 用户保障容器安全性
- **网络容错**：until 循环实现 Git 克隆自动重试
- **环境固化**：在构建阶段完成依赖安装和初始化

### entrypoint.sh 启动脚本解析
```bash
#!/usr/bin/env bash
# ========================================================
# Stable Diffusion WebUI 容器入口脚本
# 核心功能：标准化启动流程与参数传递
# ========================================================

# 使用 bash 作为脚本解释器（兼容性最佳选择）

# ========================================================
# 目录上下文管理
# ========================================================
# 进入 WebUI 主目录（保持操作上下文一致性）
# 技术细节：
# - pushd 命令将 /app/stable-diffusion-webui 压入目录栈
# - 相比 cd 命令的优势：执行后可通过 popd 自动恢复原始目录
pushd /app/stable-diffusion-webui

# ========================================================
# 核心启动逻辑
# ========================================================
# 执行官方启动脚本并透传所有参数
# 关键设计：
# - "$@" 表示传递所有容器运行时输入的参数（如 --medvram 等）
# - 使用 ./webui.sh 而非绝对路径：确保在正确上下文中执行
./webui.sh "$@"

# ========================================================
# 环境清理阶段
# ========================================================
# 恢复原始工作目录（良好的资源管理实践）
# 注意：
# - 虽然容器生命周期结束时自动清理，但显式 popd 保持逻辑完整性
popd
```
#### entrypoint.sh 关键设计
- **参数透传**：`"$@"` 允许容器运行时添加任意 `webui.sh` 支持的参数
- **目录栈管理**：`pushd/popd` 确保脚本执行后环境状态的一致性
- **最小化修改**：直接调用官方脚本，避免二次封装带来的兼容性问题

---

## 自定义配置

### 1. 加速依赖安装
- **修改 PIP 源**：取消 `Dockerfile` 中 `PIP_EXTRA_INDEX_URL` 的注释。
- **手动下载模型**：将模型文件放置到挂载目录 `models/Stable-diffusion`。

### 2. 调试构建问题
- **临时禁用步骤**：若 `git clone` 失败，可手动克隆到容器内路径。

---

## 重要提示

### 挂载目录权限
```bash
# 必须设置挂载目录归属为 1000:1000
sudo chown -R 1000:1000 /path/to/models /path/to/outputs
```

### 网络问题处理
- **首次启动**：手动下载模型避免拉取失败
- **代理配置**：在 Dockerfile 中设置 `http_proxy` 环境变量

---

## 常见问题

### Q1：构建时出现 `git clone` 失败
- **解决方案**：检查网络或手动克隆仓库到指定目录。

### Q2：启动后无法访问 WebUI
- **检查端口映射**：确认 `-p 7860:7860` 参数正确
- **查看日志**：使用 `docker logs <容器ID>` 排查错误

> 更多问题请参考 [AUTOMATIC1111/stable-diffusion-webui 官方文档](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki)
