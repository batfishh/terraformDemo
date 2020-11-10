#CLI GIT CHANGE
provider "aws" { 
  access_key = ""
  secret_key = ""
  region = "ap-south-1"
}

variable "subnet_cidrs" {
  default = ["10.0.0.0/28","10.0.0.16/28"]
}

variable "av_zones" {
  default = ["ap-south-1a","ap-south-1b","ap-south-1c"]
}

variable "sub_ids" {
  default = ["subnet-1test","subnet-2test"]
}

resource "aws_instance" "deskins" {
  ami = "ami-0e40fcc38b5870850"
  instance_type = "t2.micro"
  # availability_zone = "ap-south-1a"
  key_name = "mumbai"
  subnet_id = aws_subnet.terraSUB[1].id
  vpc_security_group_ids = [aws_security_group.desk-sec.id]
  tags = {
    Name = "Desktop Instance"
  }
}
resource "aws_ebs_volume" "data-vol" {
  availability_zone = "ap-south-1b"
  size = 1
  tags = {
    Name = "data-volume"
  }
}

resource "aws_volume_attachment" "first-vol" {
  device_name = "/dev/sdc"
  volume_id = aws_ebs_volume.data-vol.id
  instance_id = aws_instance.deskins.id
}
resource "aws_security_group" "desk-sec" {
  name = "desk-sec"
  vpc_id = aws_vpc.terraVPC.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_vpc" "terraVPC" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "terraGW" {
  vpc_id = aws_vpc.terraVPC.id
}

resource "aws_eip" "default" {
  instance = aws_instance.deskins.id
  vpc      = true
}

resource "aws_subnet" "terraSUB" {
  count = length(var.subnet_cidrs)
  vpc_id = aws_vpc.terraVPC.id
  cidr_block = var.subnet_cidrs[count.index] 
  map_public_ip_on_launch = true
  availability_zone = var.av_zones[count.index]
  tags = {
    Name = "SUBBBB"
  }
}


resource "aws_lb" "my-aws-alb" {
  name     = "my-test-alb"
  internal = false
  security_groups = [aws_security_group.my-alb-sg.id]

  subnets = [
    aws_subnet.terraSUB[0].id,
    aws_subnet.terraSUB[1].id
  ]

  tags = {
    Name = "my-test-alb"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.my-aws-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.terraTarget.arn
  }
}

resource "aws_lb_target_group" "terraTarget" {
  name     = "terra-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraVPC.id
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.terraTarget.arn
  target_id        = aws_instance.deskins.id
  port             = 80
}



resource "aws_security_group" "my-alb-sg" {
  name   = "my-alb-sg"
  vpc_id = aws_vpc.terraVPC.id
}

resource "aws_security_group_rule" "inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
