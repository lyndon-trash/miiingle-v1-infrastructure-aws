resource "aws_s3_bucket" "frontend_webapp" {
  bucket = "app.${var.domain_base}"
  acl    = "private"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://app.${var.domain_base}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  tags = merge(
    {
      Name = "Static Website Bucket for app.${var.domain_base}"
    },
    local.common_tags
  )
}

resource "aws_cloudfront_distribution" "frontend_webapp_distribution" {
  depends_on = [aws_acm_certificate.web_app]
  aliases    = ["app.${var.domain_base}"]

  origin {
    domain_name = aws_s3_bucket.frontend_webapp.bucket_domain_name
    origin_id   = "S3-app.${var.domain_base}"
  }

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-app.${var.domain_base}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "PH"]
    }
  }

  default_root_object = "index.html"
  enabled             = true

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.web_app.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}