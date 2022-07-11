terraform {
  backend "s3" {
    profile = "prod"
    key = "stage/services/webserver-cluster/terraform.tfstate"
  }
}

// This is a Test instance
resource "aws_instance" "TEST" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.For_TEST_instance.id]
  user_data              = <<-EOF
             #!/bin/bash
             echo "Hello, World" > index.html
             nohup busybox httpd -f -p ${var.server_port} &
             EOF 
  tags = {
    Name = "Test_platform"
  }
}

resource "aws_launch_configuration" "TEST" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.For_TEST_instance.id]

  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "TEST" {
  launch_configuration = aws_launch_configuration.TEST.name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns    = [aws_alb_target_group.asg.arn]
  health_check_type    = "ELB"
  min_size             = 2
  max_size             = 4

  tag {
    key                 = "Name"
    value               = "terraform_asg_test"
    propagate_at_launch = true
  }

}

// This is a test instance SG
resource "aws_security_group" "For_TEST_instance" {
  name = "${var.cluster_name}-instance"

  ingress {
    from_port   = var.server_port
    protocol    = "tcp"
    to_port     = var.server_port
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
  ingress {
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
}

resource "aws_alb" "TEST" {
  name               = "terraform-asg-test"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.TEST.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.asg.arn
  }
}

resource "aws_alb_target_group" "asg" {
  name     = "terraform-asg-test"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.hive_test.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }


}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.hive_test.id]
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.db_remote_state_bucket
    profile = "prod" 
    key = var.db_remote_state_key
    region = "us-east-2"
   }
  
}

data "template_file" "user_data" {
  template = file("user-data.sh")

  vars = {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }
}