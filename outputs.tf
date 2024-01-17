output "id" {
  description = "The ID of the REST API"
  value       = var.enabled ? aws_api_gateway_rest_api.this[0].id : null
}

output "root_resource_id" {
  description = "The resource ID of the REST API's root"
  value       = var.enabled ? aws_api_gateway_rest_api.this[0].root_resource_id : null
}
