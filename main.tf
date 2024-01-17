locals {
  enabled                = var.enabled
  create_rest_api_policy = local.enabled && var.rest_api_policy != null
  create_log_group       = local.enabled && var.logging_level != "OFF"
  vpc_endpoint_enabled   = length(var.vpc_endpoint_ids) > 0
  log_group_arn          = local.create_log_group ? module.log-group.cloudwatch_log_group_arn : null
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
# if logging is enabled we create a log group for the access logs and also make sure that the api gateway is able to log to the group
module "log-group" {
  source = "github.com/terraform-aws-modules/terraform-aws-cloudwatch//modules/log-group?ref=v5.1.0"

  create = local.create_log_group

  name_prefix       = "/aws/apigateway/${var.name}-"
  retention_in_days = 7
}

resource "aws_api_gateway_account" "settings" {
  cloudwatch_role_arn = local.create_log_group ? module.log-group-role.roles["ApiGatewayLogs"].arn : null
}

module "log-group-role" {
  source = "github.com/Flaconi/terraform-aws-iam-roles?ref=v7.3.0"

  roles = local.create_log_group ? [
    {
      name                 = "ApiGatewayLogs"
      instance_profile     = null
      path                 = null
      desc                 = null
      trust_policy_file    = "data/api-gateway.json"
      permissions_boundary = null
      policies             = []
      policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs",
      ]
      inline_policies = []
    },
  ] : []

  tags = var.tags
}
