# Project: coud_demos — CyberArk Identity Scaling Demos

## What This Repo Is
Closed-loop automation demo repository using CyberArk Identity (idsec Terraform provider),
GitHub Actions, and Terraform. Use cases are modular and composable — designed so individual
demos can be stitched together to add capability incrementally.

## Architecture Pattern
```
GitHub Issue Form → GitHub Actions → CyberArk Identity (OAuth2 AuthN)
  → Terraform (idsec + AWS provider) → AWS Organization
      → Outputs stored back to CyberArk → Comment on Issue → Close Issue
```

## Current Use Cases

### 1. AWS Account Vending (`use-cases/aws-account-vending/`)
- **Trigger:** GitHub Issue labeled `provision-aws-account`
- **Form:** `.github/ISSUE_TEMPLATE/aws-account-request.yml`
- **Pipeline:** `.github/workflows/aws-account-vending.yml`
- **What it does:** Authenticates to CyberArk, creates a new AWS Organizations account,
  applies IAM policies, comments result back on the issue, closes it

## Key Design Decisions (Already Made — Do Not Revisit Unless Asked)
- **CyberArk auth method:** OAuth2 confidential client (client_id + client_secret)
- **AWS credential flow:** Fetched at runtime via CyberArk — no static AWS keys ever in GitHub
- **Approval gate:** GitHub Environments (`environment: production`) — human approval required before any `terraform apply`
- **Issue parsing:** `stefanbuck/github-issue-parser@v3` maps issue form fields to job outputs
- **Terraform state:** Local for now — S3 backend is stubbed and commented out in `use-cases/aws-account-vending/main.tf`, ready to enable
- **idsec provider version:** `cyberark/idsec ~> 1.0`
- **AWS provider version:** `hashicorp/aws ~> 5.0`
- **Terraform version:** `>= 1.7.0`

## Repo Structure
```
coud_demos/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   └── aws-account-request.yml     # Engineer-facing request form
│   └── workflows/
│       └── aws-account-vending.yml     # Full GitHub Actions pipeline
├── modules/
│   ├── cyberark-auth/                  # idsec provider wiring (main.tf, variables.tf)
│   ├── aws-account/                    # aws_organizations_account resource (main.tf, variables.tf, outputs.tf)
│   └── aws-iam-policies/               # Phase 2 scaffold (main.tf only, empty)
├── use-cases/
│   └── aws-account-vending/            # Root Terraform config (main.tf, variables.tf)
├── CLAUDE.md                           # This file
└── README.md
```

## GitHub Secrets Required
| Secret | Description |
|---|---|
| `CYBERARK_TENANT_URL` | CyberArk tenant URL e.g. `https://abc1234.id.cyberark.cloud` |
| `CYBERARK_CLIENT_ID` | OAuth2 service account client ID |
| `CYBERARK_CLIENT_SECRET` | OAuth2 service account client secret |
| `AWS_MANAGEMENT_ACCOUNT_ID` | 12-digit management account ID used to construct IAM ARNs |

## GitHub Environment Required
- Environment name: `production`
- Setting: Required reviewers enabled
- Location: Repo → Settings → Environments

## AWS Prerequisites (Not Yet Configured)
- AWS Organizations management account must exist
- IAM role `GitHubActionsOrgProvisioner` needed in management account
- `GitHubActionsOrgProvisioner` IAM role must have `AWSOrganizationsFullAccess` managed policy attached (least-privilege refinement deferred)
- The role also requires `organizations:ListAccounts` for the duplicate account name check step
- Trust policy for that role: not yet written — next item to build
- Required permissions: `organizations:CreateAccount`, `organizations:ListAccounts`, `iam:*`, `sso:*`

## What's Built
- [x] GitHub Issue form (aws-account-request.yml)
- [x] GitHub Actions workflow (parse → approve → auth → terraform)
- [x] OIDC authentication to AWS (no static keys)
- [x] Duplicate account name guard
- [x] `modules/aws-account/` — creates `aws_organizations_account` (CloudTrail/GuardDuty deferred to Phase 2)
- [x] CyberArk auth module scaffold
- [x] IAM policies module scaffold
- [x] Use-case root Terraform config
- [x] README.md

## What's NOT Built Yet (Next Phases)
- [ ] Phase 2: baseline security in child accounts (CloudTrail, GuardDuty, account alias) — blocked on `aws.child` provider chicken-and-egg; needs separate apply pass or a data source approach
- [ ] `modules/aws-iam-policies/` — three roles (RequesterPowerUser, AuditorReadOnly, CloudOpsAdmin) — next feature
- [ ] IAM trust policy for `GitHubActionsOrgProvisioner` role
- [ ] S3 remote state backend setup
- [ ] CyberArk idsec provider integration — future phase
- [ ] IAM Identity Center / SSO permission set assignments
- [ ] Additional use cases (future: secrets rotation, user onboarding, etc.)

## Coding Conventions
- All Terraform modules follow: `main.tf`, `variables.tf`, `outputs.tf`
- New use cases go in `use-cases/<use-case-name>/`
- New reusable modules go in `modules/<module-name>/`
- New workflows go in `.github/workflows/<use-case-name>.yml`
- New issue forms go in `.github/ISSUE_TEMPLATE/<use-case-name>.yml`
- Every workflow must: authenticate to CyberArk first, use `environment: production` gate,
  comment success/failure back on the triggering issue

## CyberArk Identity Context
- Provider repo: https://github.com/cyberark/terraform-provider-idsec
- Auth endpoint: `POST {CYBERARK_TENANT_URL}/oauth2/platformtoken`
- Grant type: `client_credentials`
- Token is short-lived, masked immediately in logs with `::add-mask::`
- Token is passed to Terraform as `TF_VAR_cyberark_token` (sensitive)