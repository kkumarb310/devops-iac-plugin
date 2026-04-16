# devops-iac-plugin

![Terraform](https://img.shields.io/badge/Terraform-1.7%2B-7B42BC?logo=terraform)
![Claude Code](https://img.shields.io/badge/Claude_Code-2.1%2B-orange)
![AWS](https://img.shields.io/badge/AWS-Supported-FF9900?logo=amazonaws)
![Infracost](https://img.shields.io/badge/Infracost-Cost_Estimation-green)
![License](https://img.shields.io/badge/License-MIT-green)

> Drop this plugin into any Terraform project and Claude Code instantly knows your AWS standards — generates modules correctly, catches security issues before apply, blocks dangerous commits, and estimates infrastructure costs automatically.

## The Problem This Solves

Every infrastructure team faces the same invisible problem: standards exist in people heads, not in tools.

A new engineer joins. They write Terraform. It works — but it is missing prevent_destroy on the database, using count instead of for_each, hardcoding tags, and nobody reviewed the security groups properly. Six months later someone runs terraform destroy and the database is gone.

This plugin teaches Claude Code your standards once, permanently. After a one-minute install:
- Claude generates Terraform that already follows your conventions
- Claude catches security issues before every apply
- Dangerous commits (state files, credentials) are blocked automatically
- Every PR gets a Claude AI plain-English summary of infrastructure changes
- Every PR gets an Infracost monthly cost estimate per resource
- Non-technical managers can review infrastructure changes without reading HCL

Time saved per engineer per week: 3-5 hours.

## What It Installs

| Component | What it does |
|---|---|
| CLAUDE.md template | Project memory scaffold - Claude reads this every session |
| Skill: terraform-generate | Claude follows your HCL standards automatically |
| Skill: security-review | Structured CRITICAL/WARNING/PASSED output before every apply |
| Hook: pre-write-fmt | terraform fmt runs on every .tf file Claude saves |
| Hook: pre-commit | Blocks .tfstate and .tfvars commits automatically |
| Hook: post-apply | Reminds Claude to update CLAUDE.md after every apply |
| Workflow: pr.yml | fmt + TFLint + tfsec + plan + Claude AI summary + Infracost on every PR |
| Workflow: deploy.yml | terraform apply via OIDC on merge to main |
| Workflow: drift.yml | Weekly drift detection with Claude analysis as GitHub Issue |

## What Appears on Every PR

Three things are posted automatically on every infrastructure PR:

**1. Infracost report**
- Monthly cost estimate per resource (EC2, RDS, NAT gateway, EIP)
- Total monthly cost change introduced by the PR
- Free tier eligible resources identified
- FinOps policy alignment check

**2. Claude AI Plan Summary**
- What resources are changing in plain English
- Risk level: low / medium / high
- Cost impact assessment
- Full terraform plan in collapsible section

**3. Security scan results**
- tfsec findings with severity levels
- Actionable fix recommendations

## Requirements

| Requirement | Minimum version |
|---|---|
| Claude Code | 2.1.0+ |
| Terraform | 1.7.0+ |
| AWS CLI | Any recent |
| GitHub repository | Any |
| Anthropic API key | Any |
| Infracost API key | Free at infracost.io |
| Python 3 | 3.8+ |

## Install on Windows

```powershell
git clone https://github.com/kkumarb310/devops-iac-plugin.git
cd your-terraform-project
& ..\devops-iac-plugin\install.ps1
```

## Install on Linux or Mac

```bash
git clone https://github.com/kkumarb310/devops-iac-plugin.git
cd your-terraform-project
bash ../devops-iac-plugin/install.sh
```

## After Install - 6 Steps to Get Fully Operational

**Step 1 - Update CLAUDE.md**
Replace all placeholders: [PROJECT NAME], [YOUR_ACCOUNT_ID], [YOUR_REGION], [YOUR_NAME], [YOUR_REPO_URL]

**Step 2 - Set up OIDC IAM role in AWS**
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```
Then create an IAM role with a trust policy for your repository.

**Step 3 - Update workflow files**
In each .github/workflows/ file update: ROLE_ARN, AWS_REGION, TF_VERSION

**Step 4 - Get Infracost API key**
Sign up free at https://dashboard.infracost.io
Copy your API key from Org settings.

**Step 5 - Add GitHub secrets**
Go to: GitHub repo Settings → Secrets and variables → Actions

| Secret name | Purpose |
|---|---|
| ANTHROPIC_API_KEY | Claude AI plan summary |
| INFRACOST_API_KEY | Monthly cost estimation |
| TF_VAR_db_username | RDS username |
| TF_VAR_db_password | RDS password |

**Step 6 - Authenticate and start**
```bash
claude auth login
claude
```

## Verifying the Install Worked

Inside Claude Code, type:

  What Skills and Hooks are configured for this project?

You should see:
  Skills: terraform-generate, security-review
  Hooks: PreToolUse (fmt on file write), PostToolUse (docs after apply)

## Standards Enforced Automatically

| Standard | Why it matters |
|---|---|
| prevent_destroy on S3, DynamoDB, RDS, VPC | Prevents accidental destruction of critical resources |
| merge(var.tags, { Name = ... }) on every resource | Every AWS resource gets a Name tag for cost allocation |
| for_each with stable string keys, never count | count causes resource recreation when items are removed |
| sensitive = true on passwords and keys | Prevents credentials appearing in Terraform logs |
| Separate aws_security_group_rule resources | Independent management without replacing the security group |
| No provider or terraform blocks in modules | Modules with provider blocks cannot be reused |
| timeouts blocks on slow AWS APIs | RDS and NAT gateways take minutes without them |
| depends_on for implicit dependencies | Some AWS resources must be created in order Terraform cannot infer |
| deletion_protection = true on RDS | Prevents database deletion even when Terraform requests it |
| skip_final_snapshot = false on RDS | Ensures a backup exists before any database deletion |

## Troubleshooting

**Summary unavailable in PR comment**
Cause: ANTHROPIC_API_KEY secret not set or wrong name.
Fix: GitHub Settings → Secrets → confirm named exactly ANTHROPIC_API_KEY.

**Infracost shows no cost estimate**
Cause: INFRACOST_API_KEY secret not set.
Fix: GitHub Settings → Secrets → add INFRACOST_API_KEY from dashboard.infracost.io.

**TFLint failing with missing required version**
Cause: TFLint flagging missing terraform blocks in modules — this is a false positive.
Fix: Add .tflint.hcl to your project root:
  rule "terraform_required_version" { enabled = false }
  rule "terraform_required_providers" { enabled = false }

**OIDC authentication failing**
Cause: Trust policy condition does not match your repository path.
Fix: Check the sub condition matches repo:YOUR_ORG/YOUR_REPO:* exactly.

**Hooks not firing**
Cause: .claude/settings.json not created or malformed.
Fix: Re-run the installer — it will merge hooks into existing settings.json.

**S3 lifecycle configuration timeout**
Cause: AWS S3 lifecycle API is eventually consistent and slow.
Fix: Add timeouts block to your lifecycle configuration resource:
  timeouts { create = "10m"; update = "10m" }

**State lock stuck after interrupted apply**
Cause: Previous apply interrupted before releasing DynamoDB lock.
Fix: Run terraform force-unlock LOCK_ID shown in the error message.

**Credentials appearing as tags on resources**
Cause: Sensitive variables accidentally added inside common_tags map in tfvars.
Fix: Ensure db_username and db_password are at root level in tfvars, not inside any map.

## Built from Real Experience

Extracted from iac-lab — a production-pattern 3-tier AWS infrastructure project (VPC + EC2 + RDS) built over 5 days using Claude Code.

Every pattern came from real issues:
- ignore_changes = [rule] on S3 lifecycle — AWS API ordering drift hit repeatedly
- timeouts blocks — S3 and NAT gateway timeouts in ap-southeast-1
- credentials-as-tags bug — real mistake during development caught by security review
- TFLint --force flag — false positives on module files
- Python-based Claude API call in CI — curl failed on special characters in plan output
- Infracost — added after seeing cost surprise from NAT gateway charges

Source project: https://github.com/kkumarb310/iac-lab

## Author

Kiran Kumar
Technical Architect - Cloud, DevOps, Agentic AI
11+ years experience in AWS, Terraform, and infrastructure automation

GitHub: https://github.com/kkumarb310
IaC Portfolio: https://github.com/kkumarb310/iac-lab
Plugin: https://github.com/kkumarb310/devops-iac-plugin
