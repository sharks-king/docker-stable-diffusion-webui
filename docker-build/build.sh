#!/bin/bash

DATE=`date +"%Y%m%d_%H%M%S"`

docker buildx build -t stable-diffusion-webui:v1.10.1-${DATE}-$1 -f Dockerfile --platform=linux/amd64 . --push
