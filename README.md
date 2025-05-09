# Stable Diffusion WebUI Docker 项目

本项目通过 Docker 容器化技术提供 Stable Diffusion WebUI 的快速部署方案，支持 GPU 加速与多场景定制化配置，简化深度学习模型的部署流程。

> 原始项目 [AUTOMATIC1111/stable-diffusion-webui 官方文档](https://github.com/AUTOMATIC1111/stable-diffusion-webui)

---

## 核心功能

- 全容器化部署：一键启动 WebUI 服务，无需手动配置 Python/CUDA 环境
- 多版本兼容：支持 PyTorch 2.5 + CUDA 12.4，适配 30/40 系 NVIDIA 显卡
- 智能重试机制：内置 Git 克隆失败自动重试，应对网络波动
- 权限隔离：非 root 用户运行，保障容器安全性
- 模块化存储：通过 Volume 分离代码、模型与生成数据

---

## 快速部署指南

### 环境要求
- Linux 系统（推荐 Ubuntu 22.04 LTS）
- NVIDIA 驱动 ≥ 525.60.13
- Docker 23.0+ 与 Docker Compose 2.20+
- NVIDIA Container Toolkit 1.13+

### 启动步骤
```bash
# 克隆项目仓库
git clone https://github.com/sharks-king/docker-stable-diffusion-webui
cd docker-stable-diffusion-webui

# 初始化存储目录（保持默认权限）
mkdir -p ./docker-copose/{embeddings,extensions,inputs,localizations,models,outputs,repositories,textual_inversion_templates}

# 刷新权限
chown 1000:1000 -R ./docker-copose/*

# 进入 docker-copose 目录
cd ./docker-copose/

# 启动服务(初次会构建镜像，如不想构建镜像请修改docker-compose文件，文件内提供了我构建好的镜像地址)
docker-compose up -d

# 查看实时日志
docker-compose logs -f

# 停止服务
docker-compose stop

# 终止服务
docker-compose down
```

### 访问入口
```
http://<your-server-ip>:7860
```

> 更多问题请参考 [AUTOMATIC1111/stable-diffusion-webui 官方文档](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)



