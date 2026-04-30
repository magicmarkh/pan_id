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
      → Comment on Issue → Close Issue → Refresh Issue Templates
```

Deprovisioning is the full reverse and supports multiple accounts in one issue:
```
GitHub Issue Form (multi-select) → GitHub Actions → [production gate]
  → Matrix job per account (parallel, fail-fast: false):
       CyberArk Identity → SCA policies destroyed (terraform destroy)
       AWS Organizations → account returned to pool
  → Notify job: single summary comment → Close Issue → Refresh Issue Templates
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
- All policies: `Recurring`, Mon-Fri 08:00–18:00 UTC, 1 hour max session
- Terraform state stored as GitHub Actions artifact `sca-tfstate-{account_id}` (90 days)

### 3. AWS Account Deprovisioning (`.github/workflows/aws-account-deprovision.yml`)
- **Trigger:** GitHub Issue labeled `deprovision-aws-account`
- **Form:** `.github/ISSUE_TEMPLATE/aws-account-deprovision.yml`
- **Multi-account:** dropdown is multi-select; one parallel matrix runner per account
- Per-account: download SCA state artifact → `terraform destroy` → return account to pool OU
- Single `notify` job aggregates results, posts one summary comment, closes issue, triggers refresh

### 4. Refresh Issue Templates (`.github/workflows/refresh-issue-templates.yml`)
- **Triggers:** daily at 06:00 UTC, `workflow_dispatch`, or `workflow_run` after vending/deprovisioning completes
- Queries AWS Organizations and rewrites the YAML dropdown options:
  - Pool OU accounts tagged `Status=Available` → provision form
  - All org accounts EXCEPT management account and `AWS_UNUSED_OU_ID` accounts → deprovision form
  - Direct child OUs of org root → provision form `target_ou`
- Vending and deprovision workflows also call `createWorkflowDispatch` on success for immediate refresh

## Key Design Decisions (Already Made — Do Not Revisit Unless Asked)
- **CyberArk SCA auth:** OAuth2 confidential client (`service_user` / `service_token`) via idsec Terraform provider; tenant identified by `subdomain` only (not full URL)
- **AWS credential flow:** GitHub OIDC → `GitHubActionsOrgProvisioner` IAM role — no static AWS keys
- **Approval gate:** GitHub Environments (`environment: production`) on every destructive job
- **Issue parsing:** `stefanbuck/github-issue-parser@v3` maps issue form fields to job outputs
- **Dropdown freshness:** `refresh-issue-templates.yml` queries AWS and rewrites YAML; option format is `"Name | ID"` so workflows can parse the ID back with `awk -F' [|] '`
- **Multi-account deprovision parsing:** comma-separated multi-select string → JSON array `[{id, name}, ...]` consumed by `strategy.matrix`
- **OU return on deprovision:** dynamic via `aws organizations list-parents` (works regardless of which OU the account currently sits in); skipped if account is already in pool OU
- **SCA policy state:** GitHub Actions artifact (not S3) — sufficient for demo lifecycle (90-day retention)
- **Terraform state for account vending:** Local (S3 backend stubbed and commented in `main.tf`)
- **idsec provider version:** `cyberark/idsec >= 0.1.0` (only 0.x releases exist — DO NOT use `~> 1.0`)
- **AWS provider version:** `hashicorp/aws ~> 5.0`
- **Terraform version:** `>= 1.7.0`

