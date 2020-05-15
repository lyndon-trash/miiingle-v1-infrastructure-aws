
// Read me for more infor
//https://www.terraform.io/docs/providers/aws/r/instance.html

//resource "aws_instance" "bastion" {
//  instance_type = "t2.micro"
//
//  tags = {
//    Name = "HelloWorld"
//  }
//}

resource "aws_security_group" "bastion_sg" {
  name        = "SG Bastion"
  description = "Allow SSH inbound traffic for the bastion instance"
  vpc_id      = aws_vpc.main.id

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