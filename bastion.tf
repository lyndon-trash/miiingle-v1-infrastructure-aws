
data "aws_ami" "amazon_linux_2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "bastion" {
  count                       = var.create_bastion ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true

  security_groups = [aws_security_group.bastion_sg.id, module.vpc.default_security_group_id]
  key_name        = aws_key_pair.bastion_key.key_name
  subnet_id       = module.vpc.public_subnets[0]

  tags = merge(
    {
      Name = format("%s-BastionInstance", local.vpc_name)
    },
    local.common_tags
  )
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "BastionKey"
  public_key = var.bastion_public_key

  tags = merge(
    {
      Name = format("%s-BastionKey", local.vpc_name)
    },
    local.common_tags
  )
}

resource "aws_security_group" "bastion_sg" {
  name        = "SG Bastion"
  description = "Allow SSH inbound traffic for the bastion instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from a Secure Location"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_source_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = format("%s-BastionInstance", local.vpc_name)
    },
    local.common_tags
  )
}