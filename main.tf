provider "aws" {
  region    =   "eu-north-1"
  access_key = ""
  secret_key = ""
}


resource "random_shuffle" "az" {
    input = var.availability_zones
    result_count = length(var.availability_zones)
  
}

#create vpc
resource "aws_vpc" "tr-test-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "tr-test-vpc"
    }
  
}

#subnet creation
resource "aws_subnet" "pubsub" {
    count = 2
    vpc_id = aws_vpc.tr-test-vpc.id
    cidr_block = var.subnet_prefix.pub[count.index]
    availability_zone = random_shuffle.az.result[count.index % length(random_shuffle.az.result)]
    tags = {
      "Name" = "pubsub${count.index}"
    }
}

resource "aws_subnet" "cachesub" {
    count = 2
    vpc_id = aws_vpc.tr-test-vpc.id
    cidr_block = var.subnet_prefix.cache[count.index]
    availability_zone = random_shuffle.az.result[count.index % length(random_shuffle.az.result)]
    tags = {
      "Name" = "cachesub${count.index}"
    }
  
}

resource "aws_subnet" "prvsub" {
    count = 2
    vpc_id = aws_vpc.tr-test-vpc.id
    cidr_block = var.subnet_prefix.prv[count.index]
    availability_zone = random_shuffle.az.result[count.index % length(random_shuffle.az.result)]
    tags = {
      "Name" = "prvsub${count.index}"
    }
}


#create igw
resource "aws_internet_gateway" "tr-igw" {
    vpc_id = aws_vpc.tr-test-vpc.id
    tags = {
      "Name" = "tr-igw"
    }
  
}

#create eip
resource "aws_eip" "nat-eip" {
    vpc = true
    tags = {
      "Name" = "nat-eip"
    }
  
}

#create NATGateway
resource "aws_nat_gateway" "tr-nat" {
    allocation_id = aws_eip.nat-eip.id
    subnet_id = aws_subnet.pubsub[0].id
}


#rout table creation
resource "aws_route_table" "tr-public-rt" {
    vpc_id = aws_vpc.tr-test-vpc.id
    tags = {
      "Name" = "tr-public-rt"
    }
}

resource "aws_route_table" "tr-private-rt" {
    vpc_id = aws_vpc.tr-test-vpc.id
    tags = {
      "Name" = "tr-private-rt"
    }
  
}


#create route
resource "aws_route" "rout_to_internet" {
    route_table_id = aws_route_table.tr-public-rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tr-igw.id

}

resource "aws_route" "rout_to_nat" {
    route_table_id = aws_route_table.tr-private-rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tr-nat.id
  
}

#routing assosiations to subnet
resource "aws_route_table_association" "association_for_rout_to_igw" {
    count = 2
    route_table_id = aws_route_table.tr-public-rt.id
    subnet_id = aws_subnet.pubsub[count.index].id
  
}

resource "aws_route_table_association" "association_for_rout_to_nat" {
    count = 2
    route_table_id = aws_route_table.tr-private-rt.id
    subnet_id = aws_subnet.cachesub[count.index].id
  
}

#public sg creation
resource "aws_security_group" "pub-sg" {
    name = "pub-sg"
    description = "allow-app"
    vpc_id = aws_vpc.tr-test-vpc.id
    tags = {
      "Name" = "pub-sg"
    }
}

#rules
resource "aws_security_group_rule" "r1" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.pub-sg.id
}

resource "aws_security_group_rule" "r2" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.pub-sg.id
}


resource "aws_security_group" "pr-sg1" {
    name = "pr-sg1"
    description = "allow-pub-trffc-to-cache"
    vpc_id = aws_vpc.tr-test-vpc.id
    tags = {
      "Name" = "pr-sg1"
    }
}

resource "aws_security_group" "pr-sg2" {
    name = "pr-sg2"
    description = "allow-pub-trffc-to-cms"
    vpc_id = aws_vpc.tr-test-vpc.id
    tags = {
      "Name" = "pr-sg2"
    }
}

resource "aws_instance" "bastian" {
    count = 2
    ami = "ami-0bf2ce41790745811"
    instance_type = "t3.micro"
    availability_zone = random_shuffle.az.result[count.index % length(random_shuffle.az.result)]
    key_name = "first-key"
    subnet_id = aws_subnet.pubsub[count.index].id
    private_ip = var.pri-ip[count.index]
    tags = {
      "Name" = "bastian${count.index}"
    }

}

resource "aws_eip" "bar" {
    count = 2
    vpc = true
    instance = aws_instance.bastian[count.index].id
    associate_with_private_ip = var.pri-ip[count.index]
  
  
}