# Quickstart: CI/CD Pipeline

**Feature**: 001-cicd-pipeline
**Date**: 2025-12-15

## Prerequisites

Before setting up the CI/CD pipeline, ensure you have:

1. **GCP Projects** created:
   - `ezcopro-staging` (staging environment)
   - `ezcopro-prod` (production environment)

2. **GCS Bucket** for Terraform state:
   - Bucket name: `ezcopro-tfstate`
   - Location: `us-central1` (or preferred region)
   - Versioning: Enabled

3. **Service Accounts** created in each project:
   - `terraform-sa@ezcopro-staging.iam.gserviceaccount.com`
   - `terraform-sa@ezcopro-prod.iam.gserviceaccount.com`
   - With roles: `roles/editor`, `roles/storage.admin`

4. **Firebase CLI** token:
   - Run `firebase login:ci` locally
   - Save the token securely

---

## Step 1: Configure GitHub Secrets

### Repository Settings → Secrets and variables → Actions

**Repository secrets** (Settings → Secrets → Actions → New repository secret):

| Secret Name | Value |
|-------------|-------|
| `FIREBASE_TOKEN` | Token from `firebase login:ci` |

**Environments** (Settings → Environments → New environment):

Create `staging` environment with secrets:
| Secret Name | Value |
|-------------|-------|
| `GCP_SA_KEY` | JSON key for staging service account |
| `GCP_PROJECT_ID` | `ezcopro-staging` |

Create `production` environment with secrets:
| Secret Name | Value |
|-------------|-------|
| `GCP_SA_KEY` | JSON key for production service account |
| `GCP_PROJECT_ID` | `ezcopro-prod` |

---

## Step 2: Create Directory Structure

```bash
# From repository root
mkdir -p .github/workflows
mkdir -p terraform/environments/staging
mkdir -p terraform/environments/production
mkdir -p terraform/modules
mkdir -p firebase
```

---

## Step 3: Create Terraform Backend Config

**terraform/environments/staging/backend.tf**:
```hcl
terraform {
  backend "gcs" {
    bucket = "ezcopro-tfstate"
    prefix = "terraform/state/staging"
  }
}
```

**terraform/environments/production/backend.tf**:
```hcl
terraform {
  backend "gcs" {
    bucket = "ezcopro-tfstate"
    prefix = "terraform/state/production"
  }
}
```

---

## Step 4: Create Workflow Files

After implementing the tasks from `tasks.md`, you will have:

- `.github/workflows/terraform-validate.yml`
- `.github/workflows/terraform-deploy.yml`
- `.github/workflows/firebase-deploy.yml`

---

## Step 5: Configure Branch Protection

Go to **Settings → Branches → Add rule** for `main`:

- [x] Require a pull request before merging
- [x] Require status checks to pass before merging
  - Add: `Terraform Validate`
- [x] Require branches to be up to date before merging
- [ ] Do not require approvals (solo developer)

---

## Step 6: Test the Pipeline

### Test PR Validation

1. Create a new branch:
   ```bash
   git checkout -b test/cicd-validation
   ```

2. Make a small Terraform change (e.g., add a comment)

3. Push and create PR:
   ```bash
   git push -u origin test/cicd-validation
   gh pr create --title "Test: CI/CD validation" --body "Testing pipeline"
   ```

4. Verify:
   - [ ] `Terraform Validate` workflow triggers
   - [ ] Plan output appears as PR comment
   - [ ] Status check shows pass/fail

### Test Deployment

1. Merge the test PR to main

2. Verify:
   - [ ] `Terraform Deploy` workflow triggers
   - [ ] Staging deployment succeeds
   - [ ] Production deployment succeeds
   - [ ] Commit comment shows deployment status

---

## Verification Checklist

After setup, verify:

- [ ] PR to `main` with `terraform/**` changes triggers validation
- [ ] PR comment shows Terraform plan output
- [ ] Merge to `main` triggers deployment
- [ ] Staging deploys before production
- [ ] Failed deployment stops pipeline and comments
- [ ] Firebase rules changes trigger `firebase-deploy`
- [ ] Manual workflow dispatch works for all workflows

---

## Troubleshooting

### "Permission denied" on Terraform state
- Verify service account has `roles/storage.admin` on the state bucket
- Check bucket name matches backend config

### "Invalid Firebase token"
- Regenerate token with `firebase login:ci`
- Update `FIREBASE_TOKEN` secret

### Workflow not triggering
- Verify file paths match trigger patterns
- Check workflow file is in `.github/workflows/`
- Ensure workflow file has no YAML syntax errors

### Deployment stuck
- Check concurrency settings
- Look for locked Terraform state
- Verify GCP quotas not exceeded

---

## Next Steps

After CI/CD is operational:

1. Add Terraform resources for Firebase project configuration
2. Implement Firestore security rules
3. Set up Vercel deployment integration (separate workflow)
