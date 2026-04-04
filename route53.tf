# ==========================================
# Route 53 DNS Configuration
# ==========================================

data "aws_route53_zone" "selected" {
  name         = "${var.domain_name}."
  private_zone = false
}

# A record pointing to the ALB
resource "aws_route53_record" "clixx" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.app_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.clixx_lb.dns_name
    zone_id                = aws_lb.clixx_lb.zone_id
    evaluate_target_health = true
  }
}

# CNAME redirect for www subdomain
resource "aws_route53_record" "www_clixx" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.app_fqdn_www
  type    = "CNAME"
  ttl     = 300
  records = [local.app_fqdn]
}
