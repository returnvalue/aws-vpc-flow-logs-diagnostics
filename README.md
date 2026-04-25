# AWS Network Diagnostics & Flow Logs Lab

This lab demonstrates a mission-critical network troubleshooting and security pattern for the **AWS SysOps Administrator Associate**: using VPC Flow Logs and CloudWatch to analyze and alert on network traffic patterns.

## Architecture Overview

The system implements a real-time network diagnostics pipeline:

1.  **Traffic Collection:** VPC Flow Logs capture IP traffic metadata for all interfaces within the target VPC.
2.  **Data Streaming:** Traffic metadata (both `ACCEPT` and `REJECT` actions) is automatically streamed to a designated CloudWatch Log Group.
3.  **Pattern Recognition:** A CloudWatch Logs Metric Filter scans the flow logs for specific patterns, identifying and counting packets that were rejected by Security Groups or NACLs.
4.  **Automated Alerting:** A CloudWatch Metric Alarm monitors the custom "RejectedPacketCount" metric and triggers if blocked traffic exceeds the defined threshold (5 packets in 1 minute).

## Key Components

-   **VPC Flow Logs:** The engine for capturing network traffic metadata.
-   **CloudWatch Log Group:** The persistent storage and analysis point for flow log data.
-   **IAM Role & Policy:** Grants the VPC service the necessary permissions to write to CloudWatch.
-   **Metric Filter:** The logic that transforms raw log entries into a measurable "Rejected Traffic" metric.
-   **CloudWatch Alarm:** The automated trigger for operational notification based on high rejection rates.

## Prerequisites

-   [Terraform](https://www.terraform.io/downloads.html)
-   [LocalStack Pro](https://localstack.cloud/)
-   [AWS CLI / awslocal](https://github.com/localstack/awscli-local)

## Deployment

1.  **Initialize and Apply:**
    ```bash
    terraform init
    terraform apply -auto-approve
    
```

## Verification & Testing

To test the network diagnostics pipeline:

1.  **Verify Flow Log Configuration:**
    ```bash
    awslocal ec2 describe-flow-logs
    aws ec2 describe-flow-logs
    
```

2.  **Inspect Flow Log Data (Conceptual):**
    After generating traffic within the VPC, you can query the logs using CloudWatch Logs Insights or the CLI:
    ```bash
    awslocal logs get-log-events --log-group-name /aws/vpc/diagnostics-flow-logs --log-stream-name <STREAM_NAME>
    aws logs get-log-events --log-group-name /aws/vpc/diagnostics-flow-logs --log-stream-name <STREAM_NAME>
    
```

3.  **Check Custom Metric:**
    Verify the custom metric has been created in CloudWatch:
    ```bash
    awslocal cloudwatch list-metrics --namespace VPC/Diagnostics
    aws cloudwatch list-metrics --namespace VPC/Diagnostics
    
```

4.  **Monitor Alarm Status:**
    ```bash
    awslocal cloudwatch describe-alarms --alarm-names HighRejectedTrafficAlarm
    aws cloudwatch describe-alarms --alarm-names HighRejectedTrafficAlarm
    
```

## Cleanup

To tear down the infrastructure:
```bash
terraform destroy -auto-approve
```

---

💡 **Pro Tip: Using `aws` instead of `awslocal`**

If you prefer using the standard `aws` CLI without the `awslocal` wrapper or repeating the `--endpoint-url` flag, you can configure a dedicated profile in your AWS config files.

### 1. Configure your Profile
Add the following to your `~/.aws/config` file:
```ini
[profile localstack]
region = us-east-1
output = json
# This line redirects all commands for this profile to LocalStack
endpoint_url = http://localhost:4566
```

Add matching dummy credentials to your `~/.aws/credentials` file:
```ini
[localstack]
aws_access_key_id = test
aws_secret_access_key = test
```

### 2. Use it in your Terminal
You can now run commands in two ways:

**Option A: Pass the profile flag**
```bash
aws iam create-user --user-name DevUser --profile localstack
```

**Option B: Set an environment variable (Recommended)**
Set your profile once in your session, and all subsequent `aws` commands will automatically target LocalStack:
```bash
export AWS_PROFILE=localstack
aws iam create-user --user-name DevUser
```

### Why this works
- **Precedence**: The AWS CLI (v2) supports a global `endpoint_url` setting within a profile. When this is set, the CLI automatically redirects all API calls for that profile to your local container instead of the real AWS cloud.
- **Convenience**: This allows you to use the standard documentation commands exactly as written, which is helpful if you are copy-pasting examples from AWS labs or tutorials.
