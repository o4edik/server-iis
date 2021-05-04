
#  Create 2 EC2 instances
#  Provision 2 win2019 servers

provider "aws" {
    region = "us-east-2"
    access_key = "AKIATOVFJ5CN5H6FQ5TI"
    secret_key = "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"
}

# 1. Create vpc
resource "aws_vpc" "iis-vpc" {
  cidr_block       = "10.0.0.0/16"
  
  tags = {
    Name = "IIS-VPC"
  }
}
#  Internet gateway
 resource "aws_internet_gateway" "gw" {
     vpc_id = aws_vpc.iis-vpc.id  
tags = {
      Name = "Gate"
 }
 }
#  Create Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.iis-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Route"
  }
}
# 2.Create subnets
resource "aws_subnet" "dev-subnet" {
  vpc_id     = aws_vpc.iis-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev"
  }
}
resource "aws_subnet" "prod-subnet" {
  vpc_id     = aws_vpc.iis-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "prod"
  }
}

# Assosiate subnet with Route Table
resource "aws_route_table_association" "dev" {
    subnet_id = aws_subnet.dev-subnet.id
    route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "prod" {
    subnet_id = aws_subnet.prod-subnet.id
    route_table_id = aws_route_table.rt.id
}  
 # Create Security Group
resource "aws_security_group" "iis-sg" {
  name = "Dynamic Security Group"
  vpc_id = aws_vpc.iis-vpc.id

  dynamic "ingress" {
    for_each = ["80", "443", "22", "3389", "5985"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "IIS-SG"
  }
}
#  Create Network Interface
resource "aws_network_interface" "dev"{
  subnet_id = aws_subnet.dev-subnet.id
  private_ips  = ["10.0.1.50"]
  security_groups = [aws_security_group.iis-sg.id]
}
resource "aws_network_interface" "prod"{
subnet_id = aws_subnet.prod-subnet.id
private_ips = ["10.0.2.50"]
security_groups = [aws_security_group.iis-sg.id]
}
#  Assign an EIP to the Network Interface
resource "aws_eip" "dev" {
    vpc = true
    network_interface = aws_network_interface.dev.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.gw]
}
resource "aws_eip" "prod" {
    vpc = true
    network_interface = aws_network_interface.prod.id
    associate_with_private_ip = "10.0.2.50"
    depends_on = [aws_internet_gateway.gw]
}
#  5. Create Network Load Balancer
resource "aws_lb" "nlb" {
  name = "nlb-lb"
  load_balancer_type = "network"
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
  internal = true


  subnet_mapping {
    subnet_id = aws_subnet.dev-subnet.id
  }
  
  subnet_mapping {
    subnet_id = aws_subnet.prod-subnet.id
  }
  }
resource "aws_instance" "dev" {
  ami           = "ami-0b697c4ae566cad55"
  instance_type = "t2.micro"
  key_name = "iis-key"
  get_password_data = true
  availability_zone = "us-east-2a"
  network_interface {
    network_interface_id = aws_network_interface.dev.id
    device_index = 0
  }
user_data = <<EOF
<powershell>
Enable-PSRemoting
New-NetFirewallRule -DisplayName "WHITELIST TCP" -Direction inbound -Profile Any -Action Allow -LocalPort 80,8080,8090,5985,443,22 -Protocol TCP 
</powershell>
EOF

  tags = {
    Name = "DEV"
  }

}


resource "aws_instance" "prod" {
  ami           = "ami-0b697c4ae566cad55"
  instance_type = "t2.micro"
  key_name = "iis-key"
  get_password_data = true
  availability_zone = "us-east-2b"
    network_interface {
    network_interface_id = aws_network_interface.prod.id
    device_index = 0
  }
  user_data = <<EOF
<powershell>
Enable-PSRemoting
New-NetFirewallRule -DisplayName "WHITELIST TCP" -Direction inbound -Profile Any -Action Allow -LocalPort 80,8080,8090,5985,443,22 -Protocol TCP 
</powershell>
EOF
  tags = {
    Name = "PROD"
  }

}
output "dev_public_ip" {
    value = aws_eip.dev.public_ip
}
output "prod_public_ip" {
    value = aws_eip.prod.public_ip
}
output "nlb_dns" {
  value = aws_lb.nlb.dns_name
}