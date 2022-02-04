# Номер порта WEB-сервера 
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

provider "aws" {
  region = "eu-west-1"
}

# Выясняем какой VPC у нас используется по умолчанию
data "aws_vpc" "default" {
  default = true
}

# Получаем подсети из VPC используемого по умолчанию
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Что мы хотим запускать
# Ubuntu и WEB-сервер
resource "aws_launch_configuration" "example" {
  image_id = "ami-0fd1481c9925c13d3"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

# Требуется при использовании группы автомасштабирования
# в конфигурации запуска.
# https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}
# Как мы хотим запускать
resource "aws_autoscaling_group" "example" {
  # Что запускаем
  launch_configuration = aws_launch_configuration.example.name

  # Указываем, что нужно использовать дефолтные подсети в нашем дефолтном VPC для подключения серверов
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  # Два сервера с масштабированием до 10
  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# Security Group для открытия порта 8080
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
