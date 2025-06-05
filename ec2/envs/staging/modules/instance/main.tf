variable "key_name" {
  description = "The name of the SSH key pair to use"
  type        = string
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with your AMI ID
  instance_type = "t2.micro"
  key_name      = var.key_name

  tags = {
    Name = "example-instance"
  }
}