#!/bin/bash
# Pre-commit hook: blocks any commit containing .tfstate or .tfvars files

BLOCKED_FILES=$(git diff --cached --name-only | grep -E '\.(tfstate|tfstate\.backup|tfvars)$')

if [ -n "$BLOCKED_FILES" ]; then
  echo "BLOCKED: Attempting to commit sensitive Terraform files:"
  echo "$BLOCKED_FILES"
  echo "Remove these files from staging: git reset HEAD <file>"
  exit 1
fi
