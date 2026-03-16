locals {
  enabled                     = var.enabled
  default_integration_enabled = var.enabled && var.default_integration_enabled
  create_rest_api_policy      = local.enabled && var.rest_api_policy != null
  create_log_group            = local.enabled && var.logging_level != "OFF"
  vpc_endpoint_enabled        = length(var.vpc_endpoint_ids) > 0
  log_group_arn               = local.create_log_group ? module.log-group.cloudwatch_log_group_arn : null
  create_cognito_authorizer   = local.enabled && length(var.cognito_provider_arns) > 0
  create_custom_domain        = local.enabled && var.domain_name != null && var.certificate_arn != null
}

resource "aws_api_gateway_rest_api" "this" {
  count = local.enabled ? 1 : 0

  name = var.name
  tags = var.tags

  dynamic "endpoint_configuration" {
    for_each = local.vpc_endpoint_enabled && var.endpoint_type == "PRIVATE" ? [1] : []
    content {
      types            = [var.endpoint_type]
      vpc_endpoint_ids = var.vpc_endpoint_ids
    }
  }

  dynamic "endpoint_configuration" {
    for_each = !local.vpc_endpoint_enabled ? [1] : []
    content {
      types = [var.endpoint_type]
    }
  }

  lifecycle {
    precondition {
      condition     = (var.domain_name == null) == (var.certificate_arn == null)
      error_message = "Both domain_name and certificate_arn must be set together. You cannot set one without the other."
    }
  }
}

resource "aws_api_gateway_domain_name" "this" {
  count = local.create_custom_domain ? 1 : 0

  domain_name = var.domain_name
  endpoint_configuration {
    types = ["PRIVATE"]
  }
  certificate_arn = var.certificate_arn
  tags            = var.tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_api_gateway_domain_name_access_association" "this" {
  count = local.create_custom_domain ? 1 : 0

  domain_name_arn                = aws_api_gateway_domain_name.this[0].arn
  access_association_source      = one(var.vpc_endpoint_ids)
  access_association_source_type = "VPCE"
  tags                           = var.tags
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count = local.create_custom_domain ? 1 : 0

  api_id         = aws_api_gateway_rest_api.this[0].id
  stage_name     = var.stage_name
  domain_name    = aws_api_gateway_domain_name.this[0].domain_name
  domain_name_id = aws_api_gateway_domain_name.this[0].domain_name_id
}

data "aws_iam_policy_document" "vpc_endpoint_allow" {
  count = local.vpc_endpoint_enabled ? 1 : 0
  statement {
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"
      values   = var.vpc_endpoint_ids
    }

    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.this[0].execution_arn}/*"]
  }

  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.this[0].execution_arn}/*"]
  }
}
resource "aws_api_gateway_rest_api_policy" "private_vpc_endpoint" {
  count       = local.vpc_endpoint_enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  policy      = data.aws_iam_policy_document.vpc_endpoint_allow[0].json
}

resource "aws_api_gateway_deployment" "this" {
  count       = local.enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id

  triggers = {
    redeployment = sha1(data.aws_iam_policy_document.vpc_endpoint_allow[0].json)
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_api_gateway_rest_api_policy.private_vpc_endpoint]
}

resource "aws_api_gateway_stage" "this" {
  count                = local.enabled ? 1 : 0
  deployment_id        = aws_api_gateway_deployment.this[0].id
  rest_api_id          = aws_api_gateway_rest_api.this[0].id
  stage_name           = var.stage_name
  xray_tracing_enabled = var.xray_tracing_enabled
  tags                 = var.tags

  dynamic "access_log_settings" {
    for_each = local.create_log_group ? [1] : []

    content {
      destination_arn = local.log_group_arn
      format          = replace(var.access_log_format, "\n", "")
    }
  }

  lifecycle {
    # as deployments are happening through other places for the shared gateway we ignore changes for the deployment_id
    ignore_changes = [
      deployment_id,
    ]
  }

  depends_on = [aws_api_gateway_account.settings]
}

# Set the logging, metrics and tracing levels for all methods
resource "aws_api_gateway_method_settings" "all" {
  count       = local.enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  stage_name  = aws_api_gateway_stage.this[0].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = var.metrics_enabled
    logging_level   = var.logging_level
  }
}

resource "aws_api_gateway_resource" "resource_paths" {
  for_each = { for k in var.resource_paths : k => k }

  rest_api_id = aws_api_gateway_rest_api.this[0].id
  parent_id   = aws_api_gateway_rest_api.this[0].root_resource_id
  path_part   = each.value
}

#create default integration

resource "random_id" "path_part" {
  count       = local.default_integration_enabled ? 1 : 0
  byte_length = 8
  prefix      = "default-path-"
}

resource "aws_api_gateway_resource" "default_resource" {
  count       = local.default_integration_enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  parent_id   = aws_api_gateway_rest_api.this[0].root_resource_id
  path_part   = random_id.path_part[0].b64_url
}

resource "aws_api_gateway_method" "default_method" {
  count         = local.default_integration_enabled ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  resource_id   = aws_api_gateway_resource.default_resource[0].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "default_integration" {
  count       = local.default_integration_enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  resource_id = aws_api_gateway_resource.default_resource[0].id
  http_method = aws_api_gateway_method.default_method[0].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  count       = local.default_integration_enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  resource_id = aws_api_gateway_resource.default_resource[0].id
  http_method = aws_api_gateway_method.default_method[0].http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "default_integration_response" {
  count       = local.default_integration_enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  resource_id = aws_api_gateway_resource.default_resource[0].id
  http_method = aws_api_gateway_method.default_method[0].http_method
  status_code = aws_api_gateway_method_response.response_200[0].status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

# gateway response

resource "aws_api_gateway_gateway_response" "gateway_response" {
  for_each      = var.gateway_response
  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  response_type = each.key
  status_code   = each.value.status_code
  response_templates = {
    "application/json" = each.value.response_templates.json
  }
}

# authorizer

resource "aws_api_gateway_authorizer" "cognito" {
  count         = local.create_cognito_authorizer ? 1 : 0
  name          = "cognito"
  rest_api_id   = aws_api_gateway_rest_api.this[0].id
  type          = "COGNITO_USER_POOLS"
  provider_arns = var.cognito_provider_arns
}

# if logging is enabled we create a log group for the access logs and also make sure that the api gateway is able to log to the group
module "log-group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  create = local.create_log_group

  name_prefix       = "/aws/apigateway/${var.name}-"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_api_gateway_account" "settings" {
  cloudwatch_role_arn = local.create_log_group ? module.log-group-role.arn : null
}

module "log-group-role" {
  source          = "terraform-aws-modules/iam/aws//modules/iam-role"
  version         = "6.4.0"
  create          = local.create_log_group
  name            = "ApiGatewayLogs"
  use_name_prefix = false
  description     = "Managed by Terraform"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = ["sts:AssumeRole"],
      principals = [{
        type        = "Service",
        identifiers = ["apigateway.amazonaws.com"]
      }]
    }
  }
  policies = {
    AmazonAPIGatewayPushToCloudWatchLogs = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  }
  tags = merge(var.tags, {
    Name = "ApiGatewayLogs"
  })
}
