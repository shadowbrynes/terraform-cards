resource "aws_s3_bucket" "app_artifacts" {
  bucket_prefix = "cards-service-artifacts-"
  force_destroy = true
}

resource "aws_s3_object" "cards_jar" {
  bucket = aws_s3_bucket.app_artifacts.id
  key    = "account-0.0.1-SNAPSHOT.jar"
  source = var.jar_source_path
  etag   = filemd5(var.jar_source_path)
}

resource "aws_iam_role" "ec2_s3_access" {
  name = "cards-service-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "s3_read_policy" {
  name = "cards-service-s3-read-policy"
  role = aws_iam_role.ec2_s3_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Effect = "Allow"
      Resource = [
        aws_s3_bucket.app_artifacts.arn,
        "${aws_s3_bucket.app_artifacts.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "cards-service-ec2-profile"
  role = aws_iam_role.ec2_s3_access.name
}
