# [PROJECT NAME] — Claude Code project context

## Project overview
Terraform IaC project deploying AWS infrastructure.
AWS account: [YOUR_ACCOUNT_ID]
Region: [YOUR_REGION]
GitHub: [YOUR_REPO_URL]

## Terraform standards

### Version requirements
- Terraform >= 1.7.0
- AWS provider ~> 5.0

### File structure — always use this layout
Every module must have exactly three files:
- main.tf — resources only
- variables.tf — input variables with description and type
- outputs.tf — output values with description

### Naming conventions
- Resource prefix: [PROJECT]-
- Local name for single-instance resources: "this"
- Module names: descriptive snake_case

### Tagging — every resource must have these tags
- project = "[PROJECT]"
- env     = terraform.workspace
- owner   = "[YOUR_NAME]"

Never use var.common_tags directly — always use local.workspace_tags.
Always use merge(var.tags, { Name = "${var.project}-descriptive-name" }).
Never use tags = var.tags alone — always add a Name tag via merge.

### Module standards
- Input variables must have description and type
- Output values must have description
- Always add prevent_destroy to stateful resources (S3, DynamoDB, RDS, VPC)
- Always add ignore_changes = [tags] to externally managed resources
- S3 lifecycle: always add ignore_changes = [rule] to prevent AWS API ordering drift
- Use for_each over count with stable string keys
- Never put provider or terraform blocks inside modules
- Add depends_on explicitly when AWS cannot infer the dependency
- Add timeouts block on slow AWS APIs (S3 lifecycle, NAT gateway, RDS)
- sensitive = true on passwords, keys, and connection strings

### Security standards
- Never use 0.0.0.0/0 on ingress without explicit justification comment
- Security group rules must use separate aws_security_group_rule resources
- IAM policies must follow least privilege
- RDS: always enable storage_encrypted = true and deletion_protection = true
- S3: always enable server_side_encryption and block_public_access
- Globally unique resources (S3): append random_id suffix

### State management
- Remote state: S3 bucket (update with your bucket name)
- Lock table: DynamoDB (update with your table name)
- Never commit terraform.tfstate or sensitive .tfvars files

### CI/CD pipeline
- PR pipeline: fmt + TFLint + tfsec + terraform plan + Claude AI summary + Infracost
- Deploy pipeline: terraform apply via OIDC on merge to main
- Drift detection: weekly cron every Monday 1am UTC
- GitHub secrets needed: ANTHROPIC_API_KEY, INFRACOST_API_KEY, TF_VAR_db_username, TF_VAR_db_password

## Existing modules
[Update this section as you add modules]

## Claude behaviour instructions
- Always run terraform validate mentally before suggesting any HCL
- Always include description on every variable and output
- Always use local.workspace_tags for tags, never hardcode env values
- When generating a new module, always create all three files
- When refactoring into modules, remind user to run terraform state mv
- Update this CLAUDE.md whenever a new pattern is established
- Before creating any AWS resource, check if it already exists
- After every apply check if new patterns were established and update this file
- Confirm prevent_destroy is present on every stateful resource
- Confirm Infracost will pick up new resources correctly
