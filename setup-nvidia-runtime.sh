#!/bin/bash

curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list

sudo apt update

sudo apt-get install nvidia-container-runtime

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --host=fd:// --add-runtime=nvidia=/usr/bin/nvidia-container-runtime
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

#docker build -t ffmpeg-nvenc-bento4:latest .

#docker run --runtime=nvidia -ti --rm --tmpfs /tmp ffmpeg-nvenc-bento4