# --- compute/main.tf ---

data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "random_id" "ac_node_id" {
  byte_length = 2
  count       = var.instance_count
  keepers = {
    key_name = var.key_name
  }
}

resource "aws_key_pair" "ac_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "ac_node" {
  count         = var.instance_count # 1
  instance_type = var.instance_type  # t3.micro
  ami           = data.aws_ami.server_ami.id
  tags = {
    Name = "ac_node-${random_id.ac_node_id[count.index].dec}"
  }

  key_name               = aws_key_pair.ac_auth.id
  vpc_security_group_ids = [var.public_sg]
  subnet_id              = var.public_subnets[count.index]
  user_data = templatefile(var.user_data_path,
    {
      nodename    = "ac-${random_id.ac_node_id[count.index].dec}"
      db_endpoint = var.db_endpoint
      dbuser      = var.dbuser
      dbpass      = var.dbpassword
      dbname      = var.dbname
    }
  )
  root_block_device {
    volume_size = var.vol_size #10
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = file(var.private_key_path)
    }
    script = "${path.cwd}/delay.sh"
  }
  provisioner "local-exec" {
    command = templatefile("${path.cwd}/scp_script.tpl",
      {
        nodeip           = self.public_ip
        k3s_path         = "${path.cwd}/../"
        nodename         = self.tags.Name
        private_key_path = var.private_key_path
      }
    )
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.cwd}/../k3s-${self.tags.Name}.yaml"
  }
}

resource "aws_lb_target_group_attachment" "ac_tg_attach" {
  count            = var.instance_count
  target_group_arn = var.lb_target_group_arn
  target_id        = aws_instance.ac_node[count.index].id
  port             = var.tg_port
}