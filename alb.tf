resource "aws_security_group" "alb_sg" {
  name        = "springboot-alb-sg"
  description = "Allow inbound HTTP/HTTPS traffic to ALB"
  vpc_id      = data.aws_vpc.default_primary.id

  ingress {
    description = "HTTP Public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "springboot-alb-sg"
  }
}

resource "aws_lb" "app_alb" {
  name               = "springboot-cards-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.primary.ids

  tags = {
    Name = "springboot-cards-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "springboot-cards-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default_primary.id
  target_type = "instance"

  health_check {
    path                = "/api/cards"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "primary_instance_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.cards_service_r1.id
  port             = var.app_port
}
