# devops-iac-plugin

A Claude Code plugin that gives any Terraform project instant AWS DevOps intelligence — enforced standards, security review, and AI-powered CI/CD out of the box.

## What it installs

| Component | What it does |
|---|---|
| Skill: terraform-generate | Claude follows your HCL standards automatically |
| Skill: security-review | Structured CRITICAL/WARNING/PASSED output before every apply |
| Hook: pre-write-fmt | terraform fmt runs on every .tf file Claude saves |
| Hook: pre-commit | Blocks .tfstate and .tfvars commits automatically |
| Hook: post-apply | Reminds Claude to update CLAUDE.md after every apply |
| Workflow: pr.yml | fmt + TFLint + tfsec + plan + Claude AI summary on every PR |
| Workflow: deploy.yml | terraform apply via OIDC on merge to main |
| Workflow: drift.yml | Weekly drift detection with Claude analysis as GitHub Issue |
| CLAUDE.md template | Project memory scaffold |

## Requirements

- Claude Code 2.1.0+
- Terraform 1.7.0+
- AWS CLI configured
- GitHub repository
- Anthropic API key

## Install on Windows

```powershell
git clone https://github.com/kkumarb310/devops-iac-plugin.git
cd your-terraform-project
powershell -ExecutionPolicy Bypass -File ..\devops-iac-plugin\install.ps1
```

## Install on Linux or Mac

```bash
git clone https://github.com/kkumarb310/devops-iac-plugin.git
cd your-terraform-project
bash ../devops-iac-plugin/install.sh
```

## After install

1. Update CLAUDE.md with your project name, AWS account ID and region
2. Update workflows with your IAM role ARN
3. Add GitHub secrets: ANTHROPIC_API_KEY, TF_VAR_db_username, TF_VAR_db_password
4. Set up OIDC IAM role in AWS
5. Run claude auth login then claude

## Standards enforced automatically

- prevent_destroy on all stateful resources (S3, DynamoDB, RDS, VPC)
- merge(var.tags, { Name = ... }) on every resource
- for_each with stable string keys, never count
- sensitive = true on password and key variables
- Separate aws_security_group_rule resources, no inline rules
- No provider or terraform blocks inside modules
- timeouts blocks on slow AWS APIs
- depends_on for implicit dependencies

## Built from

Extracted from iac-lab — a production-pattern 3-tier AWS infrastructure project built with Claude Code.
github.com/kkumarb310/iac-lab

## Author

Kiran Kumar — Technical Architect, Cloud, DevOps, Agentic AI
