region = "us-east-1"

cluster_name = "containers-linuxtips"

service_name = "chip"

service_port = 8080

service_cpu = 256

service_memory = 512

service_healthcheck = {
  healthy_threshold   = 3
  unhealthy_threshold = 10
  timeout             = 10
  interval            = 60
  matcher             = "200-399"
  path                = "/healthcheck"
  port                = 8080
}

service_launch_type = "EC2"

service_task_count = 1

service_hosts = [
  "chip.linuxtips.demo"
]

ssm_vpc_id = "/containers-linuxtips/vpc/vpc_id"

ssm_listener = "/containers-linuxtips/ecs/listener/id"

ssm_private_subnet_1a = "/containers-linuxtips/vpc/subnet_private_1a"

ssm_private_subnet_1b = "/containers-linuxtips/vpc/subnet_private_1b"

ssm_private_subnet_1c = "/containers-linuxtips/vpc/subnet_private_1c"

environment_variables = [
  {
    name  = "FOO",
    value = "BAR"
  },
  {
    name  = "PING",
    value = "PONG"
  }
]

capabilities = ["EC2"]