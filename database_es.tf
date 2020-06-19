resource "aws_elasticsearch_domain" "db_search" {
  cluster_config {
    instance_type  = "t2.medium.elasticsearch"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  vpc_options {
    subnet_ids         = [module.vpc.private_subnets[0]]
    security_group_ids = [aws_security_group.db_search.id]
  }

  domain_name           = random_pet.es_domain.id
  elasticsearch_version = "7.4"

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "AWS" : "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${var.aws_region}:*:domain/${random_pet.es_domain.id}/*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_security_group" "db_search" {
  name        = "SG Elasticsearch"
  description = "Allow SSL traffic into ES"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${module.vpc.name}-Elasticsearch SG"
  }, local.common_tags)
}

resource "aws_security_group_rule" "es_ingress_bastion" {
  count                    = var.create_bastion ? 1 : 0
  description              = "Allow the Bastion instance access to Elasticsearch API"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_search.id
  source_security_group_id = aws_security_group.bastion_sg.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "es_ingress_worker" {
  description              = "Allow workers pods access to Elasticsearch API"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_search.id
  source_security_group_id = module.eks_cluster.cluster_primary_security_group_id
  type                     = "ingress"
}

resource "random_pet" "es_domain" {
  prefix = "es"
}