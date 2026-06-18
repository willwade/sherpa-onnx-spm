#!/bin/bash
# Installs scripts/pre-push-protect-tags as the repo's .git/hooks/pre-push.
# Safe to run repeatedly — overwrites the existing hook.

set -e

cd "$(git rev-parse --show-toplevel)"

mkdir -p .git/hooks
cp scripts/pre-push-protect-tags .git/hooks/pre-push
chmod +x .git/hooks/pre-push

echo "Installed pre-push hook at .git/hooks/pre-push"
echo "Tags on this repo are now protected from force-push / deletion."
