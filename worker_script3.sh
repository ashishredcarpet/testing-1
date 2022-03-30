sudo yum install docker git -y
sudo systemctl start docker

sudo usermod -aG docker ec2-user

sudo docker run -d -p 5000:5000 --restart=always -e REGISTRY_STORAGE_DELETE_ENABLED=true --name registry registry:2


sudo systemctl restart docker

sudo cat << EOF >> /home/ec2-user/registries.yaml
mirrors:
  docker.io:
    endpoint:
      - "https://registry-1.docker.io"
  ${master_local_ip}:5000:
    endpoint:
      - "http://$master_local_ip:5000"
EOF
