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
  → AWS (assume child OrganizationAccountAccessRole) → cost-free VPC in child account
      + CyberArk SIA access policy (connector pool scoped to that VPC/subnet/account)
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
- Creates three `idsec_policy_cloud_access` resources per account, all using ROLE principals:
  - `PowerUser` — `CYBERARK_POWERUSER_ROLE` role, targets PowerUser permission set
  - `Audit` — `CYBERARK_AUDITOR_ROLE` role, targets Audit permission set
  - `CloudOps` — `CYBERARK_CLOUDOPS_ROLE` role, targets CloudOps permission set
- All policies: `Recurring`, Mon-Fri 08:00–18:00 UTC, 1 hour max session
- Terraform state stored as GitHub Actions artifact `sca-tfstate-{account_id}` (90 days)

### 3. SIA Infrastructure (`use-cases/aws-sia-infrastructure/`)
- **Not triggered directly** — invoked by the vending workflow as the `apply-sia-infrastructure` job (runs after `provision-account`, in parallel with the SCA job).
- Two providers wired in one apply:
  - **AWS (`aws.child`)** assumes `OrganizationAccountAccessRole` in the vended account and builds a **cost-free VPC** via `modules/aws-network/`: VPC, public + private subnets, IGW, public route table, an *empty* private route table (**no NAT gateway** — private subnet has no egress by design), a free S3 gateway VPC endpoint, and SSH/RDP/DB security groups (ingress scoped to the VPC CIDR). **No EC2, no EIP, no RDS — zero recurring AWS cost.**
  - **CyberArk (`idsec`)** creates a per-account SIA access policy via `modules/cyberark-sia/`: `idsec_cmgr_network` + `idsec_cmgr_pool` + three `idsec_cmgr_pool_identifier`s scoping access to the account's VPC / private subnet / account ID.
- State stored as GitHub Actions artifact `sia-infra-tfstate-{account_id}` (90 days), destroyed on deprovision.
- Compute (EC2 targets, SIA connector) is intentionally omitted — add it during a live demo when needed.

### 4. CyberArk SIA Settings (`use-cases/cyberark-sia-settings/`)
- **Trigger:** `workflow_dispatch` only (`.github/workflows/cyberark-sia-settings.yml`) — run **once per tenant**.
- Tenant-wide `idsec_sia_settings_*` objects are **singletons**, so they must NOT be created per-vend. Ported verbatim from murphys_lab: MFA caching (adb/rdp/ssh/k8s/token), cert validation, logon sequence, RDP file-transfer/kerberos/keyboard/recording/transcription, SSH command audit, standing access.

### 5. AWS Account Deprovisioning (`.github/workflows/aws-account-deprovision.yml`)
- **Trigger:** GitHub Issue labeled `deprovision-aws-account`
- **Form:** `.github/ISSUE_TEMPLATE/aws-account-deprovision.yml`
- **Multi-account:** dropdown is multi-select; one parallel matrix runner per account
- Per-account: download SCA state artifact → `terraform destroy` (SCA) → download SIA-infra state artifact → `terraform destroy` (VPC + SIA pool) → return account to pool OU
- Single `notify` job aggregates results, posts one summary comment, closes issue, triggers refresh

### 6. Refresh Issue Templates (`.github/workflows/refresh-issue-templates.yml`)
- **Triggers:** daily at 06:00 UTC, `workflow_dispatch`, or `workflow_run` after vending/deprovisioning completes
- Queries AWS Organizations and rewrites the YAML dropdown options:
  - **Pool OU** accounts tagged `Status=Available` → provision form (`pool_account`)
  - **Active OU** accounts → deprovision form (`active_account`)
  - Direct child OUs of org root → provision form `target_ou`
- **Two-OU model:** the deprovision dropdown only lists accounts in `AWS_ACTIVE_OU_ID`. Accounts in other OUs (other demo environments) are intentionally invisible and cannot be deprovisioned through this pipeline.
- Vending and deprovision workflows also call `createWorkflowDispatch` on success for immediate refresh

