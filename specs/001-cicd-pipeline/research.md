# Research: CI/CD Pipeline

**Feature**: 001-cicd-pipeline
**Date**: 2025-12-15

## 1. GitHub Actions for Terraform

### Decision
Use `hashicorp/setup-terraform` action with Terraform 1.5+ and native GitHub Actions for workflow orchestration.

### Rationale
- Official HashiCorp action ensures compatibility and security updates
- Built-in support for Terraform Cloud and wrapper scripts
- Outputs terraform plan as step output for PR comments
- Widely adopted pattern with extensive community examples

### Alternatives Considered
| Alternative | Why Rejected |
|-------------|--------------|
| Terraform Cloud runs | Adds complexity, free tier has limited runs, unnecessary for this scale |
| Self-hosted runners | Overkill for MVP, increases maintenance burden |
| Atlantis | Requires separate deployment, complex for small team |
| Spacelift | Commercial product, cost not justified for MVP |

### Best Practices
- Pin action versions with SHA hashes (not just tags) for security
- Use `terraform fmt -check` as separate step for clear failure messages
- Persist plan output between jobs using artifacts or PR comments
- Set `TF_IN_AUTOMATION=true` for cleaner output

## 2. GCS Backend for Terraform State

### Decision
Use Google Cloud Storage bucket with object versioning and state locking via GCS native locking.

### Rationale
- Native integration with GCP (where Firebase lives)
- Free tier includes 5GB storage (more than sufficient)
- Built-in versioning for state recovery
- No external dependencies (vs DynamoDB for AWS)

### Configuration Pattern
```hcl
terraform {
  backend "gcs" {
    bucket = "ezcopro-tfstate"
    prefix = "terraform/state"
  }
}
```

### Best Practices
- One state file per environment (staging/production)
- Enable object versioning for state recovery
- Use separate service account for state access
- Bucket should be in same region as resources

## 3. GitHub Secrets Management

### Decision
Use GitHub Environments with environment-specific secrets for staging and production.

### Rationale
- Native GitHub feature, no additional services
- Environment protection rules available (if needed later)
- Secrets scoped to specific environments prevent accidental cross-deployment
- Audit log integration for compliance

### Required Secrets
| Secret Name | Scope | Purpose |
|-------------|-------|---------|
| `GCP_SA_KEY` | Environment | Service account JSON key for Terraform |
| `FIREBASE_TOKEN` | Repository | Firebase CLI authentication |

### Best Practices
- Use Workload Identity Federation instead of SA keys when possible (future improvement)
- Rotate service account keys quarterly
- Minimal permissions per service account
- Never log secret values in workflow output

## 4. Firebase CLI Deployment

### Decision
Use Firebase CLI v13+ with `firebase deploy --only firestore:rules,firestore:indexes`.

### Rationale
- Official tooling with stable API
- Supports selective deployment (rules only, indexes only)
- Validates rules before deployment
- Can target specific project via `--project` flag

### Best Practices
- Use `firebase deploy --only` for targeted deployments
- Run `firebase deploy --dry-run` in PR validation
- Separate workflow for Firebase to avoid blocking Terraform deploys
- Pin Firebase CLI version in workflow

## 5. Workflow Concurrency Control

### Decision
Use GitHub Actions `concurrency` groups with `cancel-in-progress: false` for deployments.

### Rationale
- Prevents race conditions when multiple PRs merge quickly
- Queue behavior ensures all changes are applied in order
- Built-in GitHub feature, no external tooling needed

### Configuration Pattern
```yaml
concurrency:
  group: terraform-deploy-${{ github.ref }}
  cancel-in-progress: false
```

### Best Practices
- Use different concurrency groups per environment
- Never cancel in-progress deployments (could leave partial state)
- Allow cancel for validation workflows (PR updates)

## 6. PR Comment Integration

### Decision
Use `actions/github-script` to post Terraform plan as PR comment.

### Rationale
- Native GitHub integration
- No additional tokens required (uses GITHUB_TOKEN)
- Can update existing comment instead of creating new ones
- Supports markdown formatting for readable plans

### Alternatives Considered
| Alternative | Why Rejected |
|-------------|--------------|
| `peter-evans/create-or-update-comment` | Extra dependency when github-script suffices |
| Terraform Cloud PR integration | Requires TFC, adds complexity |
| External webhook | Unnecessary external service |

## 7. Workflow Triggers

### Decision
Use path filters to trigger workflows only when relevant files change.

### Configuration Pattern
```yaml
on:
  pull_request:
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-*.yml'
  push:
    branches: [main]
    paths:
      - 'terraform/**'
```

### Rationale
- Reduces unnecessary workflow runs (cost/time)
- Clear separation between Terraform and Firebase workflows
- Supports `workflow_dispatch` for manual re-runs

## Summary

All technical decisions align with:
- **Constitution principles**: GitOps, IaC, Security-First, Cost Awareness
- **Spec requirements**: Automated validation, staging-first deployment, notification via PR comments
- **Clarifications**: Fully automatic deployment, GCS backend, GitHub-native notifications

No blocking unknowns remain. Ready for Phase 1 design.
