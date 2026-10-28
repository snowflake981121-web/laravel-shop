#!/usr/bin/env bash
set -euo pipefail

REPO="snowflake981121-web/laravel-shop"
BASE_BRANCH="yolo/laravel-shop"

# Verify GitHub CLI authentication.
gh auth status

# Confirm the target repository and branch exist.
gh repo view "$REPO" --json nameWithOwner \
  --jq '.nameWithOwner'

if ! git ls-remote --exit-code --heads origin "$BASE_BRANCH" >/dev/null; then
    echo "Could not find branch ${BASE_BRANCH} on origin."
    exit 1
fi

# Avoid accidentally including uncommitted work.
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Please commit or stash your existing changes first."
    exit 1
fi

git fetch origin
git switch "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"

DOC="docs/contribution-workflow.md"
mkdir -p docs

# Open and merge two distinct documentation PRs.
for N in 1 2; do
    BRANCH="docs/pr-practice-${N}-$(date +%s)"

    git switch "$BASE_BRANCH"
    git pull --ff-only origin "$BASE_BRANCH"
    git switch -c "$BRANCH"

    # Create the documentation file if necessary.
    if [[ ! -f "$DOC" ]]; then
        cat > "$DOC" <<'EOF'
# Contribution Workflow

This document describes practices for making contributions easier
to understand, review, and maintain.
EOF
    fi

    if [[ "$N" == "1" ]]; then
        cat >> "$DOC" <<'EOF'

## Writing useful pull requests

- Keep each pull request focused on one change.
- Explain the purpose of the change in the description.
- Include testing instructions when appropriate.
EOF
        TITLE="docs: document useful pull requests"
    else
        cat >> "$DOC" <<'EOF'

## Reviewing pull requests

- Check that the change addresses its stated purpose.
- Look for regressions and missing tests.
- Give specific, actionable feedback.
EOF
        TITLE="docs: document pull request review practices"
    fi

    git add "$DOC"
    git commit -m "$TITLE"
    git push -u origin "$BRANCH"

    # Create the pull request.
    PR_URL=$(gh pr create \
        --repo "$REPO" \
        --base "$BASE_BRANCH" \
        --head "$BRANCH" \
        --title "$TITLE" \
        --body "Adds practical contribution workflow documentation.")

    echo "Created PR: $PR_URL"

    # Merge the PR if repository rules and permissions allow it.
    gh pr merge "$PR_URL" --repo "$REPO" --merge --delete-branch

    echo "Merged PR: $PR_URL"
done

git switch "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH"

echo "Finished. Check your GitHub profile for Pull Shark."
