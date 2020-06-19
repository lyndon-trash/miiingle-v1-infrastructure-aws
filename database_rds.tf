resource "aws_db_instance" "db_transaction" {
  instance_class        = "db.t2.micro"
  storage_type          = "gp2"
  allocated_storage     = 50
  max_allocated_storage = 100
  identifier            = random_pet.rds_identifier.id
  username              = "postgres"
  password              = "P0sT9r3s1.E45g"

  engine                 = "postgres"
  engine_version         = "11.6"
  publicly_accessible    = false
  port                   = var.rds_port
  vpc_security_group_ids = [aws_security_group.db_transaction.id]
  db_subnet_group_name   = aws_db_subnet_group.transaction_db.name

  final_snapshot_identifier = "final-snapshot-${random_pet.rds_identifier.id}"
  deletion_protection       = false

  tags = local.common_tags
}

resource "aws_db_subnet_group" "transaction_db" {
  name       = "main"
  subnet_ids = module.vpc.private_subnets

  tags = merge({
    Name = "RDS Subnets"
  }, local.common_tags)
}

resource "random_pet" "rds_identifier" {
  prefix = "rds"
}

resource "aws_security_group" "db_transaction" {
  name        = "SG RDS Postgres"
  description = "Allow Postgres traffic into RDS"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${module.vpc.name}-RDS Postgres SG"
  }, local.common_tags)
}

resource "aws_security_group_rule" "rds_ingress_bastion" {
  count                    = var.create_bastion ? 1 : 0
  description              = "Allow the Bastion instance access to Postgres"
  from_port                = var.rds_port
  to_port                  = var.rds_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_transaction.id
  source_security_group_id = aws_security_group.bastion_sg.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "rds_ingress_worker" {
  description              = "Allow workers pods access to Postgres"
  from_port                = var.rds_port
  to_port                  = var.rds_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_transaction.id
  source_security_group_id = module.eks_cluster.cluster_primary_security_group_id
  type                     = "ingress"
}

variable "rds_port" {
  description = "PostgreSQL Port"
  type        = number
  default     = 5432
}