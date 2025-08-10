# IAM Role for EC2 instance to use SSM
resource "aws_iam_role" "ec2_ssm_role" {
  name = "bongaquino-${local.env}-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach the AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom S3 policy for EC2 instance to access deployment artifacts
resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "bongaquino-${local.env}-ec2-s3-policy"
  description = "Allow EC2 instance to access S3 deployment artifacts"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ],
        Resource = [
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

# Custom SNS and CloudWatch policy for Discord monitoring
resource "aws_iam_policy" "ec2_monitoring_policy" {
  name        = "bongaquino-${local.env}-ec2-monitoring-policy"
  description = "Allow EC2 instance to send Discord notifications and CloudWatch metrics"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = [
          "arn:aws:sns:ap-southeast-1:985869370256:bongaquino-${local.env}-discord-notifications"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_monitoring_policy_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.ec2_monitoring_policy.arn
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "bongaquino-${local.env}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# Output the instance profile ARN
output "instance_profile_arn" {
  value = aws_iam_instance_profile.ec2_ssm_profile.arn
  description = "ARN of the instance profile to attach to the EC2 instance"
} 