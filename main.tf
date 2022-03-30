provider "aws" {
  region  = "us-east-1"
  profile = "default"
}


resource "aws_vpc" "terraform-vpc" {
  cidr_block                       = "10.10.0.0/16"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_subnet" "terraform-subnet-01" {
  vpc_id            = aws_vpc.terraform-vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "terraform-subnet-01"
  }
}
resource "aws_subnet" "terraform-subnet-02" {
  vpc_id            = aws_vpc.terraform-vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "terraform-subnet-02"
  }
}
resource "aws_subnet" "terraform-subnet-03" {
  vpc_id            = aws_vpc.terraform-vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "terraform-subnet-03"
  }
}

resource "aws_internet_gateway" "terraform-ig" {
  vpc_id = aws_vpc.terraform-vpc.id
  tags = {
    Name = "terraform-ig"
  }
}



resource "aws_route_table" "terraform-router" {
  vpc_id = aws_vpc.terraform-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-ig.id
  }
  tags = {
    Name = "terraform-router"
  }
}

resource "aws_route_table_association" "terraform-attach-subnet" {
  subnet_id      = aws_subnet.terraform-subnet-01.id
  route_table_id = aws_route_table.terraform-router.id
}
resource "aws_route_table_association" "terraform-attach-subnet2" {
  subnet_id      = aws_subnet.terraform-subnet-02.id
  route_table_id = aws_route_table.terraform-router.id
}

# resource "aws_eip" "random-ip" {
#   vpc = true
#   tags = {
#     Name = "random-ip"
#   }
# }

# resource "aws_nat_gateway" "terraform-nat-gw" {
#   allocation_id = aws_eip.random-ip.id
#   subnet_id     = aws_subnet.terraform-subnet-01.id

#   tags = {
#     Name = "terraform-nat-gw"
#   }
# }

# resource "aws_route_table" "terraform-nat-gw-route-table" {
#   vpc_id = aws_vpc.terraform-vpc.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.terraform-nat-gw.id
#   }
# }

# resource "aws_route_table_association" "terraform-assign-nat-to-subnet" {
#   subnet_id      = aws_subnet.terraform-subnet-02.id
#   route_table_id = aws_route_table.terraform-nat-gw-route-table.id
# }


resource "aws_security_group" "terraform-sg" {
  name        = "terraform-sg"
  description = "terraform security group"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    description = "Inbound Rule"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # for kubernetes api server
  ingress {
    description = "Inbound Rule"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Inbound Rule"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-sg"
  }
}

variable "ami" {
  type    = string
  default = "ami-0c02fb55956c7d316"
}

resource "aws_key_pair" "terraform-key" {
  key_name   = "terraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDJ8AX0K59CfTU94JYqz3yDOhfq2WuWS58syx/T38SDPna4QWcr367RUJR4fejq7Liih4mo4XefqLe0yLE5vbSWLoJkTVp9s8Mj/DtuL5EYann+FUSVXmYcPp8f1FcNKzL4Vmf9ZLwvU8CwSGX35ildnVXR1x1DS0akKGVmxQxjLJTvm1XUL8Bl8R6TJLvAq3XsNnNoCeFICEd42gQFm2A8+5ayt9uFrp0LC8tKQb0HDrumF3JOaMyXyVnhOSnQJiS7AmBnYBvaXM8Xr3bU0GGLvgK5HEOc/jSMRo//bMrc/lNqzKR/YHGwoRzeNEhVrTiSOTdkV9CCl3be3H33RcjjfHCylKenEj1ECzqnqiYg9RsPpN3laBcvDZNoJ5N3EKi8hSX3b7xArQvWY95zoyH/MTYvuT+a0CDgVmYBoi7V2Sau4Y3PMX2VQ9R47DYYGVQB3eSJgJTb2WklaGTVplnzg8huv/bipR52NVDQYOGQYp4UdtnwH5SKn6XZuxYj4Z8= getma@DESKTOP-59V52CL"
}



resource "aws_instance" "terraform-instance" {
  ami                         = var.ami
  instance_type               = "t3.large"
  subnet_id                   = aws_subnet.terraform-subnet-01.id
  security_groups             = [aws_security_group.terraform-sg.id]
  key_name                    = "terraform-key"
  associate_public_ip_address = true
  tags = {
    Name = "terraform-instance-25-03-2022"
  }
  user_data = file("script.sh")

  provisioner "file" {
    source      = "credentials/ashish_key"
    destination = "/home/ec2-user/private_key"
  }

  provisioner "file" {
    source      = "worker_script.sh"
    destination = "/home/ec2-user/worker_script.sh"
  }
  provisioner "file" {
    source      = "worker_script2.sh"
    destination = "/home/ec2-user/worker_script2.sh"
  }
  provisioner "file" {
    source      = "worker_script3.sh"
    destination = "/home/ec2-user/worker_script3.sh"
  }
   ebs_block_device {
    volume_size = 40
    device_name = "/dev/xvdba"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 50",
      "sudo chmod +x /home/ec2-user/worker_script.sh",
      "sudo chown ec2-user:root /home/ec2-user/worker_script.sh",
      "sudo /home/ec2-user/worker_script.sh > /home/ec2-user/worker.sh",
      "sudo chmod +x /home/ec2-user/worker.sh",
      "sudo chmod +x /home/ec2-user/worker_script2.sh",
      "sudo chown ec2-user:root /home/ec2-user/worker_script2.sh",
      "sudo /home/ec2-user/worker_script2.sh > /home/ec2-user/worker2.sh",
      "sudo chmod +x /home/ec2-user/worker2.sh",
      "sudo chmod +x /home/ec2-user/worker_script3.sh",
      "sudo chown ec2-user:root /home/ec2-user/worker_script3.sh",
      "sudo /home/ec2-user/worker_script2.sh > /home/ec2-user/worker3.sh",
      "sudo chmod +x /home/ec2-user/worker3.sh",
      "sudo chmod 400 /home/ec2-user/private_key",
      "sudo scp -o StrictHostKeyChecking=no -i private_key /home/ec2-user/worker.sh /home/ec2-user/worker2.sh /home/ec2-user/worker3.sh ec2-user@${aws_instance.terraform-instance-private.private_ip}:/home/ec2-user/",
      "sudo ssh -o StrictHostKeyChecking=no -i private_key  ec2-user@${aws_instance.terraform-instance-private.private_ip} '/home/ec2-user/worker.sh && /home/ec2-user/worker2.sh && /home /ec2-user/worker3.sh && rm worker.sh' ",
      "rm -rf /home/ec2-user/script.sh  /home/ec2-user/worker.sh "
    ]
  }
  connection {
    user        = "ec2-user"
    host        = self.public_ip
    type        = "ssh"
    private_key = file("credentials/ashish_key")
  }
}


resource "aws_security_group" "terraform-sg-private" {
  name        = "terraform-sg-private"
  description = "terraform security[private] group"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  tags = {
    Name = "terraform-sg-[private]"
  }
}


resource "aws_instance" "terraform-instance-private" {
  ami             = var.ami
  instance_type   = "t3.large"
  subnet_id       = aws_subnet.terraform-subnet-02.id
  security_groups = [aws_security_group.terraform-sg-private.id]
  key_name        = "terraform-key"
  tags = {
    Name = "terraform-instance-25-03-2022-[private]"
  }
  associate_public_ip_address = true
  ebs_block_device {
    volume_size = 40
    device_name = "/dev/xvdba"
  }
}


output "private-ip" {
  value = aws_instance.terraform-instance-private.private_ip
}



