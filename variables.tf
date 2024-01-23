variable "endpoint_type" {
  type        = string
  description = "The type of the endpoint. One of - PUBLIC, PRIVATE, REGIONAL"
  default     = "REGIONAL"

  validation {
    condition     = contains(["EDGE", "REGIONAL", "PRIVATE"], var.endpoint_type)
    error_message = "Valid values for var: endpoint_type are (EDGE, REGIONAL, PRIVATE)."
  }
}

variable "logging_level" {
  type        = string
  description = "The logging level of the API. One of - OFF, INFO, ERROR"
  default     = "INFO"

  validation {
    condition     = contains(["OFF", "INFO", "ERROR"], var.logging_level)
    error_message = "Valid values for var: logging_level are (OFF, INFO, ERROR)."
  }
}

variable "metrics_enabled" {
  description = "A flag to indicate whether to enable metrics collection."
  type        = bool
  default     = false
}

variable "xray_tracing_enabled" {
  description = "A flag to indicate whether to enable X-Ray tracing."
  type        = bool
  default     = false
}


variable "tags" {
  type        = map(string)
  default     = {}
  description = "Key-value mapping of tags"
}

# See https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html for additional information
# on how to configure logging.
variable "access_log_format" {
  description = "The format of the access log file."
  type        = string
  default     = <<EOF
  {
	"requestTime": "$context.requestTime",
	"requestId": "$context.requestId",
	"httpMethod": "$context.httpMethod",
	"path": "$context.path",
	"resourcePath": "$context.resourcePath",
	"status": $context.status,
	"responseLatency": $context.responseLatency,
  "xrayTraceId": "$context.xrayTraceId",
  "integrationRequestId": "$context.integration.requestId",
	"functionResponseStatus": "$context.integration.status",
  "integrationLatency": "$context.integration.latency",
	"integrationServiceStatus": "$context.integration.integrationStatus",
  "authorizeResultStatus": "$context.authorize.status",
	"authorizerServiceStatus": "$context.authorizer.status",
	"authorizerLatency": "$context.authorizer.latency",
	"authorizerRequestId": "$context.authorizer.requestId",
  "ip": "$context.identity.sourceIp",
	"userAgent": "$context.identity.userAgent",
	"principalId": "$context.authorizer.principalId",
	"cognitoUser": "$context.identity.cognitoIdentityId",
  "user": "$context.identity.user"
}
  EOF
}

# See https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-resource-policies.html for additional
# information on how to configure resource policies.
#
# Example:
# {
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Principal": "*",
#            "Action": "execute-api:Invoke",
#            "Resource": "arn:aws:execute-api:us-east-1:000000000000:*"
#        },
#        {
#            "Effect": "Deny",
#            "Principal": "*",
#            "Action": "execute-api:Invoke",
#            "Resource": "arn:aws:execute-api:region:account-id:*",
#            "Condition": {
#                "NotIpAddress": {
#                    "aws:SourceIp": "123.4.5.6/24"
#                }
#            }
#        }
#    ]
#}
variable "rest_api_policy" {
  description = "The IAM policy document for the API."
  type        = string
  default     = null
}

variable "stage_name" {
  type        = string
  description = "The name of the stage"
}
variable "name" {
  type        = string
  description = "The name of the gateway"
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

variable "vpc_endpoint_ids" {
  type        = list(string)
  default     = []
  description = "list of vpc endpoint ids for a private api to be assigned"
}

variable "cognito_provider_arns" {
  type        = set(string)
  default     = []
  description = "List of Cognito user pool ARNS"
}

variable "default_integration_enabled" {
  type        = bool
  default     = false
  description = "Set to true to enable a initial default integration to allow policy deployments for a sharded gateway"
}

variable "resource_paths" {
  type        = list(string)
  default     = []
  description = "a list of root resource paths to be used in sharded environment"
}

variable "gateway_response" {
  #response_type => {response_templates}
  type = map(object({
    status_code = number
    #https://docs.aws.amazon.com/apigateway/latest/developerguide/supported-gateway-response-types.html
    response_templates = object({
      json = string
    })
  }))
  default = {}
}
