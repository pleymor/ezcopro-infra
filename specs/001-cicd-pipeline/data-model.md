# Data Model: CI/CD Pipeline

**Feature**: 001-cicd-pipeline
**Date**: 2025-12-15

## Overview

This feature doesn't have traditional database entities. Instead, the "data model" consists of:
1. **Workflow definitions** (YAML configuration)
2. **Secret configurations** (GitHub Secrets)
3. **Terraform state structure** (GCS backend)

## 1. Workflow Entities

### Workflow: terraform-validate

| Attribute | Type | Description |
|-----------|------|-------------|
| name | string | "Terraform Validate" |
| trigger | event | `pull_request` on paths `terraform/**` |
| jobs | list | init, fmt, validate, plan, comment |
| outputs | artifact | Terraform plan output |

**States**: triggered → running → (success | failure)

### Workflow: terraform-deploy

| Attribute | Type | Description |
|-----------|------|-------------|
| name | string | "Terraform Deploy" |
| trigger | event | `push` to `main` on paths `terraform/**` |
| environments | list | [staging, production] |
| concurrency | group | `terraform-deploy-${{ github.ref }}` |

**States**: queued → staging-deploy → production-deploy → (success | failure)

**State Transitions**:
```
queued → staging-deploy (on trigger)
staging-deploy → production-deploy (on staging success)
staging-deploy → failure (on staging error)
production-deploy → success (on prod success)
production-deploy → failure (on prod error)
```

### Workflow: firebase-deploy

| Attribute | Type | Description |
|-----------|------|-------------|
| name | string | "Firebase Deploy" |
| trigger | event | `push` to `main` on paths `firebase/**` |
| targets | list | [firestore:rules, firestore:indexes] |

**States**: triggered → validate → deploy → (success | failure)

## 2. Secret Entities

### GitHub Environment: staging

| Secret | Required | Purpose |
|--------|----------|---------|
| GCP_SA_KEY | Yes | Service account JSON for Terraform (staging project) |
| GCP_PROJECT_ID | Yes | `ezcopro-staging` |

### GitHub Environment: production

| Secret | Required | Purpose |
|--------|----------|---------|
| GCP_SA_KEY | Yes | Service account JSON for Terraform (prod project) |
| GCP_PROJECT_ID | Yes | `ezcopro-prod` |

### Repository Secrets (shared)

| Secret | Required | Purpose |
|--------|----------|---------|
| FIREBASE_TOKEN | Yes | Firebase CLI authentication token |

## 3. Terraform State Structure

### State Backend Configuration

| Attribute | Value |
|-----------|-------|
| bucket | `ezcopro-tfstate` |
| prefix | `terraform/state` |
| location | `us-central1` (or same as Firebase) |

### State Files

| Path | Environment | Contents |
|------|-------------|----------|
| `terraform/state/staging/default.tfstate` | staging | Staging infra state |
| `terraform/state/production/default.tfstate` | production | Production infra state |

## 4. Relationships

```
┌─────────────────┐     triggers      ┌─────────────────┐
│  Pull Request   │─────────────────▶│ terraform-      │
│                 │                   │ validate        │
└─────────────────┘                   └─────────────────┘
                                              │
                                              │ posts comment
                                              ▼
                                      ┌─────────────────┐
                                      │  PR Comments    │
                                      └─────────────────┘

┌─────────────────┐     triggers      ┌─────────────────┐
│  Merge to main  │─────────────────▶│ terraform-      │
│  (terraform/)   │                   │ deploy          │
└─────────────────┘                   └────────┬────────┘
                                               │
                          ┌────────────────────┴────────────────────┐
                          │                                         │
                          ▼                                         ▼
                  ┌───────────────┐                         ┌───────────────┐
                  │ staging env   │────────on success──────▶│ production    │
                  │ (GCP_SA_KEY)  │                         │ env           │
                  └───────────────┘                         └───────────────┘

┌─────────────────┐     triggers      ┌─────────────────┐
│  Merge to main  │─────────────────▶│ firebase-       │
│  (firebase/)    │                   │ deploy          │
└─────────────────┘                   └─────────────────┘
```

## 5. Validation Rules

### Workflow Triggers
- Terraform workflows MUST only trigger on `terraform/**` path changes
- Firebase workflows MUST only trigger on `firebase/**` path changes
- Deploy workflows MUST only trigger on `main` branch

### Secrets
- Environment secrets MUST be scoped to their specific environment
- Service account keys MUST have minimal required permissions
- FIREBASE_TOKEN MUST be valid and not expired

### State
- State bucket MUST have versioning enabled
- State files MUST be isolated per environment (no shared state)
- State locking MUST be enabled to prevent concurrent modifications
