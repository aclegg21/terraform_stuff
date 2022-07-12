# --- root/main.tf ---

module "asg" {
  source        = "./asg"
  vpc_id        = module.networking.vpc
  ami_id        = "ami-0cff7528ff583bf9a"
  instance_type = "t2.micro"
  public_subnet = module.networking.public_subnet_id
  app_subnet    = module.networking.private_subnet_id
}

module "database" {
  source          = "./database"
  vpc_id          = module.networking.vpc
  app_sg          = module.asg.app_sg
  database_subnet = module.networking.database_subnet_id
}

module "networking" {
  source = "./networking"
  vpc_cidr                = "10.0.0.0/16"
  item_count              = 2
  web_subnet_cidr         = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zone_names = ["us-east-1a", "us-east-1b"]
  application_subnet_cidr = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnet_cidr    = ["10.0.21.0/24", "10.0.22.0/24"]
  }