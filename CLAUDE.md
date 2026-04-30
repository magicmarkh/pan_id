# Project: pan_id — CyberArk Identity Scaling Demos

## What This Repo Is
Closed-loop automation demo repository using CyberArk Identity (idsec Terraform provider),
GitHub Actions, and Terraform. Use cases are modular and composable — designed so individual
demos can be stitched together to add capability incrementally.

## Architecture Pattern
```
GitHub Issue Form → GitHub Actions → [production gate: human approval]
  → AWS Organizations (OIDC) → account assigned/created
  → CyberArk Identity (idsec provider, OAuth2) → SCA policies created
      → Comment on Issue → Close Issue
```

Deprovisioning is the full reverse:
```
GitHub Issue Form → GitHub Actions → [production gate]
  → CyberArk Identity → SCA policies destroyed (terraform destroy)
  → AWS Organizations → account returned to pool
      → Comment on Issue → Close Issue
```

## Current Use Cases

### 1. AWS Account Vending (`use-cases/aws-account-vending/`)
- **Trigger:** GitHub Issue labeled `provision-aws-account`
- **Form:** `.github/ISSUE_TEMPLATE/aws-account-request.yml`
- **Pipeline:** `.github/workflows/aws-account-vending.yml`
- **Modes:**
  - **Simulate** — assigns a pre-staged pool account (fast, recommended for demos)
  - **Create** — provisions a real new AWS Organizations account via Terraform

### 2. CyberArk SCA Policies (`use-cases/cyberark-sca-policy/`)
- **Not triggered directly** — invoked by the vending and deprovisioning workflows
- Creates three `idsec_policy_cloud_access` resources per account:
  - `PowerUser` — requester (GitHub issue opener), targets PowerUser permission set
  - `Audit` — auditors CyberArk group, targets Audit permission set
  - `CloudOps` — cloud-ops CyberArk group, targets CloudOps permission set
- Terraform state stored as GitHub Actions artifact `sca-tfstate-{account_id}` (90 days)

### 3. AWS Account Deprovisioning (`use-cases/` — workflow only)
- **Trigger:** GitHub Issue labeled `deprovision-aws-account`
- **Form:** `.github/ISSUE_TEMPLATE/aws-account-deprovision.yml`
- **Pipeline:** `.github/workflows/aws-account-deprovision.yml`
- Downloads SCA state artifact → `terraform destroy` → returns account to pool OU

## Key Design Decisions (Already Made — Do Not Revisit Unless Asked)
- **CyberArk SCA auth:** OAuth2 confidential client (client_id + client_secret) via idsec Terraform provider
- **AWS credential flow:** GitHub OIDC → `GitHubActionsOrgProvisioner` IAM role — no static AWS keys
- **Approval gate:** GitHub Environments (`environment: production`) on every destructive job
- **Issue parsing:** `stefanbuck/github-issue-parser@v3` maps issue form fields to job outputs
- **Dropdown freshness:** `refresh-issue-templates.yml` workflow queries AWS and rewrites YAML daily; option format is `"Name | ID"` so workflows can parse the ID back with `awk`
- **SCA policy state:** GitHub Actions artifact (not S3) — sufficient for demo lifecycle (90-day retention)
- **Terraform state for account vending:** Local (S3 backend stubbed and commented in `main.tf`)
- **idsec provider version:** `cyberark/idsec >= 0.1.0`
- **AWS provider version:** `hashicorp/aws ~> 5.0`
- **Terraform version:** `>= 1.7.0`

## Repo Structure
```
pan_id/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── aws-account-request.yml       # Provision form (dropdowns refreshed by workflow)
│   │   └── aws-account-deprovision.yml   # Deprovision form (active accounts dropdown)
│   └── workflows/
│       ├── aws-account-vending.yml       # Provision pipeline (2 jobs: provision + sca)
│       ├── aws-account-deprovision.yml   # Deprovision pipeline
│       └── refresh-issue-templates.yml  # Daily dropdown refresh (queries AWS Organizations)
├── modules/
│   ├── cyberark-policy/    # idsec_policy_cloud_access × 3 (poweruser, audit, cloudops)
│   ├── aws-account/        # aws_organizations_account resource
│   ├── cyberark-auth/      # Stub — kept for reference; auth now via idsec provider directly
│   └── aws-iam-policies/   # Stub — access via SCA permission sets, not IAM roles
├── use-cases/
│   ├── aws-account-vending/     # Create mode: Terraform for real AWS account creation
│   └── cyberark-sca-policy/     # SCA policies: idsec provider only, no AWS
├── CLAUDE.md
└── README.md
```

## GitHub Secrets Required
| Secret | Description |
|---|---|
| `CYBERARK_TENANT_URL` | CyberArk tenant URL e.g. `https://abc1234.id.cyberark.cloud` |
| `CYBERARK_SUBDOMAIN` | Tenant subdomain only e.g. `abc1234` (used by idsec Terraform provider) |
| `CYBERARK_CLIENT_ID` | OAuth2 service account client ID (`service_user` in idsec provider) |
| `CYBERARK_CLIENT_SECRET` | OAuth2 service account client secret (`service_token` in idsec provider) |
| `AWS_MANAGEMENT_ACCOUNT_ID` | 12-digit management account ID (used to construct IAM role ARNs) |
| `AWS_POOL_OU_ID` | OU ID containing pre-staged lab accounts |
| `AWS_ACTIVE_OU_ID` | OU ID where assigned/active accounts live |
| `SCA_POWER_USER_PERMISSION_SET_ARN` | IAM Identity Center permission set ARN for power user access |
| `SCA_AUDIT_PERMISSION_SET_ARN` | IAM Identity Center permission set ARN for audit read-only |
| `SCA_CLOUDOPS_PERMISSION_SET_ARN` | IAM Identity Center permission set ARN for cloud ops admin |
| `SCA_AUDIT_GROUP_NAME` | CyberArk group name for auditors |
| `SCA_CLOUDOPS_GROUP_NAME` | CyberArk group name for cloud ops |

