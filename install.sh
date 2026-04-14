#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Installing DevOps IaC Plugin..."
mkdir -p .claude/skills/terraform-generate .claude/skills/security-review .claude/hooks .github/workflows
cp "$SCRIPT_DIR/skills/terraform-generate/SKILL.md" ".claude/skills/terraform-generate/SKILL.md"
cp "$SCRIPT_DIR/skills/security-review/SKILL.md" ".claude/skills/security-review/SKILL.md"
echo "Skills installed"
cp "$SCRIPT_DIR/hooks/"*.sh ".claude/hooks/"
chmod +x .claude/hooks/*.sh
echo "Hooks installed"
cp "$SCRIPT_DIR/workflows/"*.yml ".github/workflows/"
echo "Workflows installed"
if [ ! -f "CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "CLAUDE.md"
    echo "CLAUDE.md template installed"
else
    echo "CLAUDE.md already exists - skipping"
fi
echo ""
echo "Plugin installed successfully!"
echo "Next steps:"
echo "1. Update CLAUDE.md with your project details"
echo "2. Update workflows/ with your AWS account ID and IAM role ARN"
echo "3. Add GitHub secrets: ANTHROPIC_API_KEY, TF_VAR_db_username, TF_VAR_db_password"
echo "4. Run: claude auth login && claude"
