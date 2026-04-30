# AWS Account Vending System

An automated, closed-loop AWS account provisioning system using GitHub Actions, CyberArk Identity for authentication, and Terraform for infrastructure as code.

## 🏗️ Architecture Overview

This system provides a self-service AWS account vending machine that:

1. **Request Phase**: Users submit AWS account requests via GitHub issues using a structured form
2. **Authentication Phase**: CyberArk Identity provides OAuth2-based authentication and authorization
3. **Approval Phase**: Production environment gate requires manual approval before provisioning
4. **Provisioning Phase**: Terraform creates and configures the AWS account with baseline security settings
5. **Feedback Phase**: Results are posted back to the GitHub issue, which is automatically closed on success

```
┌─────────────────┐
│  GitHub Issue   │
│  (Request Form) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Label Applied:  │
│ provision-aws-  │
│    account      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ GitHub Actions  │
│   Triggered     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Parse Issue    │
│     Form        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   CyberArk      │
│ Authentication  │
│  (OAuth2)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Production    │
│ Approval Gate   │
│  (Required)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Terraform     │
│ Init/Plan/Apply │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AWS Account    │
│   Provisioned   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Issue    │
│  Close Issue    │
└─────────────────┘
```

## 📁 Repository Structure

```
.
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   └── aws-account-request.yml       # GitHub issue form template
│   └── workflows/
│       └── aws-account-vending.yml        # Main automation workflow
│
├── modules/
│   ├── cyberark-auth/                     # CyberArk Identity auth module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── aws-account/                       # AWS account provisioning module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── aws-iam-policies/                  # IAM roles and policies module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── use-cases/
│   └── aws-account-vending/               # Root Terraform configuration
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── README.md
```

## 🚀 Getting Started

### Prerequisites

1. **GitHub Repository Secrets**: Configure the following secrets in your repository settings:
   - `CYBERARK_SUBDOMAIN`: Tenant subdomain only (e.g. `abc1234`, not the full URL)
   - `CYBERARK_CLIENT_ID`: OAuth2 client ID for CyberArk Identity
   - `CYBERARK_CLIENT_SECRET`: OAuth2 client secret for CyberArk Identity

2. **GitHub Environment**: Create a `production` environment in your repository settings with required reviewers for approval gates

3. **AWS Credentials**: Configure AWS credentials for the GitHub Actions runner (via IAM role or secrets)

4. **Terraform Backend**: Update the backend configuration in [use-cases/aws-account-vending/main.tf](use-cases/aws-account-vending/main.tf) for remote state storage

### Configuration Steps

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd <repository-name>
   ```

2. **Configure GitHub Secrets**:
   - Navigate to **Settings** → **Secrets and variables** → **Actions**
   - Add the three required CyberArk secrets

3. **Set up Production Environment**:
   - Navigate to **Settings** → **Environments**
   - Create a new environment named `production`
   - Add required reviewers under **Protection rules**

4. **Implement Terraform Modules**:
   - Complete the implementation in `modules/cyberark-auth/`
   - Complete the implementation in `modules/aws-account/`
   - Complete the implementation in `modules/aws-iam-policies/`

## 📝 How to Request an AWS Account

### Step 1: Create a New Issue

1. Navigate to the **Issues** tab in this repository
2. Click **New Issue**
3. Select **AWS Account Request** template

### Step 2: Fill Out the Request Form

Provide the following required information:

- **Account Name**: Alphanumeric name for the account (e.g., `my-app-prod`)
- **Account Email**: Unique root email address (e.g., `aws-myapp-prod@company.com`)
- **Environment**: Select `dev`, `staging`, or `prod`
- **Owner Team**: Team responsible for the account (e.g., `platform-engineering`)
- **Business Justification**: Explain why this account is needed

### Step 3: Submit and Label

1. Submit the issue
2. Add the label `provision-aws-account` to trigger the workflow
3. Wait for the production approval gate (required for all provisioning)

### Step 4: Approve (Approvers Only)

If you're a designated approver:
1. Review the account request details
2. Navigate to the **Actions** tab and find the pending workflow run
3. Review and approve the deployment to the `production` environment

### Step 5: Monitor Progress

- The workflow will comment on the issue with:
  - Terraform plan output (before apply)
  - Success/failure status
  - Account details upon completion
- The issue will automatically close upon successful provisioning

## 🔒 Security Features

### CyberArk Identity Integration
- OAuth2 client credentials flow for secure authentication
- Token-based access control
- Secrets retrieved from CyberArk vault (when implemented)

### Production Approval Gate
- All account provisioning requires manual approval
- Designated reviewers must approve before Terraform runs
- Prevents unauthorized or accidental account creation

### Terraform State Security
- Remote state storage with encryption (configure in `main.tf`)
- State locking to prevent concurrent modifications
- Sensitive outputs marked as sensitive

### AWS Account Security Baseline
- CloudTrail enabled by default
- AWS Config enabled by default
- GuardDuty enabled by default
- Baseline IAM roles with least-privilege access
- MFA required for production accounts

## 🔧 Workflow Details

### Trigger
The workflow triggers when an issue receives the `provision-aws-account` label.

### Steps
1. **Parse Issue**: Extract request parameters from the GitHub issue form
2. **Authenticate**: Obtain OAuth2 token from CyberArk Identity
3. **Approval Gate**: Wait for manual approval (production environment)
4. **Terraform Init**: Initialize Terraform working directory
5. **Terraform Plan**: Generate and comment execution plan on the issue
6. **Terraform Apply**: Provision the AWS account and resources
7. **Update Issue**: Post results and close issue on success

### Environment Variables
The workflow passes the following variables to Terraform:
- `TF_VAR_account_name`
- `TF_VAR_account_email`
- `TF_VAR_environment`
- `TF_VAR_owner_team`
- `TF_VAR_cyberark_token`

## 🛠️ Development & Customization

### Adding Custom IAM Policies

Edit [modules/aws-iam-policies/main.tf](modules/aws-iam-policies/main.tf) to add custom policies for specific teams or use cases.

### Modifying Account Baseline

Update [modules/aws-account/main.tf](modules/aws-account/main.tf) to change baseline configurations like:
- Organizational Units (OUs)
- Additional AWS services
- Account-level settings

### Extending the Request Form

Modify [.github/ISSUE_TEMPLATE/aws-account-request.yml](.github/ISSUE_TEMPLATE/aws-account-request.yml) to add additional fields. Remember to update the workflow to parse new fields.

## 📊 Monitoring & Troubleshooting

### View Workflow Runs
- Navigate to **Actions** tab to see all workflow executions
- Click on a specific run to view detailed logs

### Common Issues

**Authentication Failure**:
- Verify CyberArk secrets are correctly configured
- Check token expiration settings
- Ensure OAuth2 client has appropriate permissions

**Terraform Errors**:
- Review Terraform outputs in the issue comments
- Check AWS credentials and permissions
- Verify account email is unique across the organization

**Approval Timeout**:
- Ensure production environment has designated reviewers
- Check reviewer availability
- Workflow will wait indefinitely until approved or canceled

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test with a dev environment account request
4. Submit a pull request with a clear description

## 📄 License

[Specify your license here]

## 🆘 Support

For issues or questions:
- Create an issue in this repository
- Contact the Platform Engineering team
- Refer to internal documentation

---

**Note**: This is a scaffold implementation. Complete the TODO items in the Terraform modules before using in production.
