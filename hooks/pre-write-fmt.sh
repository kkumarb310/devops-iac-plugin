#!/bin/bash
# Pre-file-write hook: runs terraform fmt on any .tf file before Claude saves it

if [[ "$CLAUDE_HOOK_FILE" == *.tf ]]; then
  terraform fmt "$CLAUDE_HOOK_FILE"
  echo "terraform fmt applied to $CLAUDE_HOOK_FILE"
fi