## Key Design Decisions (Already Made — Do Not Revisit Unless Asked)
- **CyberArk SCA auth:** OAuth2 confidential client (`service_user` / `service_token`) via idsec Terraform provider; tenant identified by `subdomain` only (not full URL). The `subdomain` value must be the ISP tenant *name* (prefix of `<name>.cyberark.cloud`), NOT the underlying Identity tenant ID (prefix of `<id>.id.cyberark.cloud`). The provider resolves all service endpoints via `platform-discovery.cyberark.cloud/api/v2/services/subdomain/<name>`.
- **SCA policy principals:** All three policies (PowerUser, Audit, CloudOps) use ROLE principals (type=ROLE in the idsec API). CyberArk Identity's role-based access construct is what SCA expects — what looks like a "Group" in the admin UI is exposed as a Role in the SCA API. Per-user (USER) principals were dropped because GitHub usernames are not federated with the CyberArk Identity tenant. Add demo users to the relevant CyberArk Identity roles instead of federating.
- **AWS credential flow:** GitHub OIDC → `GitHubActionsOrgProvisioner` IAM role — no static AWS keys
- **Approval gate:** GitHub Environments (`environment: production`) on every destructive job
- **Issue parsing:** `stefanbuck/github-issue-parser@v3` maps issue form fields to job outputs
- **Dropdown freshness:** `refresh-issue-templates.yml` queries AWS and rewrites YAML; option format is `"Name | ID"` so workflows can parse the ID back with `awk -F' [|] '`
- **Multi-account deprovision parsing:** comma-separated multi-select string → JSON array `[{id, name}, ...]` consumed by `strategy.matrix`
- **OU return on deprovision:** uses `aws organizations list-parents` to confirm current parent, then moves only if the account is in the active OU. Skipped if already in pool. Fails if account is in any other OU (defends adjacent demo environments).
- **SCA policy state:** GitHub Actions artifact (not S3) — sufficient for demo lifecycle (90-day retention)
- **SCA policy naming:** policy names get a 6-char `random_string` suffix (`aws-<account_name>-<role>-<suffix>`) so the same `account_name` can cycle through provision → deprovision → re-provision without hitting `UAP1000 The policy name must be unique`. The suffix is keyed on `account_id` so it's stable within one terraform state, but a fresh apply (post-deprovision) gets a new suffix.
- **Terraform state for account vending:** Local (S3 backend stubbed and commented in `main.tf`)
- **Cost-free VPC (no NAT):** the SIA VPC deliberately has **no NAT gateway / no Elastic IP** (would be ~$32/mo on a non-reimbursed lab). The private subnet has an empty route table (no egress); free S3 access is via a Gateway VPC endpoint. When compute is added later, put internet-facing hosts in the **public subnet (IGW, free)** or use a free EC2 Instance Connect Endpoint — never a NAT. No EC2/RDS is created at all (no billable compute).
- **Cross-account VPC creation:** the `aws-sia-infrastructure` use-case creates the VPC *inside the vended (child) account* via a second AWS provider aliased `child` that `assume_role`s into `OrganizationAccountAccessRole`. This runs as a post-provision job (account already exists → no chicken-and-egg, unlike the Phase-2 baseline-security note). The vending workflow probes `sts:assume-role` in a retry loop first (new accounts take a moment to become assumable).
- **Per-account SIA pool vs tenant-wide settings:** the per-account SIA *access policy* (`idsec_cmgr_network`/`pool`/`pool_identifier`, named with the same `account_id`-keyed random suffix as SCA policies) is created per vend and destroyed on deprovision. The tenant-wide `idsec_sia_settings_*` are **singletons** — split into a one-time `cyberark-sia-settings` `workflow_dispatch`, NOT created per vend.
- **idsec provider version:** `cyberark/idsec >= 0.1.0` for SCA (`idsec_policy_cloud_access`, verified against 0.2.7). The SIA code (`modules/cyberark-sia`, `use-cases/aws-sia-infrastructure`, `use-cases/cyberark-sia-settings`) requires **`>= 0.4.0`** — the `idsec_cmgr_*` and `idsec_sia_settings_*` resources need 0.4.x. Separate use-case dirs → separate lock files, no conflict. (Only 0.x releases exist — DO NOT use `~> 1.0`.)
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
│       ├── aws-account-vending.yml       # Provision pipeline (provision + sca + sia-infra jobs)
│       ├── aws-account-deprovision.yml   # Deprovision pipeline (parse + matrix + notify)
│       ├── cyberark-sia-settings.yml     # One-time tenant-wide SIA settings (workflow_dispatch)
│       └── refresh-issue-templates.yml   # Dropdown refresh (daily, dispatch, workflow_run)
├── modules/
│   ├── cyberark-policy/    # idsec_policy_cloud_access × 3 (poweruser, audit, cloudops)
│   ├── cyberark-sia/       # idsec_cmgr_network + pool + pool_identifier (SIA access policy)
│   ├── aws-account/        # aws_organizations_account resource
│   └── aws-network/        # cost-free VPC: subnets, IGW, S3 gw endpoint, SGs (NO NAT)
├── use-cases/
│   ├── aws-account-vending/       # Create mode: Terraform for real AWS account creation
│   ├── cyberark-sca-policy/       # SCA policies: idsec provider only, no AWS
│   ├── aws-sia-infrastructure/    # VPC (child account) + SIA access policy per vend
│   └── cyberark-sia-settings/     # Tenant-wide idsec_sia_settings_* (one-time apply)
├── CLAUDE.md
└── README.md
```

## GitHub Secrets Required
| Secret | Description |
|---|---|
| `CYBERARK_SUBDOMAIN` | ISP tenant subdomain **name** e.g. `murphyslab` — the prefix of `<subdomain>.cyberark.cloud`. NOT the Identity tenant ID (e.g. `abv4527`). Used by idsec provider via `platform-discovery.cyberark.cloud/api/v2/services/subdomain/<value>` |
| `CYBERARK_CLIENT_ID` | OAuth2 service account client ID (`service_user` in idsec provider) |
| `CYBERARK_CLIENT_SECRET` | OAuth2 service account client secret (`service_token` in idsec provider) |
| `AWS_MANAGEMENT_ACCOUNT_ID` | 12-digit management account ID (used to construct the GitHubActionsOrgProvisioner IAM role ARN) |
| `AWS_POOL_OU_ID` | OU ID containing pre-staged lab accounts (provision dropdown source) |
| `AWS_ACTIVE_OU_ID` | OU ID where assigned/active accounts live (deprovision dropdown source) |
| `SCA_POWER_USER_PERMISSION_SET_ARN` | IAM Identity Center permission set ARN for power user access |
| `SCA_AUDIT_PERMISSION_SET_ARN` | IAM Identity Center permission set ARN for audit read-only |
| `SCA_CLOUDOPS_PERMISSION_SET_ARN` | IAM Identity Center permission set ARN for cloud ops admin |
| `CYBERARK_POWERUSER_ROLE` | CyberArk Identity role name for power user access — all three SCA policies use roles, not groups or individual users (CyberArk Identity exposes role-based principals as type=ROLE in the SCA API) |
| `CYBERARK_AUDITOR_ROLE` | CyberArk Identity role name for auditors |
| `CYBERARK_CLOUDOPS_ROLE` | CyberArk Identity role name for cloud ops |

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
0. (One-time per tenant) Run **CyberArk SIA Settings (one-time)** workflow to apply tenant-wide `idsec_sia_settings_*`
1. Run **Refresh Issue Templates** workflow (or wait for daily 06:00 UTC run, or rely on auto-refresh after the previous demo)
2. Open new issue → **AWS Account Request** template
3. Select **Simulate**, choose a pool account from the dropdown
4. Apply label `provision-aws-account`
5. Approve the `production` gate
6. Account moves from pool OU → active OU, tagged InUse
7. CyberArk SCA policies created for PowerUser / Audit / CloudOps
8. A cost-free VPC is created in the vended account and a CyberArk SIA access policy (connector pool) is scoped to it
9. Issue commented with account details + SCA policy table + VPC/SIA pool, then closed
10. Demo the account (access via CyberArk Secure Cloud Access)
11. Open new issue → **AWS Account Deprovision Request**
12. Select **one or more** accounts from the multi-select dropdown, apply `deprovision-aws-account`
13. Approve the `production` gate (one approval covers all selected accounts)
14. Each account runs its own matrix runner: SCA policies destroyed, VPC + SIA access policy destroyed, account returned to pool, tagged Available
15. Single summary comment posted; issue closed when all accounts succeed

## AWS Prerequisites
- AWS Organizations management account must exist
- IAM role `GitHubActionsOrgProvisioner` in management account with:
  - Trust policy: GitHub OIDC (`token.actions.githubusercontent.com`)
  - Permissions: `AWSOrganizationsFullAccess` + `iam:CreateAccountAlias`, `iam:DeleteAccountAlias`, `iam:ListAccountAliases`
  - **`sts:AssumeRole` on `arn:aws:iam::*:role/OrganizationAccountAccessRole`** — required for the SIA VPC job to build networking inside the vended child account. `OrganizationAccountAccessRole` exists by default in Organizations-created accounts (pool + newly created) and grants AdministratorAccess in the child.
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
- [x] `modules/aws-network/` — cost-free VPC (subnets, IGW, S3 gateway endpoint, SGs; **no NAT / no compute**)
- [x] `modules/cyberark-sia/` — SIA access policy (`idsec_cmgr_network`/`pool`/`pool_identifier`) scoped to VPC/subnet/account
- [x] `use-cases/aws-sia-infrastructure/` — VPC in child account (via `aws.child` assume-role) + per-account SIA access policy, wired into vending as `apply-sia-infrastructure`, torn down on deprovision
- [x] `use-cases/cyberark-sia-settings/` — tenant-wide `idsec_sia_settings_*` (one-time `workflow_dispatch`)
- [x] CyberArk Secure Infrastructure Access (SIA) integrated into provision/deprovision lifecycle

## What's NOT Built Yet (Next Phases)

### Phase 2 — Baseline Security in Child Accounts
- [ ] CloudTrail, GuardDuty, account alias in newly created accounts (Create mode only)
- [ ] Requires a separate Terraform apply pass after account ID is known
      (blocked by aws.child provider chicken-and-egg problem on first apply)
- [ ] New module: `modules/aws-baseline-security/`

### Phase 3 — SIA Working Access (Future, opt-in due to cost)
- [ ] EC2 targets (Linux/Windows) + a SIA connector host inside the VPC so infra access actually brokers end-to-end
- [ ] These are the only billable pieces — gate behind an `enable_*` variable, deploy in the **public subnet (IGW, free)** or via a free EC2 Instance Connect Endpoint, and destroy after the demo. Still NO NAT gateway.
- [ ] `idsec_sia_access_connector` registration (verify schema first — not yet used in this repo)

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
- Available versions: `0.x` only (NO `1.x` releases). SCA code uses `>= 0.1.0` (verified against 0.2.7); SIA code (`idsec_cmgr_*`, `idsec_sia_settings_*`) needs `>= 0.4.0`
- Provider block uses `auth_method = "identity_service_user"`, `service_user`, `service_token`, `subdomain`

### `idsec_policy_cloud_access` schema (verified against working policy from CyberArk SE)

The schema as actually accepted by the SCA API differs in several ways from the
provider's terraform-plugin-framework JSON dump — the dump describes what's
*parseable*, not what the server *accepts*. Use this section as the source of
truth; it reflects a payload that creates a policy successfully.

**`metadata`**
- `name` (required, string)
- `description` (optional, string)
- `status = { status = "Active" }` (required to create an enabled policy)
- `policy_entitlement` (required):
  - `target_category` = `"Cloud console"` for AWS console access
  - `location_type` = `"AWS"` / `"Azure"` / `"GCP"`
  - **DO NOT set `policy_type`** — server 500s
- `time_zone` (optional) — IANA name e.g. `"America/New_York"`, `"Etc/UTC"`. NOT `"UTC"` (server 500s) and NOT `"GMT"`
- `policy_tags` (optional, list of string)

**`principals`** (list of objects)
- `name`, `type` (`USER` / `GROUP` / `ROLE` — uppercase). `source_directory_id` is optional and the server resolves the directory if omitted

**`targets`**
- Use `aws_organization_targets` for AWS console access (NOT `aws_account_targets` — that path 500s):
  - `role_id` (required) = IAM Identity Center permission set ARN
  - `workspace_id` (required) = 12-digit AWS account ID
  - `org_id` (required) = the AWS Organizations *management account ID* (12 digits, NOT `o-xxxx` org ID)

**`conditions`**
- `max_session_duration` (number, hours, default 1)
- `access_window`:
  - `days_of_the_week` — list of numbers, Mon=1 … Sun=7 (NOT Sun=0)
  - `from_hour` / `to_hour` — `HH:MM:SS` strings (NOT ISO 8601 datetimes — server 500s on those)

**`delegation_classification`** (optional) — `"Unrestricted"` or `"Restricted"`

### SIA resources (verified against murphys_lab, provider `~> 0.4`)

Ported verbatim from `magicmarkh/murphys_lab` applied code — NOT guessed. Source paths:
`terraform_code/05_cyberark_config/connector_pools/main.tf` and `.../sia_settings/main.tf`.

**`idsec_cmgr_network`** — a connector-manager network. Attr: `name`. Output: `network_id`.

**`idsec_cmgr_pool`** — a connector-manager pool (the SIA access-policy object). Attrs:
`name`, `description`, `assigned_network_ids` (list of `network_id`). Output: `pool_id`.

**`idsec_cmgr_pool_identifier`** — a typed scope identifier attached to a pool. Attrs:
`pool_id`, `value`, `type`. Types used: `AWS_VPC` (value = vpc id), `AWS_SUBNET`
(value = `"<vpc_id>/<subnet_id>"`), `AWS_ACCOUNT_ID` (value = 12-digit account id). Other
types seen in murphys_lab: `GENERAL_FQDN` (glob like `*.cyberark.cloud`).

**`idsec_sia_settings_*`** — tenant-wide SINGLETON toggles (one per tenant). Managed once in
`use-cases/cyberark-sia-settings/`, never per-vend. Resources + key attrs: `_adb/_rdp/_ssh/_k8s/_rdp_token_mfa_caching`
(`client_ip_enforced`, `is_mfa_caching_enabled`, `key_expiration_time_sec`), `_certificate_validation`
(`enabled`), `_logon_sequence` (`always_use_sia`, `logon_sequence`), `_rdp_file_transfer`/`_rdp_recording`/`_rdp_transcription`
(`enabled`), `_rdp_kerberos_auth_mode` (`auth_mode`), `_rdp_keyboard_layout` (`layout`), `_ssh_command_audit`
(`is_command_parsing_for_audit_enabled`, `shell_prompt_for_audit`), `_standing_access`
(`standing_access_available`, `adb/rdp/ssh_standing_access_available`, `session_max_duration`, `session_idle_time`, `fingerprint_validation`).

NOTE: murphys_lab expresses SIA infra access through connector pool + typed identifiers + these
settings — there is no separate `idsec_sia_access_policy` resource in use. NOT-YET-USED SIA
resources (e.g. `idsec_sia_access_connector`, strong-account/VM-secret, target-set) require
verifying the schema before use, per the rule below.

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
