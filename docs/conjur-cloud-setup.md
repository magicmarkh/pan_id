# Conjur Cloud — GitHub Actions OIDC Setup

This repo's workflows fetch the CyberArk Identity OAuth `client_id` and
`client_secret` from a Conjur Cloud tenant at runtime, using the GitHub Actions
OIDC token to authenticate. No long-lived CyberArk OAuth credentials live in
GitHub repository secrets.

The composite action that performs the exchange lives at
[`.github/actions/fetch-cyberark-creds`](../.github/actions/fetch-cyberark-creds/action.yml)
and uses the documented Conjur Cloud REST API
(`/authn-jwt/<service-id>/<account>/<host>/authenticate` →
`/secrets/<account>/variable/<variable-id>`).

---

## 1. Prerequisites

- A Conjur Cloud tenant. Identify its subdomain — the prefix of
  `<subdomain>.secretsmgr.cyberark.cloud`.
- Admin access to apply Conjur policy.
- The `conjur` CLI (or Secrets Manager UI) configured against the tenant.

## 2. JWKS / issuer values for GitHub Actions

GitHub's OIDC issuer values are constant:

| Field        | Value |
|--------------|-------|
| `issuer`     | `https://token.actions.githubusercontent.com` |
| `jwks-uri`   | `https://token.actions.githubusercontent.com/.well-known/jwks` |
| `audience`   | `conjur` (set by the composite action when requesting the OIDC token) |

## 3. Conjur policy — apply once

Save as `policy/github-authn-jwt.yml` and load to the **root** policy:

```yaml
# Define the JWT authenticator that trusts GitHub Actions
- !policy
  id: conjur/authn-jwt/github
  body:
    - !webservice

    - !variable jwks-uri
    - !variable issuer
    - !variable audience
    - !variable token-app-property
    - !variable identity-path
    - !variable enforced-claims

    - !group authenticatable

    - !permit
      role: !group authenticatable
      privilege: [ read, authenticate ]
      resource: !webservice

    - !webservice
      id: status
    - !group operators
    - !permit
      role: !group operators
      privilege: [ read ]
      resource: !webservice status
```

Then save the workload identity + variables as `policy/pan_id.yml` and load
under the `data` policy branch (so variable IDs are `data/...`):

```yaml
# Workload identity for the magicmarkh/pan_id repo and the secrets it can read
- !policy
  id: github
  body:
    - !policy
      id: pan_id
      body:
        - !host
          id: pan_id
          annotations:
            authn-jwt/github/repository: magicmarkh/pan_id
            # Lock to specific refs / environments as needed:
            # authn-jwt/github/ref: refs/heads/main
            # authn-jwt/github/environment: production

        - !variable cyberark-identity/client-id
        - !variable cyberark-identity/client-secret

        - !permit
          role: !host pan_id
          privileges: [ read, execute ]
          resources:
            - !variable cyberark-identity/client-id
            - !variable cyberark-identity/client-secret

# Allow the workload to authenticate via the GitHub authn-jwt service
- !grant
  role: !group conjur/authn-jwt/github/authenticatable
  member: !host data/github/pan_id/pan_id
```

## 4. Configure the JWT authenticator

Set the four required authenticator variables (one-time):

```bash
conjur variable set -i conjur/authn-jwt/github/jwks-uri \
  -v "https://token.actions.githubusercontent.com/.well-known/jwks"

conjur variable set -i conjur/authn-jwt/github/issuer \
  -v "https://token.actions.githubusercontent.com"

conjur variable set -i conjur/authn-jwt/github/audience \
  -v "conjur"

# Tells Conjur which JWT claim identifies the host. The `repository` annotation
# on the host must match this claim's value.
conjur variable set -i conjur/authn-jwt/github/token-app-property \
  -v "repository"

# Where in the policy tree to look up the host (matches the policy above)
conjur variable set -i conjur/authn-jwt/github/identity-path \
  -v "data/github/pan_id"
```

Enable the authenticator in the Conjur Cloud UI (Workloads → Authenticators →
`authn-jwt/github` → Enable), or via the `/authenticators` admin API.

## 5. Load the OAuth credential values

```bash
conjur variable set -i data/github/pan_id/cyberark-identity/client-id \
  -v "<your-cyberark-identity-oauth-client-id>"

conjur variable set -i data/github/pan_id/cyberark-identity/client-secret \
  -v "<your-cyberark-identity-oauth-client-secret>"
```

These are the same OAuth confidential-client values that previously lived in
`CYBERARK_CLIENT_ID` / `CYBERARK_CLIENT_SECRET` GitHub secrets.

## 6. Configure GitHub repo

### Repository **secrets** (still required)

| Secret | Value |
|---|---|
| `CONJUR_SUBDOMAIN` | The Conjur Cloud tenant subdomain (prefix of `<subdomain>.secretsmgr.cyberark.cloud`) |
| `CYBERARK_SUBDOMAIN` | Unchanged — the ISP tenant subdomain (e.g. `murphyslab`) |
| `AWS_*`, `SCA_*_PERMISSION_SET_ARN`, `CYBERARK_*_ROLE` | Unchanged |

Removed (now stored in Conjur Cloud):
- ~~`CYBERARK_CLIENT_ID`~~
- ~~`CYBERARK_CLIENT_SECRET`~~

### Repository **variables** (Settings → Secrets and variables → Actions → Variables)

| Variable | Example | Description |
|---|---|---|
| `CONJUR_HOST_ID` | `github/pan_id/pan_id` | Conjur host identity (without the `host/` prefix and without a leading `data/` — the action constructs the full path). Match exactly the `data/<id>` policy path. |
| `CONJUR_AUTHN_JWT_SERVICE_ID` | `github` | Service ID of the authn-jwt authenticator |
| `CONJUR_CLIENT_ID_VARIABLE` | `data/github/pan_id/cyberark-identity/client-id` | Variable path for the OAuth client_id |
| `CONJUR_CLIENT_SECRET_VARIABLE` | `data/github/pan_id/cyberark-identity/client-secret` | Variable path for the OAuth client_secret |

> **Note on `CONJUR_HOST_ID`**: the composite action prepends `host/` when
> building the authn URL, so set this variable to the resource id only —
> `data/github/pan_id/pan_id` for the policy above.

## 7. Test

Trigger the **AWS Account Request** workflow. The `apply-sca-policies` job
should log:

```
Requesting GitHub OIDC token (audience: conjur)...
Authenticating to Conjur Cloud (service: github)...
Fetching data/github/pan_id/cyberark-identity/client-id...
Fetching data/github/pan_id/cyberark-identity/client-secret...
✅ Retrieved CyberArk OAuth credentials from Conjur Cloud
```

If authentication fails (`401`), confirm:

- The host's `authn-jwt/github/repository` annotation matches the running repo
  (`magicmarkh/pan_id`).
- `token-app-property` is set to `repository`.
- The authenticator is enabled in Conjur Cloud.
- The job has `permissions: id-token: write` (already set in both workflows).

## 8. Rotation

Rotate the OAuth credentials in CyberArk Identity, then update the two
variables in Conjur Cloud — no GitHub change required.
