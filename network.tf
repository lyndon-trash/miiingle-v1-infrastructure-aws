
resource "aws_vpc" "main" {
  cidr_block = var.base_cidr_block
  tags = merge(
    {
      Name = local.vpc_name
    },
    local.common_tags
  )
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 1 + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name       = format("%s-Subnet-Private-%d", local.vpc_name, count.index + 1)
      SubnetType = "private"
    },
    local.common_tags
  )
}

resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 1)
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name       = format("%s-Subnet-Public-%d", local.vpc_name, count.index + 1)
      SubnetType = "public"
    },
    local.common_tags
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = format("%s-IGW", local.vpc_name)
    },
    local.common_tags
  )
}

resource "aws_route_table_association" "public_subnet_to_route_table_association" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    {
      Name       = format("%s-RouteTable-Public", local.vpc_name)
      SubnetType = "public"
    },
    local.common_tags
  )
}

resource "aws_network_acl" "public" {
  count = length(var.availability_zones) > 0 ? 1 : 0

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public.*.id

  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    {
      Name       = format("%s-ACL-Public", local.vpc_name)
      SubnetType = "public"
    },
    local.common_tags
  )
}

//default route table locked down
resource "aws_default_route_table" "default_routes" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = merge(
    {
      Name = format("%s-RouteTable-Default", local.vpc_name)
    },
    local.common_tags
  )
}

//default network ACL locked down
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id

  tags = merge(
    {
      Name = format("%s-ACL-Default", local.vpc_name)
    },
    local.common_tags
  )
}

resource "aws_network_acl_rule" "ssh_internal_outbound" {
  network_acl_id = aws_default_network_acl.default.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_vpc.main.cidr_block
}

resource "aws_network_acl_rule" "ssh_internal_inbound" {
  network_acl_id = aws_default_network_acl.default.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_vpc.main.cidr_block
}

//default SG locked down
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  //we only allow internal,instance-to-instance communication by default
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }
  tags = merge(
    {
      Name = format("%s-SG-Default", local.vpc_name)
    },
    local.common_tags
  )
}