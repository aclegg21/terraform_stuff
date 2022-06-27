resource "aws_ecs_cluster" "ecs_cluster" {
  name = "project_ecs_cluster"
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_providers" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_ecr_repository_policy" "foopolicy" {
  repository = aws_ecr_repository.foo.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

module "ecs-fargate" {
  source  = "umotif-public/ecs-fargate/aws"
  version = "~> 6.1.0"

  name_prefix        = "ecs-fargate-week20"
  vpc_id             = aws_vpc.ecs_vpc.id
  private_subnet_ids = [aws_subnet.priv_subnet1.id, aws_subnet.priv_subnet2.id]

  cluster_id = aws_ecs_cluster.ecs_cluster.id

  task_container_image   = var.app_image
  task_definition_cpu    = 256
  task_definition_memory = 512
  
  load_balanced = false

  task_container_port             = 80
  task_container_assign_public_ip = true

  target_groups = [
    {
      target_group_name = "tg-fargate-project"
      container_port    = 80
    }
  ]

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  tags = {
    Environment = "Dev"
    Project     = "Week20"
  }
}
