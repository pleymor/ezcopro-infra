# Tasks: CI/CD Pipeline

**Input**: Design documents from `/specs/001-cicd-pipeline/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: No tests explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Workflows**: `.github/workflows/`
- **Terraform**: `terraform/environments/{staging,production}/`, `terraform/modules/`
- **Firebase**: `firebase/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure

- [x] T001 Create directory structure: `.github/workflows/`, `terraform/environments/staging/`, `terraform/environments/production/`, `terraform/modules/`, `firebase/`
- [x] T002 [P] Create `.terraform-version` file pinning Terraform to 1.5.x in `terraform/.terraform-version`
- [x] T003 [P] Create `firebase/firebase.json` with project configuration pointing to firestore.rules and indexes

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Terraform backend and base configuration that MUST be complete before workflows can function

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Create `terraform/environments/staging/backend.tf` with GCS backend config (bucket: ezcopro-tfstate, prefix: terraform/state/staging)
- [x] T005 [P] Create `terraform/environments/production/backend.tf` with GCS backend config (bucket: ezcopro-tfstate, prefix: terraform/state/production)
- [x] T006 [P] Create `terraform/environments/staging/main.tf` with provider configuration and terraform version constraints
- [x] T007 [P] Create `terraform/environments/production/main.tf` with provider configuration and terraform version constraints
- [x] T008 [P] Create `terraform/environments/staging/variables.tf` with environment-specific variables (project_id, region)
- [x] T009 [P] Create `terraform/environments/production/variables.tf` with environment-specific variables (project_id, region)
- [x] T010 Create placeholder `firebase/firestore.rules` with basic deny-all rules for initial deployment
- [x] T011 [P] Create placeholder `firebase/firestore.indexes.json` with empty indexes array

**Checkpoint**: Foundation ready - workflow implementation can now begin

---

## Phase 3: User Story 1 - Infrastructure Validation on PR (Priority: P1) 🎯 MVP

**Goal**: Automatically validate Terraform changes when a PR is opened, showing plan output in PR comments

**Independent Test**: Open a PR with Terraform changes and verify validation runs automatically with results in PR comments

### Implementation for User Story 1

- [x] T012 [US1] Create `.github/workflows/terraform-validate.yml` with workflow skeleton (name, permissions, triggers)
- [x] T013 [US1] Add PR trigger configuration to terraform-validate.yml with path filters (`terraform/**`, `.github/workflows/terraform-validate.yml`)
- [x] T014 [US1] Add workflow_dispatch trigger to terraform-validate.yml for manual runs
- [x] T015 [US1] Add checkout step using `actions/checkout@v4` in terraform-validate.yml
- [x] T016 [US1] Add Terraform setup step using `hashicorp/setup-terraform@v3` with version from .terraform-version
- [x] T017 [US1] Add GCP authentication step using `google-github-actions/auth@v2` with staging credentials
- [x] T018 [US1] Add `terraform init` step for staging environment in terraform-validate.yml
- [x] T019 [US1] Add `terraform fmt -check` step in terraform-validate.yml
- [x] T020 [US1] Add `terraform validate` step in terraform-validate.yml
- [x] T021 [US1] Add `terraform plan` step with output capture in terraform-validate.yml
- [x] T022 [US1] Add PR comment step using `actions/github-script@v7` to post plan output as formatted comment
- [x] T023 [US1] Add job status summary step to set check status (success/failure) in terraform-validate.yml

**Checkpoint**: User Story 1 complete - PR validation workflow functional

---

## Phase 4: User Story 2 - Automated Deployment on Merge (Priority: P2)

**Goal**: Automatically deploy Terraform changes to staging then production when PRs are merged to main

**Independent Test**: Merge a PR with Terraform changes and verify deployment to staging then production with commit comments

### Implementation for User Story 2

- [x] T024 [US2] Create `.github/workflows/terraform-deploy.yml` with workflow skeleton (name, permissions, concurrency group)
- [x] T025 [US2] Add push trigger to terraform-deploy.yml for main branch with path filters (`terraform/**`)
- [x] T026 [US2] Add workflow_dispatch trigger to terraform-deploy.yml with environment selection input
- [x] T027 [US2] Add concurrency configuration to terraform-deploy.yml (`group: terraform-deploy, cancel-in-progress: false`)
- [x] T028 [US2] Create staging deploy job in terraform-deploy.yml with environment reference
- [x] T029 [US2] Add checkout and Terraform setup steps to staging job in terraform-deploy.yml
- [x] T030 [US2] Add GCP authentication with staging secrets to staging job in terraform-deploy.yml
- [x] T031 [US2] Add `terraform init` and `terraform apply -auto-approve` steps to staging job
- [x] T032 [US2] Create production deploy job in terraform-deploy.yml with `needs: staging` dependency
- [x] T033 [US2] Add GCP authentication with production secrets to production job in terraform-deploy.yml
- [x] T034 [US2] Add `terraform init` and `terraform apply -auto-approve` steps to production job
- [x] T035 [US2] Add commit comment step to post deployment status (success/failure per environment)
- [x] T036 [US2] Add failure notification step using `actions/github-script@v7` to comment on commit when deployment fails

