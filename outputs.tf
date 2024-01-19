output "id" {
  description = "The ID of the REST API"
  value       = try(aws_api_gateway_rest_api.this[0].id, null)
}

output "root_resource_id" {
  description = "The resource ID of the REST API's root"
  value       = try(aws_api_gateway_rest_api.this[0].root_resource_id, null)
}

output "cognito_authorizer_id" {
  description = "The authorizer ID of the REST API's cognito authorizer"
  value       = try(aws_api_gateway_authorizer.cognito[0].id, null)
}

output "api_url" {
  description = "The URL to invoke the API pointing to the stage"
  value       = try(aws_api_gateway_stage.this[0].invoke_url, null)
}

output "resources_paths_map" {
  description = "Map of resource paths to id in api gateway"
  value       = { for k, v in aws_api_gateway_resource.resource_paths : k => v.id }
}