## Repo Structure
```
pan_id/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── aws-account-request.yml       # Provision form (single account)
│   │   └── aws-account-deprovision.yml   # Deprovision form (multi-select)
│   └── workflows/
│       ├── aws-account-vending.yml       # Provision pipeline (provision + sca jobs)
│       ├── aws-account-deprovision.yml   # Deprovision pipeline (parse + matrix + notify)
│       └── refresh-issue-templates.yml   # Dropdown refresh (daily, dispatch, workflow_run)
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
| `CYBERARK_TENANT_URL` | CyberArk tenant URL e.g. `https://abc1234.id.cyberark.cloud` (used by legacy curl steps; SCA uses `CYBERARK_SUBDOMAIN`) |
| `CYBERARK_SUBDOMAIN` | Tenant subdomain only e.g. `abc1234` (used by idsec Terraform provider) |
| `CYBERARK_CLIENT_ID` | OAuth2 service account client ID (`service_user` in idsec provider) |
| `CYBERARK_CLIENT_SECRET` | OAuth2 service account client secret (`service_token` in idsec provider) |
| `AWS_MANAGEMENT_ACCOUNT_ID` | 12-digit management account ID (used to construct IAM role ARNs and to exclude from deprovision dropdown) |
| `AWS_POOL_OU_ID` | OU ID containing pre-staged lab accounts |
| `AWS_ACTIVE_OU_ID` | OU ID where assigned/active accounts live |
| `AWS_UNUSED_OU_ID` | OU ID for unprovisioned/unconfigured accounts (excluded from deprovision dropdown) |
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
1. Run **Refresh Issue Templates** workflow (or wait for daily 06:00 UTC run, or rely on auto-refresh after the previous demo)
2. Open new issue → **AWS Account Request** template
3. Select **Simulate**, choose a pool account from the dropdown
4. Apply label `provision-aws-account`
5. Approve the `production` gate
6. Account moves from pool OU → active OU, tagged InUse
7. CyberArk SCA policies created for PowerUser / Audit / CloudOps
8. Issue commented with account details + SCA policy table, then closed
9. Demo the account (access via CyberArk Secure Cloud Access)
10. Open new issue → **AWS Account Deprovision Request**
11. Select **one or more** accounts from the multi-select dropdown, apply `deprovision-aws-account`
12. Approve the `production` gate (one approval covers all selected accounts)
13. Each account runs its own matrix runner: SCA policies destroyed, account returned to pool, tagged Available
14. Single summary comment posted; issue closed when all accounts succeed

## AWS Prerequisites
- AWS Organizations management account must exist
- IAM role `GitHubActionsOrgProvisioner` in management account with:
  - Trust policy: GitHub OIDC (`token.actions.githubusercontent.com`)
  - Permissions: `AWSOrganizationsFullAccess` + `iam:CreateAccountAlias`, `iam:DeleteAccountAlias`, `iam:ListAccountAliases`
- IAM Identity Center permission sets pre-created for PowerUser, Audit, CloudOps
- Pool accounts pre-staged with `Status = Available` tag

## What's Built
- [x] GitHub Issue forms with dynamic dropdowns (refreshed daily, on demand, and after every provision/deprovision)
- [x] Dropdown refresh workflow — queries pool OU, all org accounts (excluding management + Unused OU), and org root OUs
- [x] Simulate mode — assigns pre-staged pool accounts via AWS Organizations tags + move
- [x] Create mode — provisions real AWS account via `aws_organizations_account` Terraform resource
- [x] Duplicate account name guard (Create mode)
- [x] OIDC authentication to AWS — no static keys
- [x] Human approval gate via GitHub Environments
- [x] CyberArk SCA policies — `idsec_policy_cloud_access` for PowerUser / Audit / CloudOps, schema-aligned (Recurring, Mon-Fri 08:00-18:00 UTC, 1h sessions)
- [x] SCA policy state persisted as GitHub Actions artifact for deprovision
- [x] Deprovisioning workflow with multi-account support — matrix job per account, fail-fast disabled, single summary comment
- [x] Dynamic OU return on deprovision via `aws organizations list-parents` (no hardcoded source OU)
- [x] Skip-if-already-in-pool guard for `move-account` (prevents `DuplicateAccountException` on re-runs)
- [x] Auto-refresh of issue templates after every provision/deprovision (via `createWorkflowDispatch` and `workflow_run`)
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
- Every workflow must: use `environment: production` gate on destructive steps, comment success/failure on the issue
- Dropdown option format: `"Display Name | id-value"` — ID parsed back with `awk -F' [|] ' '{print $NF}' | tr -d ' '` (note: `' [|] '` is the safe regex form; bare `'|'` is interpreted as alternation)

## CyberArk Identity Context

