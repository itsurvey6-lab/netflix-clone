# Securirty Group

module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "netflix-sg"
  description = "Security group for netflix clone server"
  vpc_id      = var.vpc_id

  ingress_rules = {
    jenkins = {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "jenkins"
      cidr_ipv4   = "0.0.0.0/0"
    }

    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https"
      cidr_ipv4   = "0.0.0.0/0"
    }

    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh"
      cidr_ipv4   = "0.0.0.0/0"
    }

    sonar = {
      from_port   = 9000
      to_port     = 9000
      protocol    = "tcp"
      description = "sonar"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  egress_rules = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "all outbound traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}


# EC2 instance for server
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "netflix-server"

  instance_type          = var.instance_type
  key_name               = var.key_pair
  ami                    = var.ami
  monitoring             = true
  vpc_security_group_ids = [module.sg.id]
  subnet_id              = var.subnet_id
  user_data              = file("userdata.sh")

  root_block_device = {
    volume_size = 25
    volume_type = "gp3"
  }

  tags = {
    Terraform   = "true"
    name        = "netflix-server"
    Environment = "dev"
  }
}

resource "aws_eip" "eip" {
  instance = module.ec2_instance.id
  domain   = "vpc"
}
