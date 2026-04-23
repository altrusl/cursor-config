#!/bin/bash
# Sync lissa skills from cursor-config to all Lissa Health repositories
# Run from cursor-config directory

LISSA_PATH="/src/lissa-health"
SKILLS_SOURCE="/src/cursor-config/skills/lissa"

echo "Syncing lissa skills to all repositories..."

# Backend
echo "→ Backend"
rm -rf "$LISSA_PATH/backend/.cursor/skills/lissa-"* 2>/dev/null
cp -r "$SKILLS_SOURCE"/* "$LISSA_PATH/backend/.cursor/skills/"

# Frontend
echo "→ Frontend"
rm -rf "$LISSA_PATH/frontend/.cursor/skills/lissa-"* 2>/dev/null
cp -r "$SKILLS_SOURCE"/* "$LISSA_PATH/frontend/.cursor/skills/"

# Docs
echo "→ Docs"
rm -rf "$LISSA_PATH/docs/.cursor/skills/lissa-"* 2>/dev/null
cp -r "$SKILLS_SOURCE"/* "$LISSA_PATH/docs/.cursor/skills/"

# Organization
echo "→ Organization"
rm -rf "$LISSA_PATH/organization/.cursor/skills/lissa-"* 2>/dev/null
cp -r "$SKILLS_SOURCE"/* "$LISSA_PATH/organization/.cursor/skills/"

echo "Done! Skills synced to all repositories."
echo ""
echo "To commit changes, run in each repo:"
echo "  git add .cursor/skills/ && git commit -m 'chore(cursor): sync lissa skills'"