### Provider basics
- Provider repo: https://github.com/cyberark/terraform-provider-idsec
- Available versions: `0.1.x`–`0.2.x` only (NO `1.x` releases). Use constraint `>= 0.1.0`
- Provider block uses `auth_method = "identity_service_user"`, `service_user`, `service_token`, `subdomain`

### `idsec_policy_cloud_access` schema (verified via `terraform providers schema -json`)
**`metadata` (object, required for `name` and `policy_entitlement`)**
- `name` (required, string)
- `description` (optional, string, max 200 chars)
- `policy_entitlement` (required, object):
  - `target_category` (required) — `"Cloud console"` for AWS console access
  - `location_type` (required) — `"AWS"`, `"Azure"`, or `"GCP"`
  - `policy_type` (optional) — `"Recurring"` or `"OnDemand"`
- `time_zone` (optional, default `"GMT"`)
- `time_frame.from_time` / `to_time` (optional ISO 8601 `yyyy-MM-ddTHH:mm:ss`)
- `status`, `created_by`, `updated_on`, `policy_id` are **computed/read-only** — DO NOT set
- The resource has **no top-level `id` attribute**. The policy ID is `<resource>.metadata.policy_id`

**`delegation_classification`** (optional, string, default `"Unrestricted"`)
- Valid values: `"Unrestricted"`, `"Restricted"` — NOT `"Privileged"`

**`principals`** (list of objects)
- `name`, `type` (`USER`/`GROUP`/`ROLE` — **uppercase**), optional `id`, `source_directory_id`, `source_directory_name`

**`targets.aws_account_targets`** (list of objects)
- `role_id` (required) = IAM Identity Center **permission set ARN** (NOT an IAM role ARN — SCA federates through IAM Identity Center)
- `workspace_id` (required) = 12-digit AWS account ID

**`conditions`** (object)
- `max_session_duration` (number, **HOURS** not seconds, default 1)
- `access_window` (object):
  - `days_of_the_week` — set of numbers (Sun=0, Mon=1, …, Sat=6)
  - `from_hour` / `to_hour` — ISO 8601 datetimes (date portion ignored for recurring policies)
- There is NO `time_restrictions` attribute, NO `enforcement_type`, NO string `days` array

## Agent Instructions (Claude Code)

When working autonomously on this repo:

1. **Always read this file fully before making any changes.**
2. **Never commit directly to main — use feature branches.** When done, create a pull request.
3. **Do not touch files outside the scope of the current task.**
4. The `environment: production` gate requires manual approval — note this in output.
5. When done, summarize: what changed, what was tested, what the workflow output showed.

### Update CLAUDE.md after milestones
Whenever a milestone is completed (a new module, workflow, demo flow, or significant
fix), **update CLAUDE.md in the same PR**:
- Move items from "What's NOT Built Yet" into "What's Built"
- Update "Repo Structure" if new files/directories were added
- Update "GitHub Secrets Required" if new secrets are needed
- Update "Demo Flow" if the user-facing experience changed
- Update "Key Design Decisions" if a non-obvious choice was made
- Add to "CyberArk Identity Context" if a new provider resource is used
- Bump the schema notes if a provider version with a different schema is adopted

A milestone is anything worth telling future-you about. When in doubt, update.

### When the provider schema is unknown — ASK, don't guess
The CyberArk `idsec` provider has a complex schema and is sparsely documented online.
**Do not invent attribute names, types, or nested shapes from intuition.** Each guess
costs a workflow run, an approval, and the user's time.

If you need to use an `idsec_*` resource you've never confirmed against the schema,
**stop and ask the user for the schema before writing the resource block**. Provide
this exact instruction:

> I need the schema for the `idsec_<resource>` resource. Please run the following
> from a directory that has the provider initialized (e.g. `use-cases/cyberark-sca-policy/`):
>
> ```bash
> terraform init   # if not already initialized
> terraform providers schema -json | jq '.provider_schemas["registry.terraform.io/cyberark/idsec"].resource_schemas.idsec_<resource>'
> ```
>
> Paste the JSON output back to me and I'll write the resource block against the
> verified schema.

Same rule applies to data sources (`.data_source_schemas` instead of
`.resource_schemas`) and any other provider whose docs are inaccessible.
