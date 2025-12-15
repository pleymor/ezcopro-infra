# Secrets Schema Contract

**Feature**: 001-cicd-pipeline
**Date**: 2025-12-15

## Overview

This document defines the required secrets and their expected formats for the CI/CD pipeline.

## Repository Secrets

### FIREBASE_TOKEN

| Property | Value |
|----------|-------|
| Scope | Repository |
| Format | String (CI token from `firebase login:ci`) |
| Rotation | Annually or on compromise |
| Used By | firebase-deploy workflow |

**Validation**:
```bash
firebase projects:list --token "$FIREBASE_TOKEN"
# Should list accessible projects
```

---

## Environment Secrets

### staging Environment

#### GCP_SA_KEY

| Property | Value |
|----------|-------|
| Scope | Environment: staging |
| Format | JSON (service account key) |
| Required Fields | `type`, `project_id`, `private_key_id`, `private_key`, `client_email` |
| Rotation | Quarterly |
| Used By | terraform-deploy (staging job) |

**Expected Structure**:
```json
{
  "type": "service_account",
  "project_id": "ezcopro-staging",
  "private_key_id": "<key-id>",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "terraform-sa@ezcopro-staging.iam.gserviceaccount.com",
  "client_id": "<client-id>",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
```

**Required IAM Roles**:
- `roles/editor` (or more restrictive based on resources)
- `roles/storage.admin` (for state bucket)

#### GCP_PROJECT_ID

| Property | Value |
|----------|-------|
| Scope | Environment: staging |
| Format | String |
| Value | `ezcopro-staging` |
| Used By | terraform-deploy, firebase-deploy |

---

### production Environment

#### GCP_SA_KEY

| Property | Value |
|----------|-------|
| Scope | Environment: production |
| Format | JSON (service account key) |
| Required Fields | Same as staging |
| Rotation | Quarterly |
| Used By | terraform-deploy (production job) |

**Expected Structure**:
```json
{
  "type": "service_account",
  "project_id": "ezcopro-prod",
  "private_key_id": "<key-id>",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "terraform-sa@ezcopro-prod.iam.gserviceaccount.com",
  ...
}
```

#### GCP_PROJECT_ID

| Property | Value |
|----------|-------|
| Scope | Environment: production |
| Format | String |
| Value | `ezcopro-prod` |
| Used By | terraform-deploy, firebase-deploy |

---

## Secret Usage in Workflows

### Authentication Pattern

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}

- name: Set up Cloud SDK
  uses: google-github-actions/setup-gcloud@v2
  with:
    project_id: ${{ secrets.GCP_PROJECT_ID }}
```

### Firebase Authentication Pattern

```yaml
- name: Deploy Firebase Rules
  env:
    FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
  run: |
    firebase deploy --only firestore:rules \
      --project ${{ secrets.GCP_PROJECT_ID }} \
      --token "$FIREBASE_TOKEN"
```

---

## Validation Checklist

Before first pipeline run, verify:

- [ ] `FIREBASE_TOKEN` is set at repository level
- [ ] `staging` environment exists in GitHub
- [ ] `staging/GCP_SA_KEY` contains valid JSON
- [ ] `staging/GCP_PROJECT_ID` is set to `ezcopro-staging`
- [ ] `production` environment exists in GitHub
- [ ] `production/GCP_SA_KEY` contains valid JSON
- [ ] `production/GCP_PROJECT_ID` is set to `ezcopro-prod`
- [ ] Service accounts have required IAM roles
- [ ] State bucket exists and is accessible by service accounts

---

## Security Notes

1. **Never log secrets** - Use `::add-mask::` for any derived values
2. **Minimal permissions** - Service accounts should have only required roles
3. **Separate accounts** - Staging and production use different service accounts
4. **Key rotation** - Rotate service account keys quarterly
5. **Audit access** - Review secret access logs in GitHub periodically
