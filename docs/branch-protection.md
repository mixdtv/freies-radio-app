# Branch Protection Setup

## Current Rules (main branch)

- **Pull request reviews**: 1 approval required before merging
- **Dismiss stale reviews**: Enabled — approvals are dismissed when new commits are pushed
- **Direct push access**: Restricted to specific users (see restrictions in the protection config)
- **Enforce for admins**: Disabled — repo admins can bypass all protection rules (push directly, merge without reviews, etc.). Set to `true` to enforce rules for everyone, including admins.
- **Require last push approval**: Enabled — if new commits are pushed after approval, a fresh approval is required before merging
- **Required status checks**: `Analyze` workflow (runs `flutter analyze` on PRs)
- **Force pushes**: Not allowed
- **Branch deletion**: Not allowed

## Managing Branch Protection via CLI

### List repo admins

```bash
gh api repos/mixdtv/freies-radio-app/collaborators --jq '.[] | select(.permissions.admin==true) | .login'
```

### View current protection

```bash
gh api repos/mixdtv/freies-radio-app/branches/main/protection
```

### Set or update protection

```bash
gh api repos/mixdtv/freies-radio-app/branches/main/protection -X PUT --input - <<'EOF'
{
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "required_approving_review_count": 1,
    "require_last_push_approval": true
  },
  "required_status_checks": {
    "strict": true,
    "contexts": ["analyze"]
  },
  "enforce_admins": false,
  "restrictions": {
    "users": ["<your-github-username>"],
    "teams": []
  }
}
EOF
```

### Remove protection entirely

```bash
gh api repos/mixdtv/freies-radio-app/branches/main/protection -X DELETE
```

### Add a user to the push access list

```bash
gh api repos/mixdtv/freies-radio-app/branches/main/protection/restrictions/users -X POST --input - <<'EOF'
["<github-username>"]
EOF
```

### Remove a user from the push access list

```bash
gh api repos/mixdtv/freies-radio-app/branches/main/protection/restrictions/users -X DELETE --input - <<'EOF'
["<github-username>"]
EOF
```
