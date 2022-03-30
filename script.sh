#!/bin/bash
sudo yum install docker git -y
sudo systemctl start docker

sudo usermod -aG docker ec2-user

sudo docker run -d -p 5000:5000 --restart=always -e REGISTRY_STORAGE_DELETE_ENABLED=true --name registry registry:2

export INSTANCE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

sudo systemctl restart docker

sudo cat << EOF >> /home/ec2-user/registries.yaml
mirrors:
  docker.io:
    endpoint:
      - "https://registry-1.docker.io"
  $INSTANCE_IP:5000:
    endpoint:
      - "http://$INSTANCE_IP:5000"
EOF

curl -sfL https://get.k3s.io | sh -
chown ec2-user:root /etc/rancher/k3s/k3s.yaml