**Checkpoint**: User Story 2 complete - automated Terraform deployment workflow functional

---

## Phase 5: User Story 3 - Firebase Rules Deployment (Priority: P3)

**Goal**: Automatically deploy Firestore security rules and indexes when those files are modified

**Independent Test**: Modify firestore.rules and verify deployment to staging then production after merge

### Implementation for User Story 3

- [x] T037 [US3] Create `.github/workflows/firebase-deploy.yml` with workflow skeleton (name, permissions, concurrency group)
- [x] T038 [US3] Add push trigger to firebase-deploy.yml for main branch with path filters (`firebase/**`)
- [x] T039 [US3] Add workflow_dispatch trigger to firebase-deploy.yml with target (rules/indexes/both) and environment inputs
- [x] T040 [US3] Add concurrency configuration to firebase-deploy.yml (`group: firebase-deploy, cancel-in-progress: false`)
- [x] T041 [US3] Create staging deploy job in firebase-deploy.yml with checkout step
- [x] T042 [US3] Add Firebase CLI setup using `npm install -g firebase-tools` in staging job
- [x] T043 [US3] Add `firebase deploy --only firestore:rules,firestore:indexes --project ezcopro-staging` step with FIREBASE_TOKEN
- [x] T044 [US3] Create production deploy job in firebase-deploy.yml with `needs: staging` dependency
- [x] T045 [US3] Add `firebase deploy --only firestore:rules,firestore:indexes --project ezcopro-prod` step with FIREBASE_TOKEN
- [x] T046 [US3] Add commit comment step to post Firebase deployment status
- [x] T047 [US2] Document edge case handling in workflow comments: state lock (Terraform retries), idempotency (apply is idempotent), missing secrets (fail fast), concurrent merges (concurrency group queues)

**Checkpoint**: User Story 3 complete - all workflows functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and validation

- [x] T048 [P] Document required GitHub Secrets in specs/001-cicd-pipeline/quickstart.md (verify checklist complete)
- [x] T049 [P] Document branch protection rule configuration in specs/001-cicd-pipeline/quickstart.md
- [ ] T050 Run full pipeline test: create test branch, open PR, verify validation completes within 5 minutes (SC-001), merge, verify deployment with failure notification within 2 minutes (SC-003)
- [ ] T051 Verify concurrency handling by attempting simultaneous merges (manual test)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - US1 (P1): Can start after Foundational
  - US2 (P2): Can start after Foundational (independent of US1)
  - US3 (P3): Can start after Foundational (independent of US1/US2)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories - validates PRs
- **User Story 2 (P2)**: No dependencies on US1 - deploys Terraform on merge
- **User Story 3 (P3)**: No dependencies on US1/US2 - deploys Firebase on merge

### Within Each User Story

- Workflow skeleton before triggers
- Triggers before steps
- Authentication before Terraform/Firebase commands
- Core steps before notification steps

### Parallel Opportunities

- T002, T003 can run in parallel (Setup phase)
- T004-T011 marked [P] can run in parallel (Foundational phase)
- US1, US2, US3 can run in parallel after Foundational phase (different workflow files)
- T048, T049 can run in parallel (Polish phase)

---

## Parallel Example: Foundational Phase

```bash
# Launch all backend configs together:
Task: "Create terraform/environments/staging/backend.tf"
Task: "Create terraform/environments/production/backend.tf"

# Launch all main.tf configs together:
Task: "Create terraform/environments/staging/main.tf"
Task: "Create terraform/environments/production/main.tf"

# Launch all variables.tf together:
Task: "Create terraform/environments/staging/variables.tf"
Task: "Create terraform/environments/production/variables.tf"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (PR Validation)
4. **STOP and VALIDATE**: Open test PR, verify validation works
5. Deploy if ready - MVP delivers PR validation

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test with PR → MVP delivers PR validation
3. Add User Story 2 → Test with merge → Delivers automated Terraform deployment
4. Add User Story 3 → Test with Firebase changes → Delivers full CI/CD pipeline

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (terraform-validate.yml)
   - Developer B: User Story 2 (terraform-deploy.yml)
   - Developer C: User Story 3 (firebase-deploy.yml)
3. Each workflow is in a separate file - no conflicts

---

## Notes

- [P] tasks = different files, no dependencies
- [US#] label maps task to specific user story for traceability
- Each workflow file is independently testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All secrets must be configured in GitHub before workflows will succeed
