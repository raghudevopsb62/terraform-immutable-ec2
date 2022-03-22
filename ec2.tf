resource "aws_instance" "od-instance" {
  count                  = var.OD_INSTANCE_COUNT
  instance_type          = var.OD_INSTANCE_TYPE
  ami                    = "${var.COMPONENT}-${var.APP_VERSION}"
  subnet_id              = element(data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS_IDS, count.index)
  vpc_security_group_ids = [aws_security_group.allow.id]
}

resource "aws_spot_instance_request" "spot-instance" {
  count                  = var.SPOT_INSTANCE_COUNT
  ami                    = data.aws_ami.ami.id
  instance_type          = var.SPOT_INSTANCE_TYPE
  wait_for_fulfillment   = true
  subnet_id              = element(data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS_IDS, count.index + 1)
  vpc_security_group_ids = [aws_security_group.allow.id]
}

resource "null_resource" "ansible-apply" {

  triggers = {
    TRIGGER     = var.TRIGGER
    APP_VERSION = var.APP_VERSION
  }

  count = length(local.ALL_INSTANCE_IPS)
  provisioner "remote-exec" {
    connection {
      host     = element(local.ALL_INSTANCE_IPS, count.index)
      user     = jsondecode(data.aws_secretsmanager_secret_version.latest.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.latest.secret_string)["SSH_PASS"]
    }
    inline = [
      "ansible-pull -U https://github.com/raghudevopsb62/ansible roboshop-pull.yml -e COMPONENT=${var.COMPONENT} -e ENV=${var.ENV} -e APP_VERSION=${var.APP_VERSION}"
    ]
  }
}
