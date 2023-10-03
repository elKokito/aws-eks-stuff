# Get latest AMI ID for Amazon Linux2 OS
data "aws_ami" "amzlinux2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# AWS Availability Zones Datasource
data "aws_availability_zones" "available" {
}


data "aws_partition" "current" {}

data "aws_route53_zone" "aprehende" {
  name = "aprehen.de"
}

resource "aws_route53_record" "test" {
  zone_id = data.aws_route53_zone.aprehende.zone_id
  name = "test.aprehen.de"
  type = "A"
  ttl = 300
  records = ["23.16.27.13"]
}

module "acm" {
  source = "terraform-aws-modules/acm/aws"
  version = "~>4.0"

  domain_name = "aprehen.de"
  zone_id = data.aws_route53_zone.aprehende.zone_id

  subject_alternative_names = [
    "*.aprehen.de"
  ]
  wait_for_validation = true
  tags = {
    Name = "aprehen.de"
  }
}
