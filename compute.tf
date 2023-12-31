data "aws_ami" "server_ami" {

  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "random_id" "ans_node_id" {

  byte_length = 2
  count       = var.main_instance_count

}

resource "aws_key_pair" "ans_key" {

  key_name   = var.key_name
  public_key = file(var.public_key_path)

}

resource "aws_instance" "ans_main" {
  count                  = var.main_instance_count
  instance_type          = var.main_instance_type
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.ans_key.id
  vpc_security_group_ids = [aws_security_group.ans_sg.id]
  subnet_id              = aws_subnet.ans_public_subnet[count.index].id
  user_data              = templatefile("./main-userdata.tpl", { new_hostname = "ans-main-${random_id.ans_node_id[count.index].dec}" })
  root_block_device {
    volume_size = var.main_vol_size
  }
  tags = {
    Name = "ans-main-${random_id.ans_node_id[count.index].dec}"
  }

  provisioner "local-exec" {
    command = "printf '\n${self.public_ip}' >> aws_hosts"

  }
}

resource "null_resource" "grafana_update" {

  count = var.main_instance_count
  provisioner "remote-exec" {

    inline = ["sudo apt upgrade -y grafana && touch upgrade.log && echo 'I updated Grafana' >> upgrade.log"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("F:/Users/RAHUL/Desktop/Devops/Devops Projects/Project6-Terraform-ansible-grafana/ansterra")
      host        = aws_instance.ans_main[count.index].public_ip
    }   

  }

}
