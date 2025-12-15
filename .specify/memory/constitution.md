<!--
================================================================================
SYNC IMPACT REPORT
================================================================================
Version change: 1.1.0 → 1.1.1 (Domain configuration added)

Modified principles: None

Added sections: None

Removed sections: None

Refined:
- Environments: Added custom domain configuration (ezcopro.pleymor.com) and
  DNS management details

Templates requiring updates:
- .specify/templates/plan-template.md: ✅ No changes needed
- .specify/templates/spec-template.md: ✅ No changes needed
- .specify/templates/tasks-template.md: ✅ No changes needed
- .specify/templates/checklist-template.md: ✅ No changes needed
- .specify/templates/agent-file-template.md: ✅ No changes needed

Follow-up TODOs: None

================================================================================
-->

# EZCopro Infra Constitution

## Core Principles

### I. Infrastructure as Code

All infrastructure MUST be defined in version-controlled code. No manual changes
to cloud resources or configurations are permitted.

**Non-negotiable rules:**
- Every infrastructure resource MUST be defined in Terraform, Pulumi, or
  equivalent IaC tooling
- Manual console/CLI changes are forbidden except in documented emergency
  procedures
- All IaC code MUST pass linting and validation before merge
- State files MUST be stored remotely with proper locking mechanisms

**Rationale:** Manual infrastructure changes create drift, are unreproducible,
and bypass review processes. IaC ensures auditability and consistency.

### II. GitOps Workflow

Git is the single source of truth for all infrastructure state. All changes MUST
flow through pull requests with proper review.

**Non-negotiable rules:**
- All infrastructure changes MUST be submitted via pull request
- Direct commits to main/master are forbidden
- PRs MUST include a description of what changes and why
- Automated pipelines MUST apply changes from merged PRs (no manual applies)
- Rollbacks MUST be performed via revert commits, not manual intervention

**Rationale:** GitOps provides auditability, enables collaboration, and ensures
all changes are reviewed before deployment.

### III. Reproducibility

Any environment MUST be fully recreatable from code at any point in time.

**Non-negotiable rules:**
- Environment configurations MUST NOT depend on undocumented external state
- All dependencies (modules, providers, images) MUST be version-pinned
- Seed data and initial configurations MUST be scriptable
- Documentation MUST exist for bootstrapping a new environment from scratch

**Rationale:** Infrastructure that cannot be reproduced is a liability. Disaster
recovery, scaling, and testing all depend on reproducibility.

### IV. Security-First

Security controls MUST be built into infrastructure from the start, not added
as an afterthought.

**Non-negotiable rules:**
- Secrets MUST be managed via dedicated secrets management (GitHub Secrets for
  CI/CD, Firebase environment config for runtime)—never committed to repositories
- All resources MUST follow least-privilege access principles
- Firestore Security Rules MUST enforce tenant isolation at the database level
- All changes to IAM policies or security rules MUST have explicit justification
- Audit logging MUST be enabled for all sensitive operations

**Rationale:** Security vulnerabilities in infrastructure are catastrophic and
expensive to remediate. Prevention is mandatory.

### V. Cost Awareness

Resource costs MUST be tracked, visible, and actively optimized.

**Non-negotiable rules:**
- All resources MUST be tagged/labeled with cost allocation metadata (project,
  environment, owner)
- Cost estimates MUST be included in PRs that add or modify resources
- Unused resources MUST be identified and removed within 30 days
- Development/staging environments MUST stay within free tier limits or use
  auto-shutdown policies

**Rationale:** Cloud costs grow silently. Proactive cost management prevents
budget overruns and waste.

## Tech Stack

**Infrastructure as Code:**
- Primary: Terraform with Google provider (for Firebase/GCP resources)
- State backend: GCS bucket with state locking, or Terraform Cloud
- Firebase CLI for Firestore rules and indexes deployment

**Cloud Providers:**
- Primary: Firebase (GCP) — Firestore, Authentication, Cloud Functions
- Hosting: Vercel (Next.js frontend deployment, free tier)
- DNS/CDN: Vercel Edge Network (included with hosting)

**Container Orchestration:** Not applicable — serverless/BaaS architecture

**CI/CD:**
- Platform: GitHub Actions
- Workflows: Terraform plan/apply, Firebase deploy, Vercel preview deployments
- Branch protection: Required status checks before merge

**Secrets Management:**
- CI/CD secrets: GitHub Secrets (encrypted, scoped to repository/environment)
- Runtime secrets: Firebase environment configuration
- Service accounts: GCP IAM with least-privilege roles

**Environments:**
- Production: `ezcopro-prod` Firebase project
  - Domain: `ezcopro.pleymor.com` (custom domain via Vercel)
  - DNS: CNAME record pointing to Vercel, managed at pleymor.com registrar
- Staging: `ezcopro-staging` Firebase project (mirrors prod configuration)
  - Domain: Vercel auto-generated URL (no custom domain for staging)
- Preview: Vercel preview deployments per PR (auto-generated URLs)

**Domain Management:**
- Root domain: `pleymor.com` (owned by project maintainer)
- Subdomain: `ezcopro.pleymor.com` for production MVP
- SSL: Automatic via Vercel (Let's Encrypt)
- DNS changes MUST be documented in IaC or this constitution

## Governance

### Amendment Procedure

1. Propose amendment via pull request to this file
2. Include rationale for the change
3. All active contributors MUST be notified
4. Minimum 48-hour review period
5. Requires approval from at least one other contributor
6. Version MUST be incremented according to versioning policy

### Versioning Policy

This constitution follows semantic versioning:
- **MAJOR**: Backward-incompatible principle removals or fundamental redefinitions
- **MINOR**: New principles added or existing principles materially expanded
- **PATCH**: Clarifications, typo fixes, non-semantic refinements

### Compliance Review

- All PRs MUST be checked against constitution principles
- Non-compliance MUST be documented and justified (see Complexity Tracking in
  plan.md)
- Repeated violations warrant a constitution review discussion

**Version**: 1.1.1 | **Ratified**: 2025-12-15 | **Last Amended**: 2025-12-15
