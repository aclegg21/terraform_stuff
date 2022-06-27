resource "aws_vpc" "ecs_vpc" {
    cidr_block = var.vpc_cidr_block
    
    tags = {
        Name = "VPC for week 20 cluster project"
    }
}