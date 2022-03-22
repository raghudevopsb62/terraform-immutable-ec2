resource "aws_lb_target_group" "tg" {
  name     = "${var.COMPONENT}-${var.ENV}"
  port     = var.PORT
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.VPC_ID
  health_check {
    enabled             = true
    path                = "/health"
    unhealthy_threshold = 2
    healthy_threshold   = 2
    interval            = 5
    timeout             = 2
  }
}

resource "aws_lb_target_group_attachment" "tg-attach" {
  count            = length(local.ALL_INSTANCE_IDS)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = element(local.ALL_INSTANCE_IDS, count.index)
  port             = var.PORT
}

resource "aws_lb_listener" "frontend" {
  count             = var.ALB_ATTACH_TO == "frontend" ? 1 : 0
  load_balancer_arn = data.terraform_remote_state.alb.outputs.frontend-arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "frontend-https" {
  count             = var.ALB_ATTACH_TO == "frontend" ? 1 : 0
  load_balancer_arn = data.terraform_remote_state.alb.outputs.frontend-arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.terraform_remote_state.vpc.outputs.PUBLIC_ACM_ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}


resource "random_integer" "priority" {
  min = 100
  max = 500
  keepers = {
    tg_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener_rule" "static" {
  count        = var.ALB_ATTACH_TO == "backend" ? 1 : 0
  listener_arn = data.terraform_remote_state.alb.outputs.backend_listener_arn
  priority     = random_integer.priority.result

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = ["${var.COMPONENT}-${var.ENV}.roboshop.internal"]
    }
  }
}
