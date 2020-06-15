//TODO: deploy the homepage
resource "aws_s3_bucket" "frontend_website" {
  bucket        = "www.${var.domain_base}"
  acl           = "private"
  force_destroy = true

  website {
    redirect_all_requests_to = "https://app.${var.domain_base}"
  }

  tags = merge(
    {
      Name = "Static Website Bucket for www.${var.domain_base}"
    },
    local.common_tags
  )
}