## GitHub Environment Required
- Environment name: `production`
- Setting: Required reviewers enabled
- Location: Repo → Settings → Environments

## Lab Setup

### Pool OU Accounts
Three accounts are pre-staged in the pool OU. Before running simulate mode,
ensure all three have the following tag applied in AWS Organizations:
- Key: `Status`, Value: `Available`

The `refresh-issue-templates.yml` workflow reads these tags to populate dropdowns.

### Labels Required in GitHub
- `provision-aws-account` — triggers provisioning workflow
- `provisioned` — applied on successful provisioning
- `deprovision-aws-account` — triggers deprovisioning workflow
- `returned-to-pool` — applied on successful return to pool

### Demo Flow
1. Run **Refresh Issue Templates** workflow (or wait for daily 06:00 UTC run)
2. Open new issue → **AWS Account Request** template
3. Select **Simulate**, choose a pool account from the dropdown
4. Apply label `provision-aws-account`
5. Approve the `production` gate
6. Account moves from pool OU → active OU, tagged InUse
7. CyberArk SCA policies created for PowerUser / Audit / CloudOps
8. Issue commented with account details + SCA policy table, then closed
9. Demo the account (access via CyberArk Secure Cloud Access)
10. Open new issue → **AWS Account Deprovision Request**
11. Select the account from the dropdown, apply `deprovision-aws-account`
12. Approve the `production` gate
13. SCA policies destroyed, account returned to pool, tagged Available
14. Issue commented and closed

## AWS Prerequisites
- AWS Organizations management account must exist
- IAM role `GitHubActionsOrgProvisioner` in management account with:
  - Trust policy: GitHub OIDC (`token.actions.githubusercontent.com`)
  - Permissions: `AWSOrganizationsFullAccess` + `iam:CreateAccountAlias`, `iam:DeleteAccountAlias`, `iam:ListAccountAliases`
- IAM Identity Center permission sets pre-created for PowerUser, Audit, CloudOps
- Pool accounts pre-staged with `Status = Available` tag

## What's Built
- [x] GitHub Issue forms with dynamic dropdowns (refreshed daily from AWS)
- [x] Dropdown refresh workflow — queries pool OU, active OU, and org root OUs
- [x] Simulate mode — assigns pre-staged pool accounts via AWS Organizations tags + move
- [x] Create mode — provisions real AWS account via `aws_organizations_account` Terraform resource
- [x] Duplicate account name guard (Create mode)
- [x] OIDC authentication to AWS — no static keys
- [x] Human approval gate via GitHub Environments
- [x] CyberArk SCA policies — `idsec_policy_cloud_access` for PowerUser / Audit / CloudOps
- [x] SCA policy state persisted as GitHub Actions artifact for deprovision
- [x] Deprovisioning workflow — destroys SCA policies then returns account to pool
- [x] Issue lifecycle — success/failure comments on every job, issue closed on completion
- [x] `modules/aws-account/` — `aws_organizations_account` resource
- [x] `modules/cyberark-policy/` — three `idsec_policy_cloud_access` resources
- [x] `use-cases/aws-account-vending/` — Create mode Terraform config
- [x] `use-cases/cyberark-sca-policy/` — SCA policy Terraform config (idsec provider only)

## What's NOT Built Yet (Next Phases)

### Phase 2 — Baseline Security in Child Accounts
- [ ] CloudTrail, GuardDuty, account alias in newly created accounts (Create mode only)
- [ ] Requires a separate Terraform apply pass after account ID is known
      (blocked by aws.child provider chicken-and-egg problem on first apply)
- [ ] New module: `modules/aws-baseline-security/`

### Phase 5 — Additional Use Cases (Future)
- [ ] User onboarding — provision CyberArk Identity user + SCA policy triggered by GitHub issue
- [ ] Secrets rotation — trigger CyberArk secrets rotation via GitHub Actions
- [ ] Cross-account access — grant an existing user access to a new account

## Coding Conventions
- All Terraform modules follow: `main.tf`, `variables.tf`, `outputs.tf`
- New use cases go in `use-cases/<use-case-name>/`
- New reusable modules go in `modules/<module-name>/`
- New workflows go in `.github/workflows/<use-case-name>.yml`
- New issue forms go in `.github/ISSUE_TEMPLATE/<use-case-name>.yml`
- Every workflow must: use `environment: production` gate, comment success/failure on the issue
- Dropdown option format: `"Display Name | id-value"` — ID parsed back with `awk -F' | ' '{print $NF}' | tr -d ' '`

## CyberArk Identity Context
- Provider repo: https://github.com/cyberark/terraform-provider-idsec
- Auth endpoint: `POST {CYBERARK_TENANT_URL}/oauth2/platformtoken`
- Grant type: `client_credentials`
- SCA policy resource: `idsec_policy_cloud_access`
- `role_id` in `aws_account_targets` = IAM Identity Center **permission set ARN**
  (not an IAM role ARN — SCA federates through IAM Identity Center)

## Agent Instructions (Claude Code)

When working autonomously on this repo:

1. Always read this file fully before making any changes
2. Never commit directly to main — use feature branches
3. Do not touch files outside the scope of the current task
4. The `environment: production` gate requires manual approval — note this in output
5. When done, summarize: what changed, what was tested, what the workflow output showed
