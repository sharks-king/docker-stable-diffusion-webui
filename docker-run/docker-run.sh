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
  --entrypoint bash \
  registry.cn-hangzhou.aliyuncs.com/sharksking/stable-diffusion-webui:v1.10.1-20250107_100652-test \
  /app/entrypoint.sh --xformers --listen --port 7860 --api --skip-torch-cuda-test --enable-insecure-extension-access --no-half-vae --skip-install
