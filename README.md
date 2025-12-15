# EZCopro Infrastructure

Infrastructure as Code for the EZCopro project using Terraform and Firebase.

## Architecture

- **Cloud Provider**: Firebase (GCP)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **State Backend**: GCS bucket (`ezcopro-tfstate`)

## Structure

```
.github/workflows/
├── terraform-validate.yml   # PR validation
├── terraform-deploy.yml     # Deploy on merge
└── firebase-deploy.yml      # Firebase rules deployment

terraform/
└── environments/
    └── dev/                 # Dev environment config

firebase/
├── firestore.rules          # Firestore security rules
├── firestore.indexes.json   # Firestore indexes
└── firebase.json            # Firebase config
```

## Workflows

| Workflow | Trigger | Action |
|----------|---------|--------|
| Terraform Validate | PR to `main` | Runs `fmt`, `validate`, `plan` and comments on PR |
| Terraform Deploy | Push to `main` | Applies Terraform changes to dev |
| Firebase Deploy | Push to `main` | Deploys Firestore rules and indexes |

## Setup

### Prerequisites

- GCP project: `ezcopro-dev`
- GCS bucket: `ezcopro-tfstate` (for Terraform state)
- GitHub Environment: `dev` with secrets:
  - `GCP_SA_KEY`: Service account JSON key
  - `FIREBASE_TOKEN`: Firebase CI token

### Local Development

```bash
# Install Terraform
tfenv install

# Initialize Terraform
cd terraform/environments/dev
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply
```

## Contributing

All infrastructure changes must go through pull requests. The CI pipeline will:

1. Validate Terraform syntax and formatting
2. Show the planned changes as a PR comment
3. Apply changes automatically on merge to `main`
