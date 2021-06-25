
# vpc
resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my-vpc"
  }

  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.2.0/24"

  availability_zone_id = "use1-az1"

  tags = {
    Name = "public-subnet"
  }

  map_public_ip_on_launch = true
}


# internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "internet-gateway"
  }
}

# route table with target as internet gateway
resource "aws_route_table" "IG_route_table" {
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.internet_gateway,
  ]

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "IG-route-table"
  }
}

resource "aws_route_table_association" "associate_routetable_to_public_subnet" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_route_table.IG_route_table,
  ]
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.IG_route_table.id
}

# elastic ip
resource "aws_eip" "elastic_ip" {
  vpc = true
}

resource "aws_security_group" "sg_public_host" {
  depends_on = [
    aws_vpc.vpc,
  ]
  name        = "sg public host"
  description = "public host security group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "allow 8000"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "ec2_role_profile" {
  name = "test_profile"
  role = "${aws_iam_role.ec2_role.name}"
}

resource "aws_iam_role_policy" "ec2_role_policy" {
  name = "test_policy"
  role = "${aws_iam_role.ec2_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_instance" "webapp" {
  ami                    = "ami-07ebfd5b3428b6f4d"
  instance_type          = "t2.medium"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_public_host.id]
  subnet_id              = aws_subnet.public_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_role_profile.name
  user_data              = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install software-properties-common apt-transport-https ca-certificates curl -y
                sudo add-apt-repository ppa:deadsnakes/ppa
                sudo apt update -y
                sudo apt install python3.8 -y
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
                sudo apt update -y
                sudo apt install docker-ce -y
                sudo usermod -aG docker ubuntu
                newgrp docker
                sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                cd /home/ubuntu
                git clone https://github.com/Yeshreddy0405/modiface-assessment.git helloflask
                cd helloflask
                cp .env.example .env
                cp docker-compose.override.yml.example docker-compose.override.yml
                docker-compose up -d --build
                EOF
  tags = {
    Name = "app"
  }
}
