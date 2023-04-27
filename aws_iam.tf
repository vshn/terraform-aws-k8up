locals {
  name          = "${var.cluster_name}-${var.name}"
  bucket_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:CreateBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::k8up-c-${var.cluster_name}-cluster-backup"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
              "arn:aws:s3:::k8up-c-${var.cluster_name}-cluster-backup",
              "arn:aws:s3:::k8up-c-${var.cluster_name}-cluster-backup/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_user" "k8up" {
  name = local.name
  path = "/"

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_iam_access_key" "k8up" {
  user = aws_iam_user.k8up.name
}

resource "aws_iam_user_group_membership" "k8up" {
  user = aws_iam_user.k8up.name

  groups = [
    aws_iam_group.k8up_bucket_access.name,
  ]
}

resource "aws_iam_group_policy_attachment" "k8up_bucket_access" {
  group      = aws_iam_group.k8up_bucket_access.name
  policy_arn = aws_iam_policy.k8up_bucket_access.arn
}

resource "aws_iam_group" "k8up_bucket_access" {
  name = "${var.cluster_name}-k8up-bucket-access"
}

resource "aws_iam_policy" "k8up_bucket_access" {
  name        = "${var.cluster_name}-k8up-bucket-access"
  description = "Allows access to k8up S3 buckets"

  policy = var.bucket_policy != null ? var.bucket_policy : local.bucket_policy
}
