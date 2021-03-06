# Terraform module which creates CloudTrail resources on AWS.
#
# https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html

# https://www.terraform.io/docs/providers/aws/r/cloudtrail.html
resource "aws_cloudtrail" "default" {
  name           =  "${var.name}"
  s3_bucket_name =  aws_s3_bucket.onebucket.id
  s3_key_prefix  =  "prefix"

  # When you create a trail, logging is turned on automatically. You can turn off logging for a trail.
  # https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-turning-off-logging.html
  enable_logging = "${var.enable_logging}"

  # When you create a trail that applies to all regions,
  # CloudTrail records events in each region and delivers the CloudTrail event log files to an S3 bucket that you specify.
  # https://docs.aws.amazon.com/awscloudtrail/latest/userguide/how-cloudtrail-works.html
  is_multi_region_trail = "${var.is_multi_region_trail}"

  # For global services such as IAM, STS, CloudFront, and Route 53,
  # events are delivered to any trail that includes global services,
  # and are logged as occurring in US East (N. Virginia) Region.
  # https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-global-service-events
  include_global_service_events = "${var.include_global_service_events}"

  # To determine whether a log file was modified, deleted, or unchanged after CloudTrail delivered it,
  # you can use CloudTrail log file integrity validation.
  # https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-log-file-validation-intro.html
  enable_log_file_validation = "${var.enable_log_file_validation}"

  # Role for CloudTrail that enables it to send events to the CloudWatch Logs log group.
  # https://docs.aws.amazon.com/awscloudtrail/latest/userguide/send-cloudtrail-events-to-cloudwatch-logs.html#send-cloudtrail-events-to-cloudwatch-logs-cli-create-role
  cloud_watch_logs_role_arn = "${var.cloud_watch_logs_role_arn}"

  # You can configure CloudTrail with CloudWatch Logs to monitor your trail logs
  # and be notified when specific activity occurs.
  # https://docs.aws.amazon.com/awscloudtrail/latest/userguide/send-cloudtrail-events-to-cloudwatch-logs.html#send-cloudtrail-events-to-cloudwatch-logs-cli-create-log-group
  cloud_watch_logs_group_arn = "${var.cloud_watch_logs_group_arn}"

  # A mapping of tags to assign to the bucket.
  tags = "${var.tags}"
}

# Create a bucket
resource "aws_s3_bucket" "onebucket" {
   bucket = "testing-s3-with-terraform-ramesh2"
   acl    = "private"   # or can be "public-read"
  #  force_destroy ="true"

   versioning {
      enabled = true
   }

   tags = {
     Environment = "Test"
   }
}


data "aws_caller_identity" "current" {}


# Bucket Policy

resource "aws_s3_bucket_policy" "onebucket" {
  bucket = aws_s3_bucket.onebucket.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.onebucket.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.onebucket.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

