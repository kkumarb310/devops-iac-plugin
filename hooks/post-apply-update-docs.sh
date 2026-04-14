#!/bin/bash
# Post-apply hook: reminds Claude to update CLAUDE.md with new patterns

echo "Apply complete. Review if any new patterns were established:"
echo "1. New module created? Add to modules list in CLAUDE.md"
echo "2. New naming convention used? Document in CLAUDE.md"
echo "3. New lifecycle pattern needed? Add to terraform-generate SKILL.md"
echo "Ask Claude: Did this apply establish any new patterns to document?"
