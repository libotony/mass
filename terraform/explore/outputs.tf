output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = length(module.ecs-cluster) > 0 ? module.ecs-cluster.name : ""
}

output "mass_ecs_service_names" {
  description = "The names of the load balanced ECS services"
  value       = length(module.ecs-lb-service-mass) > 0 ? [for service in module.ecs-lb-service-mass : service.service_name] : []
}

output "chain-scanner_ecs_service_names" {
  description = "The names of the backend ECS services"
  value       = length(module.ecs-backend-service-chain-scanner) > 0 ? [for service in module.ecs-backend-service-chain-scanner : service.service_name] : []
}

output "explore_ecs_service_names" {
  description = "The names of the frontend ECS services"
  value       = length(module.ecs-lb-service-explore) > 0 ? [for service in module.ecs-lb-service-explore : service.service_name] : []
}

output "load_balancer_domain_mainnet" {
  description = "The domain name of the mainnet load balancer"
  value       = length(module.ecs-lb-service-explore) > 0 ? module.ecs-lb-service-explore["main"].alb_dns_name : ""
}

output "load_balancer_domain_testnet" {
  description = "The domain name of the testnet load balancer"
  value       = length(module.ecs-lb-service-explore) > 0 ? module.ecs-lb-service-explore["test"].alb_dns_name : ""
}
