# DevOps IaC Plugin — Windows Installer
# Run from your project root: & ..\devops-iac-plugin\install.ps1

Write-Host "Installing DevOps IaC Plugin..." -ForegroundColor Cyan

$PluginDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create directory structure
New-Item -ItemType Directory -Path ".claude\skills\terraform-generate" -Force | Out-Null
New-Item -ItemType Directory -Path ".claude\skills\security-review" -Force | Out-Null
New-Item -ItemType Directory -Path ".claude\hooks" -Force | Out-Null
New-Item -ItemType Directory -Path ".github\workflows" -Force | Out-Null

# Copy Skills
Copy-Item "$PluginDir\skills\terraform-generate\SKILL.md" ".claude\skills\terraform-generate\SKILL.md" -Force
Copy-Item "$PluginDir\skills\security-review\SKILL.md" ".claude\skills\security-review\SKILL.md" -Force
Write-Host "Skills installed" -ForegroundColor Green

# Copy Hooks
Copy-Item "$PluginDir\hooks\pre-write-fmt.sh" ".claude\hooks\pre-write-fmt.sh" -Force
Copy-Item "$PluginDir\hooks\pre-commit-block-state.sh" ".claude\hooks\pre-commit-block-state.sh" -Force
Copy-Item "$PluginDir\hooks\post-apply-update-docs.sh" ".claude\hooks\post-apply-update-docs.sh" -Force
Write-Host "Hooks installed" -ForegroundColor Green

# Wire hooks into Claude Code settings
$settingsPath = ".claude\settings.json"
$hooksConfig = @{
  hooks = @{
    PreToolUse = @(
      @{
        matcher = "Write|Edit|Create"
        hooks = @(@{ type = "command"; command = "bash .claude/hooks/pre-write-fmt.sh" })
      }
    )
    PostToolUse = @(
      @{
        matcher = "terraform apply"
        hooks = @(@{ type = "command"; command = "bash .claude/hooks/post-apply-update-docs.sh" })
      }
    )
  }
}

if (Test-Path $settingsPath) {
    $existing = Get-Content $settingsPath | ConvertFrom-Json
    $existing | Add-Member -MemberType NoteProperty -Name "hooks" -Value $hooksConfig.hooks -Force
    $existing | ConvertTo-Json -Depth 10 | Out-File $settingsPath -Encoding utf8 -Force
    Write-Host "Hooks wired into existing settings.json" -ForegroundColor Green
} else {
    $hooksConfig | ConvertTo-Json -Depth 10 | Out-File $settingsPath -Encoding utf8 -Force
    Write-Host "Hooks wired into new settings.json" -ForegroundColor Green
}

# Copy Workflows
Copy-Item "$PluginDir\workflows\pr.yml" ".github\workflows\pr.yml" -Force
Copy-Item "$PluginDir\workflows\deploy.yml" ".github\workflows\deploy.yml" -Force
Copy-Item "$PluginDir\workflows\drift.yml" ".github\workflows\drift.yml" -Force
Write-Host "Workflows installed" -ForegroundColor Green

# Copy CLAUDE.md template if not exists
if (-not (Test-Path "CLAUDE.md")) {
    Copy-Item "$PluginDir\CLAUDE.md" "CLAUDE.md" -Force
    Write-Host "CLAUDE.md template installed" -ForegroundColor Green
} else {
    Write-Host "CLAUDE.md already exists - skipping" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Plugin installed successfully!" -ForegroundColor Cyan
Write-Host "Next steps:"
Write-Host "1. Update CLAUDE.md with your project details"
Write-Host "2. Update workflows/ with your AWS account ID and IAM role ARN"
Write-Host "3. Add GitHub secrets: ANTHROPIC_API_KEY, TF_VAR_db_username, TF_VAR_db_password"
Write-Host "4. Run: claude auth login"
Write-Host "5. Run: claude"
