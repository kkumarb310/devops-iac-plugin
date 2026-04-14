# DevOps IaC Plugin for Claude Code

![Terraform](https://img.shields.io/badge/Terraform-1.7%2B-7B42BC?logo=terraform)
![Claude Code](https://img.shields.io/badge/Claude_Code-2.1%2B-orange)
![AWS](https://img.shields.io/badge/AWS-Supported-FF9900?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)

> Drop this plugin into any Terraform project and Claude Code instantly knows your AWS standards — generates modules correctly, catches security issues before apply, and blocks dangerous commits automatically.

## The Problem This Solves

Every infrastructure team faces the same invisible problem: standards exist in people heads, not in tools.

A new engineer joins. They write Terraform. It works — but it is missing prevent_destroy on the database, using count instead of for_each, and hardcoding tags instead of using workspace variables. The code gets reviewed, but the reviewer is busy. It goes to production. Six months later someone runs terraform destroy and the database is gone.

Or consider this: a senior engineer writes a security group. They forget to restrict ingress to a specific security group ID and use 0.0.0.0/0 instead. The code passes review because everyone assumes someone else checked it. The misconfiguration sits in production for months until a security audit finds it.

These are not hypothetical problems. They happen in every organisation that manages infrastructure manually.

The root cause is that infrastructure standards are documented in wikis nobody reads, enforced by reviewers who are under time pressure, and applied inconsistently across a team.

When someone uses an AI coding assistant like Claude Code, the problem gets worse — Claude generates code quickly but it does not know your team specific conventions, your naming patterns, your security requirements, or which resources need prevent_destroy.

This plugin teaches Claude Code your standards once, permanently.

Time saved per engineer per week: 3-5 hours of review, formatting, and debugging work that the plugin handles automatically.

Risk reduced: The most common infrastructure mistakes (missing lifecycle guardrails, open security groups, committed state files) are caught before they reach production.

## How It Works — The Full Flow

When an engineer uses this plugin, here is exactly what happens:

1. Engineer opens their Terraform project and runs claude
2. Claude reads CLAUDE.md and knows the project standards immediately
3. Engineer asks Claude to generate a module
4. Claude reads the terraform-generate Skill and applies all standards automatically
5. Claude generates all 3 files (main.tf, variables.tf, outputs.tf) simultaneously
6. Pre-write hook fires — terraform fmt runs automatically on every saved file
7. Engineer reviews the code and runs terraform plan locally
8. Engineer opens a Pull Request on GitHub
9. GitHub Actions pr.yml triggers automatically:
   - terraform fmt check
   - terraform validate
   - TFLint (lint rules)
   - tfsec (security scan)
   - terraform plan (shows what will change in AWS)
   - Claude API reads the plan and writes a plain-English summary
   - Summary posted as PR comment for team review
10. Team approves and merges the PR
11. GitHub Actions deploy.yml triggers automatically
12. terraform apply runs via OIDC — no AWS keys stored anywhere
13. Every Monday at 1am: drift detection runs automatically
14. If AWS state differs from Terraform code, Claude analyses the drift and creates a GitHub Issue

## What Gets Installed

### CLAUDE.md — Project Memory

Claude reads this file at the start of every session. It tells Claude everything about your project — naming conventions, tagging standards, module patterns, security requirements.

Without CLAUDE.md, Claude starts every session knowing nothing about your project. With it, Claude starts knowing your account ID, your module structure, your tag requirements, and your security standards. It is the difference between a new contractor who has never seen your codebase and a senior engineer who has worked on it for a year.

Time saved: 15-20 minutes per session that would otherwise be spent explaining context to Claude.

### Skill: terraform-generate

A detailed instruction set that Claude auto-reads whenever you ask it to generate Terraform code. It enforces every HCL standard your team has agreed on.

Without this Skill, Claude generates technically correct Terraform that violates your conventions — wrong naming, missing lifecycle guards, inline security group rules, count instead of for_each. With this Skill, Claude generates production-ready code that passes review on the first try.

Standards enforced automatically:

| Standard | Why it matters |
|---|---|
| prevent_destroy on S3, DynamoDB, RDS, VPC | Prevents accidental destruction of critical resources |
| merge(var.tags, { Name = ... }) on every resource | Ensures every AWS resource has a Name tag for cost allocation |
| for_each with stable string keys, never count | count causes resource recreation when items are removed from lists |
| sensitive = true on passwords and keys | Prevents credentials appearing in Terraform logs |
| Separate aws_security_group_rule resources | Allows independent management of each rule |
| No provider or terraform blocks in modules | Modules with provider blocks cannot be reused across configurations |
| timeouts blocks on slow AWS APIs | RDS and NAT gateways can take minutes — without timeouts Terraform fails |
| depends_on for implicit dependencies | Some AWS resources must be created in order Terraform cannot infer |
| deletion_protection = true on RDS | Prevents database deletion even when Terraform requests it |
| skip_final_snapshot = false on RDS | Ensures a backup exists before any database deletion |

Time saved: 45-60 minutes per module of review and rework.

### Skill: security-review

A structured security audit Claude runs against your Terraform code before any apply. Produces findings in CRITICAL / WARNING / INFO / PASSED format.

Security reviews done by humans under time pressure miss things. A structured automated review catches the same class of issues every time.

What it checks:
- Network: any ingress open to 0.0.0.0/0, SSH or RDP exposed to internet
- IAM: policies with wildcard actions or resources, admin-level EC2 permissions
- S3: all four public access blocks, encryption, versioning
- RDS: encrypted, deletion protection, backups, not publicly accessible
- Drift: compares live AWS state against Terraform code when MCP is available

Example output:
CRITICAL — port 22 open to 0.0.0.0/0 on aws_security_group.bastion
WARNING  — backup_retention_period = 0 on aws_db_instance.main
PASSED   — port 3306 restricted to EC2 SG on aws_security_group.rds

Time saved: 30-45 minutes of manual security review per module.

### Hooks — Automated Quality Enforcement

Hooks are scripts that fire automatically at specific moments in the Claude Code workflow. Unlike Skills which teach Claude what to do, hooks enforce that it was done correctly — without relying on anyones memory.

#### Hook 1: pre-write-fmt

Fires before every .tf file save. Runs terraform fmt automatically.

Problem it eliminates: "The CI failed because of formatting" — a common and entirely avoidable failure. Without this hook, someone has to remember to run terraform fmt before every commit. With this hook, it is impossible to save a badly formatted .tf file.

#### Hook 2: pre-commit-block-state

Fires before every git commit. Scans staged files for .tfstate, .tfstate.backup, and .tfvars files. If found, blocks the commit with a clear error message.

Problem it eliminates: State files and credentials accidentally committed to git. Terraform state files contain the full record of your infrastructure including sensitive values. This has caused real security incidents at real companies. This hook makes it impossible.

#### Hook 3: post-apply-update-docs

Fires after terraform apply. Reminds Claude to check whether any new patterns were established and update CLAUDE.md.

Problem it eliminates: Project memory that becomes stale. CLAUDE.md is only useful if it stays current. Without this hook, CLAUDE.md drifts out of sync with reality.

### GitHub Actions Workflows

#### pr.yml — Pull Request Pipeline

Runs on every pull request that touches .tf or .tfvars files.

Infrastructure changes are irreversible in ways that application code changes are not. A bad deployment can destroy databases, expose resources to the internet, or incur thousands of dollars in unexpected costs. This pipeline is the last line of defence before changes reach production.

| Step | What it does | Why it matters |
|---|---|---|
| terraform fmt | Checks formatting | Catches whitespace issues that cause apply failures |
| terraform validate | Syntax check | Catches HCL errors before they waste CI minutes |
| TFLint | Lint rules | Catches deprecated syntax and AWS best practice violations |
| tfsec | Security scan | Finds security misconfigurations before they reach AWS |
| terraform plan | Shows what will change | Engineers see exactly what AWS will do |
| Claude AI summary | Plain-English explanation | Non-technical reviewers understand the impact |

The Claude AI plan summary transforms this:

  Plan: 0 to add, 14 to change, 0 to destroy.

Into this:

  Changes: Adding a pipeline tag to 14 existing resources.
  No infrastructure is being created or destroyed.
  Risk Level: Low — tag-only changes, no service impact.
  Cost Impact: None — tags do not affect billing.
  Recommendation: Safe to merge.

A non-technical engineering manager can read this and make an informed approval decision in 10 seconds.

#### deploy.yml — Deployment Pipeline

Runs terraform apply automatically when code is merged to main.

Manual applies from local machines are dangerous — different engineers may have different versions, different credentials, different local state. Centralised applies from CI ensure every deployment uses the same process and leaves an audit trail.

OIDC authentication means no AWS keys are stored anywhere. GitHub generates a short-lived token for each workflow run. AWS validates it and issues temporary 15-minute credentials. When the job completes, the credentials expire automatically. There are no permanent keys to rotate, leak, or manage.

#### drift.yml — Weekly Drift Detection

Runs every Monday at 1am UTC. Compares live AWS infrastructure against Terraform code. If they differ, creates a GitHub Issue with a Claude-written analysis.

Drift happens when engineers make emergency changes in the AWS console, when AWS auto-modifies resources, or when other automation touches resources. Catching it weekly means it is a Monday morning routine, not a Friday afternoon crisis.

Claude analyses the drift and produces:

  Resources that have drifted:
  1. Security group rule for port 8080 exists in AWS but not in Terraform.
     Likely added manually during an incident.
     Recommended action: Add to Terraform if permanent, remove from AWS if not.

  2. EC2 instance type changed from t3.micro to t3.small in AWS.
     Likely a manual resize.
     Recommended action: Update Terraform to match or revert AWS to match.

## Requirements

| Requirement | Minimum version | Why |
|---|---|---|
| Claude Code | 2.1.0+ | Skills and Hooks API required |
| Terraform | 1.7.0+ | for_each on lifecycle rules |
| AWS CLI | Any recent | Local plan and apply |
| GitHub repository | Any | Workflows require GitHub Actions |
| Anthropic API key | Any | Claude AI plan summary in CI |
| Python 3 | 3.8+ | Claude API call in workflows |

## Install on Windows

```powershell
# Step 1 — clone the plugin
git clone https://github.com/kkumarb310/devops-iac-plugin.git

# Step 2 — go to your Terraform project
cd your-terraform-project

# Step 3 — run the installer
& ..\devops-iac-plugin\install.ps1
```

What the installer does:
1. Creates .claude/skills/ with both Skill files
2. Creates .claude/hooks/ with all three hook scripts
3. Creates .claude/settings.json wiring hooks into Claude Code
4. Creates .github/workflows/ with all three workflow files
5. Creates CLAUDE.md template if one does not already exist

## Install on Linux or Mac

```bash
git clone https://github.com/kkumarb310/devops-iac-plugin.git
cd your-terraform-project
bash ../devops-iac-plugin/install.sh
```

## After Install — 5 Steps to Get Fully Operational

### Step 1 — Update CLAUDE.md

Open CLAUDE.md and replace all placeholders:
- [PROJECT NAME] — your project name
- [YOUR_ACCOUNT_ID] — your AWS account ID (run: aws sts get-caller-identity)
- [YOUR_REGION] — your AWS region (e.g. ap-southeast-1)
- [YOUR_NAME] — your name or team name for the owner tag
- [YOUR_REPO_URL] — your GitHub repository URL

### Step 2 — Set up OIDC IAM role in AWS

This is the role GitHub Actions uses to deploy. No long-lived keys required.

```bash
# Create OIDC identity provider (run once per AWS account)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create trust policy file
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/YOUR_REPO:*"
      },
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      }
    }
  }]
}
EOF

# Create the role
aws iam create-role \
  --role-name YOUR_PROJECT-github-actions \
  --assume-role-policy-document file://trust-policy.json
```

### Step 3 — Update workflow files

Open each file in .github/workflows/ and update:
- ROLE_ARN — your IAM role ARN from Step 2
- AWS_REGION — your AWS region
- TF_VERSION — your Terraform version

### Step 4 — Add GitHub secrets

Go to your GitHub repository: Settings → Secrets and variables → Actions → New repository secret

| Secret name | Value | Purpose |
|---|---|---|
| ANTHROPIC_API_KEY | Your Anthropic API key | Claude AI plan summary |
| TF_VAR_db_username | Your RDS username | Passed to Terraform as variable |
| TF_VAR_db_password | Your RDS password | Passed to Terraform as variable |

Get your Anthropic API key at https://console.anthropic.com

### Step 5 — Authenticate and start

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

## Using the Skills

### Generate a module

Inside Claude Code, type:

  Generate a VPC module with public and private subnets across 2 availability zones.

Claude will:
- Read CLAUDE.md for your project standards
- Read the terraform-generate Skill
- Generate all 3 files simultaneously (main.tf, variables.tf, outputs.tf)
- Apply every standard without being asked
- Self-verify against the compliance checklist
- Remind you to run terraform state mv if refactoring existing resources

### Run a security review

Inside Claude Code, type:

  Review my security groups for issues.

Claude produces structured output:

  CRITICAL — port 22 open to 0.0.0.0/0 on aws_security_group.bastion
             Fix: restrict to your VPN CIDR or remove SSH access entirely

  WARNING  — backup_retention_period = 0 on aws_db_instance.main
             Fix: set to 7 for production workloads

  PASSED   — port 3306 restricted to EC2 SG only on aws_security_group.rds
  PASSED   — deletion_protection = true on aws_db_instance.main
  PASSED   — all four S3 public access blocks enabled

## Troubleshooting

### Summary unavailable in PR comment
Cause: ANTHROPIC_API_KEY secret not set or wrong name.
Fix: Go to GitHub Settings → Secrets → confirm the secret is named exactly ANTHROPIC_API_KEY.

### TFLint failing with missing required version
Cause: TFLint flagging missing terraform blocks in modules. This is a false positive — modules should not have provider blocks.
Fix: Add .tflint.hcl to your project root:

  rule "terraform_required_version" { enabled = false }
  rule "terraform_required_providers" { enabled = false }

### OIDC authentication failing
Cause: Trust policy condition does not match your repository path.
Fix: Check the sub condition in your trust policy matches repo:YOUR_ORG/YOUR_REPO:* exactly.

### Hooks not firing
Cause: .claude/settings.json not created or malformed.
Fix: Re-run the installer. It will merge hooks into existing settings.json.

### S3 lifecycle configuration timeout
Cause: AWS S3 lifecycle API is eventually consistent and sometimes takes over 3 minutes to respond.
Fix: Add timeouts block to your lifecycle configuration resource:

  timeouts {
    create = "10m"
    update = "10m"
  }

### State lock stuck after interrupted apply
Cause: A previous apply was interrupted before releasing the DynamoDB lock.
Fix: Run terraform force-unlock LOCK_ID where LOCK_ID is shown in the error message.

### Credentials appearing as tags on resources
Cause: Sensitive variables accidentally added inside common_tags map in tfvars.
Fix: Ensure db_username and db_password are at root level in tfvars, not inside any map block.

## Contributing

To extend this plugin:

1. Fork the repository
2. Add or update Skill files in skills/
3. Add hook scripts in hooks/
4. Update both installers (install.ps1 and install.sh) to copy new files
5. Test with a fresh empty directory
6. Submit a pull request

When adding a new Skill, follow this structure:

  ## When to invoke
  [trigger conditions — what phrases or contexts auto-invoke this Skill]

  ## Behaviour
  [what Claude should do step by step]

  ## After completing always:
  [checklist Claude self-verifies before presenting output]

When adding a new hook, add it to both installers and wire it into the settings.json block in install.ps1 and install.sh.

## Built from Real Experience

This plugin was extracted from iac-lab — a production-pattern 3-tier AWS infrastructure project (VPC + EC2 + RDS) built entirely using Claude Code over 5 days of hands-on work.

Every standard in the Skills and every hook script was developed through real issues encountered during development:
- The ignore_changes = [rule] pattern on S3 lifecycle came from hitting AWS API ordering drift repeatedly
- The timeouts blocks came from S3 and NAT gateway timeouts in ap-southeast-1
- The credentials-as-tags bug came from a real mistake during development
- The TFLint --force flag came from false positives on module files
- The Python-based Claude API call in CI came from curl failing to handle special characters in plan output

These are real solutions to real problems, not theoretical best practices.

Source project: https://github.com/kkumarb310/iac-lab

## Summary — What This Plugin Gives You

| Without plugin | With plugin |
|---|---|
| Claude generates generic Terraform | Claude generates code matching your exact standards |
| Standards enforced by human review | Standards enforced by Skill on every generation |
| Security issues caught in production | Security issues caught before apply |
| State files accidentally committed | State file commits blocked automatically |
| PR reviewers read raw HCL | PR reviewers read plain-English Claude summary |
| Drift discovered during deployments | Drift caught weekly and reported automatically |
| Terraform fmt forgotten | terraform fmt runs automatically on every save |
| 3-5 hours per week on quality work | Quality enforced automatically, time spent on architecture |

## Author

Kiran Kumar
Technical Architect — Cloud, DevOps, Agentic AI
19 years experience across banking, healthcare, retail, and consulting
AWS, Terraform, Claude Code, GitHub Actions, Observability

GitHub: https://github.com/kkumarb310
IaC Portfolio: https://github.com/kkumarb310/iac-lab
Plugin: https://github.com/kkumarb310/devops-iac-plugin
