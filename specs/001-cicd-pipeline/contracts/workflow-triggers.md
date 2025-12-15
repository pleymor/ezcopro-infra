# Workflow Trigger Contracts

**Feature**: 001-cicd-pipeline
**Date**: 2025-12-15

## Overview

This document defines the contracts for GitHub Actions workflow triggers - the "API" of the CI/CD system.

## 1. terraform-validate Workflow

### Trigger Contract

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-validate.yml'
  workflow_dispatch:
    inputs:
      pr_number:
        description: 'PR number to validate (optional)'
        required: false
        type: string
```

### Input Context

| Variable | Source | Description |
|----------|--------|-------------|
| `github.event.pull_request.number` | Event | PR number for commenting |
| `github.event.pull_request.head.sha` | Event | Commit SHA to validate |
| `github.head_ref` | Context | Branch name |

### Output Contract

| Output | Type | Description |
|--------|------|-------------|
| PR Comment | Markdown | Terraform plan formatted output |
| Check Status | pass/fail | Required for branch protection |

### Status Codes

| Status | Meaning | PR Effect |
|--------|---------|-----------|
| success | All checks pass | Merge allowed |
| failure | Validation failed | Merge blocked |
| cancelled | Workflow cancelled | Merge blocked |

---

## 2. terraform-deploy Workflow

### Trigger Contract

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - staging
          - production
          - both
      skip_staging:
        description: 'Skip staging (emergency only)'
        required: false
        type: boolean
        default: false
```

### Input Context

| Variable | Source | Description |
|----------|--------|-------------|
| `github.sha` | Context | Commit SHA being deployed |
| `github.event.head_commit.message` | Event | Commit message for audit |
| `inputs.environment` | Dispatch | Manual target override |

### Output Contract

| Output | Type | Description |
|--------|------|-------------|
| Commit Comment | Markdown | Deployment result summary |
| Deployment Status | GitHub Deployment API | Tracked deployment |

### Environment Sequence

```
staging → production (automatic on staging success)
```

### Failure Behavior

| Stage | On Failure | Action |
|-------|------------|--------|
| staging | Stop pipeline | Comment on commit, no prod deploy |
| production | Stop pipeline | Comment on commit, alert |

---

## 3. firebase-deploy Workflow

### Trigger Contract

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'firebase/**'
  workflow_dispatch:
    inputs:
      target:
        description: 'Deployment target'
        required: true
        type: choice
        options:
          - rules
          - indexes
          - both
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - staging
          - production
          - both
```

### Input Context

| Variable | Source | Description |
|----------|--------|-------------|
| `github.sha` | Context | Commit SHA being deployed |
| `inputs.target` | Dispatch | What to deploy (manual) |
| `inputs.environment` | Dispatch | Where to deploy (manual) |

### Output Contract

| Output | Type | Description |
|--------|------|-------------|
| Commit Comment | Markdown | Rules/indexes deployment result |

### Deployment Targets

| Target | Files | Firebase Command |
|--------|-------|------------------|
| rules | `firebase/firestore.rules` | `firebase deploy --only firestore:rules` |
| indexes | `firebase/firestore.indexes.json` | `firebase deploy --only firestore:indexes` |
| both | Both files | `firebase deploy --only firestore` |

---

## 4. Shared Contracts

### Concurrency

All deploy workflows share concurrency rules:

```yaml
concurrency:
  group: deploy-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false  # Never cancel deployments
```

### Required Permissions

```yaml
permissions:
  contents: read
  pull-requests: write      # For PR comments
  deployments: write        # For deployment status
  id-token: write          # For Workload Identity (future)
```

### Environment Protection

| Environment | Protection Rules |
|-------------|------------------|
| staging | None (auto-deploy) |
| production | None (auto-deploy per clarification) |

### Comment Format

All workflow comments follow this structure:

```markdown
## [Workflow Name] - [Status Emoji] [Status]

**Commit**: `<sha>`
**Environment**: <staging|production>

### [Details Section]
<collapsible details>

---
*Triggered by [commit/PR link]*
```
