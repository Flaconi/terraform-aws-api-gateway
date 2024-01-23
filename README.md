# terraform-module-template
Template for Terraform modules

<!-- Uncomment and replace with your module name
[![lint](https://github.com/flaconi/<MODULENAME>/workflows/lint/badge.svg)](https://github.com/flaconi/<MODULENAME>/actions?query=workflow%3Alint)
[![test](https://github.com/flaconi/<MODULENAME>/workflows/test/badge.svg)](https://github.com/flaconi/<MODULENAME>/actions?query=workflow%3Atest)
[![Tag](https://img.shields.io/github/tag/flaconi/<MODULENAME>.svg)](https://github.com/flaconi/<MODULENAME>/releases)
-->
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

For requirements regarding module structure: [style-guide-terraform.md](https://github.com/Flaconi/devops-docs/blob/master/doc/conventions/style-guide-terraform.md)

<!-- TFDOCS_HEADER_START -->


<!-- TFDOCS_HEADER_END -->

<!-- TFDOCS_PROVIDER_START -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.6 |

<!-- TFDOCS_PROVIDER_END -->

<!-- TFDOCS_REQUIREMENTS_START -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6 |

<!-- TFDOCS_REQUIREMENTS_END -->

<!-- TFDOCS_INPUTS_START -->
## Required Inputs

The following input variables are required:

### <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name)

Description: The name of the stage

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the gateway

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_endpoint_type"></a> [endpoint\_type](#input\_endpoint\_type)

Description: The type of the endpoint. One of - PUBLIC, PRIVATE, REGIONAL

Type: `string`

Default: `"REGIONAL"`

### <a name="input_logging_level"></a> [logging\_level](#input\_logging\_level)

Description: The logging level of the API. One of - OFF, INFO, ERROR

Type: `string`

Default: `"INFO"`

### <a name="input_metrics_enabled"></a> [metrics\_enabled](#input\_metrics\_enabled)

Description: A flag to indicate whether to enable metrics collection.

Type: `bool`

Default: `false`

### <a name="input_xray_tracing_enabled"></a> [xray\_tracing\_enabled](#input\_xray\_tracing\_enabled)

Description: A flag to indicate whether to enable X-Ray tracing.

Type: `bool`

Default: `false`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Key-value mapping of tags

Type: `map(string)`

Default: `{}`

### <a name="input_access_log_format"></a> [access\_log\_format](#input\_access\_log\_format)

Description: The format of the access log file.

Type: `string`

Default: `"  {\n\t\"requestTime\": \"$context.requestTime\",\n\t\"requestId\": \"$context.requestId\",\n\t\"httpMethod\": \"$context.httpMethod\",\n\t\"path\": \"$context.path\",\n\t\"resourcePath\": \"$context.resourcePath\",\n\t\"status\": $context.status,\n\t\"responseLatency\": $context.responseLatency,\n  \"xrayTraceId\": \"$context.xrayTraceId\",\n  \"integrationRequestId\": \"$context.integration.requestId\",\n\t\"functionResponseStatus\": \"$context.integration.status\",\n  \"integrationLatency\": \"$context.integration.latency\",\n\t\"integrationServiceStatus\": \"$context.integration.integrationStatus\",\n  \"authorizeResultStatus\": \"$context.authorize.status\",\n\t\"authorizerServiceStatus\": \"$context.authorizer.status\",\n\t\"authorizerLatency\": \"$context.authorizer.latency\",\n\t\"authorizerRequestId\": \"$context.authorizer.requestId\",\n  \"ip\": \"$context.identity.sourceIp\",\n\t\"userAgent\": \"$context.identity.userAgent\",\n\t\"principalId\": \"$context.authorizer.principalId\",\n\t\"cognitoUser\": \"$context.identity.cognitoIdentityId\",\n  \"user\": \"$context.identity.user\"\n}\n"`

### <a name="input_rest_api_policy"></a> [rest\_api\_policy](#input\_rest\_api\_policy)

Description: The IAM policy document for the API.

Type: `string`

Default: `null`

### <a name="input_enabled"></a> [enabled](#input\_enabled)

Description: Set to false to prevent the module from creating any resources

Type: `bool`

Default: `true`

### <a name="input_vpc_endpoint_ids"></a> [vpc\_endpoint\_ids](#input\_vpc\_endpoint\_ids)

Description: list of vpc endpoint ids for a private api to be assigned

Type: `list(string)`

Default: `[]`

### <a name="input_cognito_provider_arns"></a> [cognito\_provider\_arns](#input\_cognito\_provider\_arns)

Description: List of Cognito user pool ARNS

Type: `set(string)`

Default: `[]`

### <a name="input_default_integration_enabled"></a> [default\_integration\_enabled](#input\_default\_integration\_enabled)

Description: Set to true to enable a initial default integration to allow policy deployments for a sharded gateway

Type: `bool`

Default: `false`

### <a name="input_resource_paths"></a> [resource\_paths](#input\_resource\_paths)

Description: a list of root resource paths to be used in sharded environment

Type: `list(string)`

Default: `[]`

### <a name="input_gateway_response"></a> [gateway\_response](#input\_gateway\_response)

Description: n/a

Type:

```hcl
map(object({
    status_code = number
    #https://docs.aws.amazon.com/apigateway/latest/developerguide/supported-gateway-response-types.html
    response_templates = object({
      json = string
    })
  }))
```

Default: `{}`

<!-- TFDOCS_INPUTS_END -->

<!-- TFDOCS_OUTPUTS_START -->
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_url"></a> [api\_url](#output\_api\_url) | The URL to invoke the API pointing to the stage |
| <a name="output_cognito_authorizer_id"></a> [cognito\_authorizer\_id](#output\_cognito\_authorizer\_id) | The authorizer ID of the REST API's cognito authorizer |
| <a name="output_id"></a> [id](#output\_id) | The ID of the REST API |
| <a name="output_resources_paths_map"></a> [resources\_paths\_map](#output\_resources\_paths\_map) | Map of resource paths to id in api gateway |
| <a name="output_root_resource_id"></a> [root\_resource\_id](#output\_root\_resource\_id) | The resource ID of the REST API's root |

<!-- TFDOCS_OUTPUTS_END -->

## License

**[MIT License](LICENSE)**

Copyright (c) 2023 **[Flaconi GmbH](https://github.com/flaconi)**
