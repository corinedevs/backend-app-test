resource "aws_security_group" "sg" {
  name        = var.name
  vpc_id      = var.vpc_id

  # dynamic "ingress" {
  #   for_each = var.ingress_rules

  #   content {
  #     from_port        = ingress.value.port
  #     to_port          = ingress.value.port
  #     protocol         = "tcp"
  #     cidr_blocks      = ingress.value.cidr_blocks
  #   }
  # }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = {
    for idx, rule in var.ingress_rules : idx => rule
  }

  security_group_id = aws_security_group.sg.id
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"


  # One of these two will be used
  cidr_ipv4                = try(each.value.cidr_blocks, null)
  referenced_security_group_id = try(each.value.source_security_group_id, null)
}