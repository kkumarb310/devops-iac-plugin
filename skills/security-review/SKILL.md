# Security review skill

## When to invoke
Auto-invoke when user asks to:
- Review security groups, IAM policies, S3 policies, RDS configs
- Check for security issues in any Terraform resource
- Audit existing infrastructure
- Before any terraform apply involving network or IAM changes

Also auto-invoke silently before generating any resource that touches:
- aws_security_group or aws_security_group_rule
- aws_iam_role, aws_iam_policy, aws_iam_role_policy
- aws_s3_bucket_policy
- aws_db_instance
- aws_lambda_function

## Review checklist

### Network security
- Flag any ingress rule with cidr_blocks = ["0.0.0.0/0"] — require justification
- Flag any ingress rule with port 22 (SSH) or 3389 (RDP) open to 0.0.0.0/0
- Flag any egress rule with port 0 and cidr 0.0.0.0/0 on production resources
- Verify security groups are referenced by ID not CIDR where possible
- Check that RDS, ElastiCache, and internal services are in private subnets only
- Verify NAT gateway is in public subnet, application servers in private

### IAM security
- Flag any policy with Action = "*" or Resource = "*"
- Flag any policy with Effect = Allow on iam:* actions
- Flag any EC2 instance profile with admin-level permissions
- Verify IAM roles use least-privilege — only actions the service actually needs
- Check that cross-account trust relationships are intentional
- Flag any inline policies — prefer managed policies for reusability

### S3 security
- Verify block_public_acls = true
- Verify block_public_policy = true
- Verify ignore_public_acls = true
- Verify restrict_public_buckets = true
- Verify server_side_encryption is configured
- Verify versioning is enabled on state and data buckets
- Flag any bucket policy that allows s3:GetObject to Principal = "*"

### RDS security
- Verify storage_encrypted = true
- Verify deletion_protection = true
- Verify skip_final_snapshot = false
- Verify RDS is in private subnet (no publicly_accessible = true)
- Verify backup_retention_period >= 7
- Flag any RDS with master_username = "admin" or "root" — require custom username

### Drift detection (when AWS MCP is available)
- Query live security group rules and compare with Terraform config
- Report any rules in AWS not present in Terraform (manual additions = drift)
- Report any rules in Terraform not in AWS (failed applies or partial state)
- Query live S3 bucket policies and compare with Terraform
- Check if any S3 buckets have public access enabled that Terraform declares private

## Output format
Always present findings in this structure:

CRITICAL — must fix before apply:
- [resource name]: [issue] → [recommended fix]

WARNING — should fix soon:
- [resource name]: [issue] → [recommended fix]

INFO — best practice improvement:
- [resource name]: [issue] → [recommended fix]

PASSED — no issues found:
- [resource name]: [check that passed]

## After review always:
1. Block apply recommendation if any CRITICAL findings exist
2. Suggest the exact HCL fix for each finding
3. If drift detected via MCP, recommend terraform plan to reconcile
4. Update CLAUDE.md if a new security pattern is established
