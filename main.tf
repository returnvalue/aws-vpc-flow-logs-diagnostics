# AWS provider configuration for LocalStack
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    route53        = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    elb            = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    rds            = "http://localhost:4566"
    autoscaling    = "http://localhost:4566"
    events         = "http://localhost:4566"
    logs           = "http://localhost:4566"
  }
}

# VPC: The target network for flow log diagnostics
resource "aws_vpc" "diagnostics_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "diagnostics-lab-vpc"
    Environment = "SysOps-Lab"
  }
}

# CloudWatch Log Group: The destination for our network flow logs
resource "aws_cloudwatch_log_group" "flow_log_group" {
  name              = "/aws/vpc/diagnostics-flow-logs"
  retention_in_days = 7

  tags = {
    Name        = "vpc-flow-log-group"
    Environment = "SysOps-Lab"
  }
}

# IAM Role: Identity allowing VPC Flow Logs to write to CloudWatch
resource "aws_iam_role" "flow_log_role" {
  name = "vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "flow-log-identity"
    Environment = "SysOps-Lab"
  }
}

# IAM Policy: Grants permission to write flow log data into the CloudWatch Log Group
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "vpc-flow-log-delivery-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.flow_log_group.arn}:*"
      }
    ]
  })
}

# VPC Flow Log: Activates traffic capturing for our diagnostics VPC
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.diagnostics_vpc.id

  tags = {
    Name        = "diagnostics-vpc-flow-logs"
    Environment = "SysOps-Lab"
  }
}

# CloudWatch Metric Filter: Detects and counts 'REJECT' events in network traffic
resource "aws_cloudwatch_log_metric_filter" "reject_filter" {
  name           = "RejectedTrafficFilter"
  pattern        = "[version, account_id, interface_id, srcaddr, dstaddr, srcport, dstport, protocol, packets, bytes, start, end, action=\"REJECT\", log_status]"
  log_group_name = aws_cloudwatch_log_group.flow_log_group.name

  metric_transformation {
    name      = "RejectedPacketCount"
    namespace = "VPC/Diagnostics"
    value     = "1"
  }
}

# CloudWatch Alarm: Alerts when blocked traffic exceeds the threshold
resource "aws_cloudwatch_metric_alarm" "rejected_traffic_alarm" {
  alarm_name          = "HighRejectedTrafficAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.reject_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.reject_filter.metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This alarm triggers when blocked VPC traffic exceeds 5 packets in 1 minute"

  tags = {
    Name        = "vpc-reject-alarm"
    Environment = "SysOps-Lab"
  }
}

# Outputs: Key identifiers for verifying the network diagnostics pipeline
output "vpc_id" {
  value = aws_vpc.diagnostics_vpc.id
}

output "flow_log_group_name" {
  value = aws_cloudwatch_log_group.flow_log_group.name
}

output "reject_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.rejected_traffic_alarm.arn
}
