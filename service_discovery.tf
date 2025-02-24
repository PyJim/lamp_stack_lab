resource "aws_service_discovery_private_dns_namespace" "service_discovery" {
  name = "todo.local"
  vpc  = aws_vpc.main.id
}



resource "aws_service_discovery_service" "apache" {
  name = "apache"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.service_discovery.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

