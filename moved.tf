moved {
  from = module.log-group-role.aws_iam_role.roles["ApiGatewayLogs"]
  to   = module.log-group-role.aws_iam_role.this[0]
}

moved {
  from = module.log-group-role.aws_iam_role_policy_attachment.policy_arn_attachments["ApiGatewayLogs:arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"]
  to   = module.log-group-role.aws_iam_role_policy_attachment.this["AmazonAPIGatewayPushToCloudWatchLogs"]
}
