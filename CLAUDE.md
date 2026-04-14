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

Never use var.common_tags directly — always use local.workspace_tags

### Module standards
- Input variables must have description and type
- Output values must have description
- Always add prevent_destroy to stateful resources (S3, DynamoDB, RDS, VPC)
- Always add ignore_changes = [tags] to externally managed resources
- Use for_each over count with stable string keys

### State management
- Remote state: S3 bucket
- Lock table: DynamoDB
- Never commit terraform.tfstate or sensitive .tfvars files

## Existing modules
[Update this section as you add modules]

## Claude behaviour instructions
- Always run terraform validate mentally before suggesting HCL
- Always include description on every variable and output
- Always use local.workspace_tags for tags
- When generating a new module, always create all three files
- When refactoring into modules, remind user to run terraform state mv
- Before creating any AWS resource, check if it already exists
- Update this CLAUDE.md whenever a new pattern is established
