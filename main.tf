data "aws_vpc" "default_primary" {
  default = true
}

data "aws_subnets" "primary" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_primary.id]
  }
}

# --- SECURITY GROUP ---
resource "aws_security_group" "cards_sg_r1" {
  name        = "springboot-cards-sg-r1"
  description = "Security group for cards microservice in us-east-1"
  vpc_id      = data.aws_vpc.default_primary.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Spring Boot Application Port"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "springboot-cards-sg-r1"
    Environment = "Production"
  }
}

# --- EC2 INSTANCE WITH AUTOMATED BOOTSTRAP ---
resource "aws_instance" "cards_service_r1" {
  ami                         = var.ami_primary
  instance_type               = "t2.micro"
  key_name                    = "umoh2"
  vpc_security_group_ids      = [aws_security_group.cards_sg_r1.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data_replace_on_change = true

  user_data = <<-USERDATA
              #!/bin/bash
              exec > /var/log/app-setup.log 2>&1
              set -ex

              echo "[1/4] Installing OpenJDK 17 and AWS CLI..."
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y openjdk-17-jre-headless awscli

              echo "[2/4] Downloading application artifact from S3..."
              mkdir -p /opt/cards
              aws s3 cp s3://${aws_s3_bucket.app_artifacts.id}/${aws_s3_object.cards_jar.key} /opt/cards/app.jar
              chown -R ubuntu:ubuntu /opt/cards
              chmod 500 /opt/cards/app.jar

              echo "[3/4] Creating systemd service unit..."
              cat << 'SERVICE' > /etc/systemd/system/cards.service
              [Unit]
              Description=Spring Boot Cards Microservice
              After=network.target

              [Service]
              User=ubuntu
              WorkingDirectory=/opt/cards
              ExecStart=/usr/bin/java -jar /opt/cards/app.jar
              SuccessExitStatus=143
              Restart=always
              RestartSec=10
              StandardOutput=journal
              StandardError=journal

              [Install]
              WantedBy=multi-user.target
              SERVICE

              echo "[4/4] Starting cards.service..."
              systemctl daemon-reload
              systemctl enable --now cards.service
              USERDATA

  tags = {
    Name        = "cards-service-us-east-1"
    Environment = "Production"
  }
}
