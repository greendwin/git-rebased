#!/usr/bin/bash
set -ex

REMOTE=origin
BRANCH=$(git rev-parse --abbrev-ref HEAD)
BACKUP_BRANCH="$BRANCH-backup"

if ! git rev-parse --abbrev-ref "$REMOTE/$BACKUP_BRANCH"; then
    # create backup branch
    git branch "$BACKUP_BRANCH" "$REMOTE/$BRANCH"
    git push origin "$BACKUP_BRANCH:$BACKUP_BRANCH"
    git branch -D "$BACKUP_BRANCH"
fi

# merge both backup and main branch (they can differ)
git merge -s ours "$REMOTE/$BRANCH" "$REMOTE/$BACKUP_BRANCH"
git push origin "$BRANCH:$BACKUP_BRANCH"
git reset HEAD~

git push -f 