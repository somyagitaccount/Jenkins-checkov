# ---------------------------
# 1. Public S3 bucket (NO encryption, NO versioning)
# ---------------------------
resource "aws_s3_bucket" "insecure_bucket" {
  bucket = "checkov-insecure-bucket-demo-12345"
  acl    = "public-read"
}

# ❌ Missing:
# - encryption
# - versioning
# - block public access

# ---------------------------
# 2. Security Group open to the world
# ---------------------------
resource "aws_security_group" "open_sg" {
  name        = "open-security-group"
  description = "Allow all traffic"
  vpc_id      = "vpc-123456"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# 3. EC2 instance without IMDSv2
# ---------------------------
resource "aws_instance" "insecure_ec2" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional" # ❌ Should be "required"
  }
}

# ---------------------------
# 4. Unencrypted EBS volume
# ---------------------------
resource "aws_ebs_volume" "unencrypted_volume" {
  availability_zone = "us-east-1a"
  size              = 10
  encrypted         = false
}

# ---------------------------
# 5. IAM policy with admin access
# ---------------------------
resource "aws_iam_policy" "admin_policy" {
  name = "admin-policy-demo"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}
