# AWS Account Vending System

Closed-loop AWS account provisioning demo using GitHub Actions, Idira Identity, Secrets Manager SaaS, and Terraform.

## Architecture

```
GitHub Issue Form → Label Applied → GitHub Actions
  → Parse Issue → Production Approval Gate
  → AWS Organizations (OIDC) → Account assigned/created
  → Idira Identity (idsec provider) → SCA policies created
  → Comment on Issue → Close Issue → Refresh Issue Templates
```

Deprovisioning is the full reverse, supporting multiple accounts in a single issue:

```
GitHub Issue Form (multi-select) → Label Applied → GitHub Actions
  → Parse Issue → Production Approval Gate
  → Matrix job per account (parallel, fail-fast: false):
       Idira SCA policies destroyed (terraform destroy)
       AWS account returned to pool OU
  → Single summary comment → Close Issue → Refresh Issue Templates
```

## Repository Structure

```
.
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── aws-account-request.yml       # Provision form (single account, Simulate/Create modes)
│   │   └── aws-account-deprovision.yml   # Deprovision form (multi-select)
│   └── workflows/
│       ├── aws-account-vending.yml        # Provision pipeline
│       ├── aws-account-deprovision.yml    # Deprovision pipeline
│       └── refresh-issue-templates.yml    # Dropdown refresh (daily + after every run)
├── modules/
│   ├── idira-policy/                      # idsec_policy_cloud_access × 3 (poweruser, audit, cloudops)
│   └── aws-account/                       # aws_organizations_account resource
├── use-cases/
│   ├── aws-account-vending/               # Create mode: Terraform for real AWS account creation
│   └── idira-sca-policy/                  # SCA policies: idsec provider only, no AWS
├── CLAUDE.md                              # Project instructions for Claude Code
└── README.md
```

## Prerequisites

### GitHub Secrets

| Secret | Value format |
|---|---|
| `IDIRA_SUBDOMAIN` | Tenant subdomain prefix only, e.g. `murphyslab` (not a full URL) |
| `SECRETSMGR_URL` | `https://<tenant>.secretsmgr.cyberark.cloud` |
| `SECRETSMGR_ACCOUNT` | Account name, typically `conjur` |
| `SECRETSMGR_JWT_AUTHENTICATOR_ID` | JWT authenticator service ID, e.g. `github` |
| `SECRETSMGR_AUDIENCE` | Audience value configured in the JWT authenticator, e.g. `magicmarkh` |
| `SCA_SERVICE_ACCT_USERNAME_PATH` | Secrets Manager variable path for Idira service user client ID |
| `SCA_SERVICE_ACCT_PASSWORD_PATH` | Secrets Manager variable path for Idira service user client secret |
| `AWS_MANAGEMENT_ACCOUNT_ID` | 12-digit AWS management account ID |
| `AWS_POOL_OU_ID` | OU ID for pre-staged pool accounts |
| `AWS_ACTIVE_OU_ID` | OU ID for accounts currently in use |
| `SCA_POWER_USER_PERMISSION_SET_ARN` | IAM Identity Center permission set ARN for power user |
| `SCA_AUDIT_PERMISSION_SET_ARN` | IAM Identity Center permission set ARN for audit |
| `SCA_CLOUDOPS_PERMISSION_SET_ARN` | IAM Identity Center permission set ARN for cloud ops |
| `IDIRA_POWERUSER_ROLE` | Idira Identity role name for power user access |
| `IDIRA_AUDITOR_ROLE` | Idira Identity role name for auditors |
| `IDIRA_CLOUDOPS_ROLE` | Idira Identity role name for cloud ops |

### GitHub Environment

Create an environment named `production` under **Settings → Environments** with required reviewers enabled. Every destructive workflow step gates on this environment.

### GitHub Labels

Create the following labels in the repository:
- `provision-aws-account` — triggers the provisioning workflow
- `provisioned` — applied on successful provisioning
- `deprovision-aws-account` — triggers the deprovisioning workflow
- `returned-to-pool` — applied on successful deprovisioning

### AWS Setup

- IAM role `GitHubActionsOrgProvisioner` in the management account:
  - Trust: GitHub OIDC (`token.actions.githubusercontent.com`)
  - Permissions: `AWSOrganizationsFullAccess`, `iam:CreateAccountAlias`, `iam:DeleteAccountAlias`, `iam:ListAccountAliases`
- IAM Identity Center permission sets pre-created for PowerUser, Audit, CloudOps
- Pool OU accounts pre-staged and tagged `Status=Available`

### Secrets Manager SaaS Setup

- JWT authenticator (`authn-jwt`) configured for GitHub OIDC
- Host identity in Secrets Manager with the annotation `authn-jwt/<service-id>/repository_id` set to the numeric GitHub repository ID
- Host granted `authenticate` on the webservice and `execute` on the two variable resources (client ID path and client secret path)

## Demo Flow

1. Run **Refresh Issue Templates** (or wait for the 06:00 UTC daily run)
2. Open **Issues → New Issue → AWS Account Request**
3. Select **Simulate**, choose a pool account from the dropdown
4. Submit the issue and apply the label `provision-aws-account`
5. Approve the `production` gate in the Actions tab
6. Account moves from pool OU → active OU, tagged InUse
7. Idira SCA policies created for PowerUser, Audit, CloudOps roles
8. Issue receives a comment with account details and SCA policy table, then closes
9. Access the account via Idira Secure Cloud Access
10. Open **Issues → New Issue → AWS Account Deprovision Request**
11. Select one or more accounts from the multi-select dropdown
12. Apply the label `deprovision-aws-account` and approve the `production` gate
13. Each account runs in its own matrix job: SCA policies destroyed, account returned to pool
14. A single summary comment is posted; issue closes when all accounts complete successfully

## Provisioning Modes

**Simulate** (recommended for demos): Assigns a pre-staged account from the pool OU. Fast — no AWS account creation. Account is tagged `InUse` and moved to the active OU.

**Create**: Provisions a real AWS Organizations account via `aws_organizations_account` Terraform resource. Slower (~5 min). Enforces unique account name check before applying.

## Credential Flow

AWS credentials are obtained via GitHub OIDC → `GitHubActionsOrgProvisioner` IAM role — no static AWS keys anywhere.

Idira (idsec provider) credentials are fetched at runtime from Secrets Manager SaaS:
1. GitHub OIDC JWT is exchanged with the Secrets Manager JWT authenticator
2. The resulting session token is used to read the service account client ID and secret
3. These are injected as `TF_VAR_idira_client_id` and `TF_VAR_idira_client_secret`

## Security

- No static credentials stored in GitHub — all sensitive values retrieved at runtime
- Production approval gate required before any account changes
- Two-OU safety model: deprovision only touches accounts in `AWS_ACTIVE_OU_ID`; accounts in any other OU are blocked with a hard error
- SCA policy names include a `random_string` suffix keyed on account ID to prevent name collisions across provision/deprovision cycles
- SCA Terraform state retained as a GitHub Actions artifact for 90 days (sufficient for demo lifecycle)
