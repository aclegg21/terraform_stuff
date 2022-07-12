# --- database/main.tf ---


resource "aws_security_group" "database_sg" {
  name        = "database_sg"
  description = "Allow inbound traffic from alb"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow traffic from app layer"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [var.app_sg]
  }

  egress {
    from_port        = 32768
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db_sg"
  }
  
  lifecycle {
    # Necessary if changing 'name' or 'name_prefix' properties.
    create_before_destroy = true
  }
}

resource "aws_db_instance" "week22db" {
  allocated_storage    = 10
  db_subnet_group_name = aws_db_subnet_group.week22db.id
  engine               = "mysql"
  engine_version       = "8.0.20"
  instance_class       = "db.t2.micro"
  name                 = "db_name"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.database_sg.id]
}

resource "aws_db_subnet_group" "week22db" {
  name       = "week22db"
  subnet_ids = var.database_subnet

  tags = {
    Name = "My DB subnet group"
  }
}