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
    ```

2.  **Inspect Flow Log Data (Conceptual):**
    After generating traffic within the VPC, you can query the logs using CloudWatch Logs Insights or the CLI:
    ```bash
    awslocal logs get-log-events --log-group-name /aws/vpc/diagnostics-flow-logs --log-stream-name <STREAM_NAME>
    ```

3.  **Check Custom Metric:**
    Verify the custom metric has been created in CloudWatch:
    ```bash
    awslocal cloudwatch list-metrics --namespace VPC/Diagnostics
    ```

4.  **Monitor Alarm Status:**
    ```bash
    awslocal cloudwatch describe-alarms --alarm-names HighRejectedTrafficAlarm
    ```

## Cleanup

To tear down the infrastructure:
```bash
terraform destroy -auto-approve
```
