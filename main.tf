# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = {
    Name = "testvpc"
  }
}
# Subnets
# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
 
 tags = {
    Name = "my-igw"
  }
}

# Public subnets
resource "aws_subnet" "public_subnet-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "terraformPubSubnet1"
  }
}
resource "aws_subnet" "public_subnet-2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "terraformPubSubnet2"
  }
}
# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = {
    Name = "public-route-table"
  }
}
# Route for Internet Gateway

# Subnet association for public route table
resource "aws_route_table_association" "publicRT1" {
  subnet_id      = aws_subnet.public_subnet-1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "publicRT2" {
  subnet_id      = aws_subnet.public_subnet-2.id
  route_table_id = aws_route_table.public.id
}


# Private subnets
#resource "aws_subnet" "private_subnet-1" {
 # vpc_id                  = aws_vpc.vpc.id
  #cidr_block              = "192.168.3.0/24"
  #availability_zone       = "us-west-1"
  #map_public_ip_on_launch = false

  #tags = {
   # Name = "terraform-Private-Subnet-1"
  #}
#}
#resource "aws_subnet" "private_subnet-2" {
  #vpc_id                  = aws_vpc.vpc.id
#  cidr_block              = "192.168.4.0/24"
 # availability_zone       = "us-west-1"
 # map_public_ip_on_launch = false

  #tags = {
   # Name = "terraform-Private-Subnet-2"
  
# Elastic-IP (eip) for NAT
resource "aws_eip" "nat_eip" {

}
# # NAT
# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.nat_eip.id
#   subnet_id     = aws_subnet.public_subnet-2.id
#   tags = {
#     Name = "nat"
#   }
# }

# Routing tables to route traffic for Private Subnet
#resource "aws_route_table" "private" {
 # vpc_id = aws_vpc.vpc.id

 # tags = {
 #   Name = "private-route-table"
 # }
#}
# # Route for NAT
# resource "aws_route" "private_nat_gateway" {
#   route_table_id         = aws_route_table.private.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.nat.id
# }

# Subnet association for private route table
#resource "aws_route_table_association" "privateRT1" {
 # subnet_id      = aws_subnet.private_subnet-1.id
  #route_table_id = aws_route_table.private.id
#}
#resource "aws_route_table_association" "privateRT2" {
 # subnet_id      = aws_subnet.private_subnet-2.id
  #route_table_id = aws_route_table.private.id
#}

# Security group creation
resource "aws_security_group" "default" {
  name        = "all-traffic-sg"
  description = "Default SG to alllow traffic from the VPC"
  vpc_id      = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "all"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "all"
    self        = "true"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#instance launcing with jenkins-master as an user data
resource "aws_instance" "new" {
  ami                    = "ami-0646513672e4fb341"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_subnet-1.id
  key_name               = "cal.mahi"
  vpc_security_group_ids = [aws_security_group.default.id]
  user_data              = file("sh.sh")
  tags = {
    Name = "Jenkins-Instance"
  }
}

# attaching elastic ip to jenkins-master 
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.new.id
  allocation_id = aws_eip.nat_eip.id
}


#instance launcing with jenkins-slave
resource "aws_instance" "slave" {
  ami                    = "ami-0646513672e4fb341"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_subnet-1.id
  key_name               = "cal.mahi"
  vpc_security_group_ids = [aws_security_group.default.id]
  user_data              = file("slave.sh")
  tags = {
    Name = "Jenkins-Instance-Slave"
  }
}

