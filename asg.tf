resource "aws_launch_template" "app_lt" {
  name_prefix   = "springboot-lt-"
  image_id      = var.ami_primary
  instance_type = "t2.micro"
  key_name      = "umoh2"

  vpc_security_group_ids = [aws_security_group.cards_sg_r1.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -e

              # 1. Install Java and AWS CLI
              apt-get update -y
              apt-get install -y openjdk-17-jre-headless awscli

              # 2. Setup application folder
              mkdir -p /opt/cards
              cd /opt/cards

              # 3. Pull JAR from S3
              aws s3 cp s3://${aws_s3_bucket.app_artifacts.id}/${aws_s3_object.cards_jar.key} /opt/cards/app.jar

              # 4. Create systemd daemon
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

              [Install]
              WantedBy=multi-user.target
              SERVICE

              # 5. Start and enable service
              chown -R ubuntu:ubuntu /opt/cards
              systemctl daemon-reload
              systemctl enable cards.service
              systemctl start cards.service
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "cards-service-asg-worker"
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "springboot-asg-"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = data.aws_subnets.primary.ids
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "cards-service-asg-worker"
    propagate_at_launch = true
  }
}
