resource "aws_security_group" "checkmk-sg" {
  name        = "checkmk-sg"
  description = "Security group for checkmk"
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self             = true
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }
}
resource "aws_key_pair" "terraform-key" {
  key_name   = "terraform-key"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}
resource "aws_instance" "checkmk-server" {
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "c5.xlarge"
  key_name      = aws_key_pair.terraform-key.key_name
  availability_zone = var.availability_zone
  vpc_security_group_ids = [aws_security_group.checkmk-sg.id]

  tags = {
    Name = "checkmk-server"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
    delete_on_termination = true
  }
}

resource "aws_ebs_volume" "checkmk-volume-1" {
  availability_zone = var.availability_zone
  size = 100
  type = "gp2"
}

resource "aws_volume_attachment" "checkmk-volume-1-attachment" {
  device_name = "/dev/xvdh"
  volume_id = aws_ebs_volume.checkmk-volume-1.id
  instance_id = aws_instance.checkmk-server.id
}

resource "null_resource" "checkmk-server-exec" {
  provisioner "file" {
    source      = "cert/monitoring1.vibicloud.id.crt"
    destination = "/tmp/monitoring1.vibicloud.id.crt"
  }

  provisioner "file" {
    source      = "cert/monitoring1.vibicloud.id.key"
    destination = "/tmp/monitoring1.vibicloud.id.key"
  }

  provisioner "file" {
    source      = "cert/CACert.crt"
    destination = "/tmp/CACert.crt"
  }

  provisioner "file" {
    source      = "default-ssl.conf"
    destination = "/tmp/default-ssl.conf"
  }

  provisioner "file" {
    source      = "000-default.conf"
    destination = "/tmp/000-default.conf"
  }

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo sed -i -e 's/\r$//' /tmp/script.sh",  # Remove the spurious CR characters.
      "sudo /tmp/script.sh",
    ]
  }
  connection {
    host        = coalesce(aws_instance.checkmk-server.public_ip, aws_instance.checkmk-server.private_ip)
    type        = "ssh"
    user        = var.INSTANCE_USERNAME
    private_key = file(var.PATH_TO_PRIVATE_KEY)
  }
}

output "ip" {
  value = aws_instance.checkmk-server.public_ip
}

