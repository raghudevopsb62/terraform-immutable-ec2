//resource "aws_instance" "od-instance" {
//  count                  = var.OD_INSTANCE_COUNT
//  instance_type          = var.OD_INSTANCE_TYPE
//  ami                    = data.aws_ami.ami.id
//  subnet_id              = element(data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS_IDS, count.index)
//  vpc_security_group_ids = [aws_security_group.allow.id]
//  user_data              = file("${path.module}/${var.ENV}-userdata.sh")
//}
//
//resource "aws_spot_instance_request" "spot-instance" {
//  count                  = var.SPOT_INSTANCE_COUNT
//  ami                    = data.aws_ami.ami.id
//  instance_type          = var.SPOT_INSTANCE_TYPE
//  wait_for_fulfillment   = true
//  subnet_id              = element(data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS_IDS, count.index + 1)
//  vpc_security_group_ids = [aws_security_group.allow.id]
//  user_data              = file("${path.module}/${var.ENV}-userdata.sh")
//}

resource "aws_launch_template" "template" {
  name                   = "${var.COMPONENT}-${var.ENV}"
  image_id               = data.aws_ami.ami.id
  instance_type          = var.SPOT_INSTANCE_TYPE
  vpc_security_group_ids = [aws_security_group.allow.id]
  user_data              = filebase64("${path.module}/${var.ENV}-userdata.sh")

  instance_market_options {
    market_type = "spot"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.COMPONENT}-${var.ENV}"
      APP_VERSION = var.APP_VERSION
    }
  }
  tags = {
    Name        = "${var.COMPONENT}-${var.ENV}"
    APP_VERSION = var.APP_VERSION
  }
}


resource "aws_autoscaling_group" "asg" {
  name                = "${var.COMPONENT}-${var.ENV}"
  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS_IDS
  desired_capacity    = var.ASG_DESIRED
  max_size            = var.ASG_MAX
  min_size            = var.ASG_MIN

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }
}

