# Terraform generate skill

## When to invoke
Auto-invoke when user asks to:
- Generate, create, or add a Terraform resource or module
- Write HCL for any AWS service
- Scaffold a new module

## Behaviour

### Always follow CLAUDE.md conventions
Read CLAUDE.md before generating any HCL. Apply all conventions without being asked.
If AWS MCP server is available, query live AWS state before creating any resource
to avoid duplicates and check existing naming patterns.

### Module generation checklist
When generating a new module always produce all three files simultaneously:
1. modules/{name}/main.tf
2. modules/{name}/variables.tf
3. modules/{name}/outputs.tf

Never generate a partial module — all three files or none.
Never put provider or terraform blocks inside a module — root only.
Never commit .tfvars files — remind user to add them to .gitignore.

### Variable rules
Every variable must have:
- description (string)
- type (explicit — never omit)
- default only if truly optional
- sensitive = true for variables that accept passwords, keys, or tokens

### Output rules
Every output must have:
- description (string)
- value referencing the resource directly
- sensitive = true for any output containing passwords, keys, or connection strings
- Use for expressions to transform for_each resources:
  { for k, v in aws_subnet.public : k => v.id }
- Never expose internal implementation details — only expose what callers need

### Resource rules

#### Naming
- Local name inside modules: always "this"
- Resource names must be deterministic — never use timestamp() or uuid() in names
- Globally unique resources (S3 buckets, IAM roles): append random_id suffix
- Tags: always merge(var.tags, { Name = "${var.project}-descriptive-name" })
  Never use tags = var.tags alone — always add a Name tag via merge

#### Lifecycle guardrails
- Stateful resources (S3, DynamoDB, RDS, EBS, VPC): always add prevent_destroy = true
- VPC is always stateful — deleting cascades to all subnets, route tables, NAT gateways.
  Always add prevent_destroy = true to aws_vpc without exception.
- RDS instances: always add deletion_protection = true and skip_final_snapshot = false
- External-managed resources: always add ignore_changes = [tags]
- S3 lifecycle configuration: always add ignore_changes = [rule] to prevent
  AWS API ordering causing phantom drift on every plan
- Multiple similar resources: always use for_each with string keys
- Never use count when for_each with stable string keys is possible

#### Dependencies and timing
- Add depends_on explicitly when AWS cannot infer the dependency:
  NAT gateway depends on IGW
  S3 lifecycle config depends on versioning
  RDS depends on subnet group
- Add timeouts block on known slow AWS APIs:
  S3 lifecycle: create = "10m", update = "10m"
  NAT gateway: create = "10m"
  RDS instance: create = "40m", update = "40m", delete = "40m"
  EKS cluster: create = "30m", update = "60m", delete = "30m"

#### Security rules
- Never use 0.0.0.0/0 on security group ingress without an explicit comment
  explaining why broad access is required
- Security group rules must use separate aws_security_group_rule resources
  not inline ingress/egress blocks — enables independent management
- IAM policies must follow least privilege — never use * on actions or resources
  without explicit justification comment
- Never use admin-level IAM policies on compute resources (EC2, Lambda, ECS)
- RDS: always enable storage_encrypted = true
- S3: always enable server_side_encryption and block_public_access

#### Provider and state rules
- Never put provider or terraform blocks inside modules — root only
- Pin provider versions with upper bound in root: version = "~> 5.0"
- Avoid null_resource and local-exec provisioners — use proper AWS resources
- Avoid data sources that query mutable state on every plan (use outputs instead)

### State management reminders
- After every module refactor always remind user to run terraform state mv
  for each resource being moved to the new module address
- After every apply check if new patterns were established and update CLAUDE.md
- Workspace name flows from terraform.workspace via locals — never hardcode env values

### After generating HCL always:
1. Run terraform validate mentally — confirm no syntax errors before presenting
2. If refactoring existing resources into a module, list every terraform state mv
   command needed — one per resource being moved
3. Add the new module to the existing modules list in CLAUDE.md
4. Explicitly confirm prevent_destroy is present on every stateful resource
   in the generated code — list them by name
5. Confirm Name tag is present on every resource via merge pattern
6. Confirm no provider or terraform blocks exist inside the module
7. Confirm sensitive = true on any outputs or variables containing secrets
8. Confirm security groups use least-privilege — flag any 0.0.0.0/0 ingress

## Example output format
When generating a module, present files in this order:
1. variables.tf first — defines the contract
2. main.tf second — the implementation
3. outputs.tf third — what gets exposed

Always show the module call for root main.tf after the module files.
Show the complete terraform state mv commands if refactoring existing resources.
