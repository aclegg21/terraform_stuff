# --- asg/main.tf ---

##WEB TIER##

#Create Web Security Group
resource "aws_security_group" "web_sg" {
  name        = "Web_SG"
  description = "Allow HTTP inbound traffic"
  vpc_id      =  var.vpc_id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-SG"
  }
}

#create web launch template
resource "aws_launch_template" "web_launch_template" {
  name_prefix   = "web-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
}  

#create web auto scaling group#
resource "aws_autoscaling_group" "web_asg" {
  max_size           = 3
  min_size           = 1
  vpc_zone_identifier = var.public_subnet
  
  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }
}

#######################################################################

##APP TIER##

# Create Application Security Group

resource "aws_security_group" "app_sg" {
  name        = "APP_SG"
  description = "Allow inbound traffic from web layer"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = "app-SG"
  }
}

# App - Application Load Balancer
resource "aws_lb" "app_app_lb" {
  name = "app-app-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.app_sg.id]
  subnets = var.app_subnet
}

# App - Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# App - Target Group
resource "aws_lb_target_group" "app_target_group" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    port     = 80
    protocol = "HTTP"
  }
}

# App - Launch Template
resource "aws_launch_template" "app_launch_template" {
  name_prefix   = "app-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_sg.id]
}

# App - Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  max_size           = 3
  min_size           = 1
  target_group_arns = [aws_lb_target_group.app_target_group.arn]
  vpc_zone_identifier = var.public_subnet

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }
}