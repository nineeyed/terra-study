provider "aws" {
    region = "eu-west-1"
}

resource "aws_instance" "example" {
    ami = "ami-0fd1481c9925c13d3"
    instance_type = "t2.micro"
    tags = {
        Name = "terraform-example"
    }
}

