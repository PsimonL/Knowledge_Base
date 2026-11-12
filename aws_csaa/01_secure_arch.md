#  Design Secure Architectures 

## AWS IAM

### Console & Role Switching
- Multiple accounts/roles can be open at once in one browser (multi-session).
- **Switch Role** = `sts:AssumeRole` → temporary credentials, no re-login.
- Alternatives: separate browser profiles, **IAM Identity Center** (central SSO).

### Root User
- Created with the account. Identified by **email + 12-digit Account ID** (no IAM username).
- ARN: `arn:aws:iam::<ACCOUNT_ID>:root`
- Full access, cannot be limited by IAM policies (**SCPs** can limit it in member accounts).
- Best practices:
  - Enable **MFA**
  - **Delete access keys**
  - Don't use for daily work, only for root-only tasks (close account, change support plan, etc.)

### IAM Users vs Roles (Human Access)

| | IAM User | IAM Role / Identity Center |
|---|---|---|
| Credentials | Long-term (password, access keys `AKIA...`) | Temporary via **STS** (15 min to 12 h) |
| Risk | Leaks, manual key rotation | Low, no stored secrets |
| Verdict | Discouraged for humans | **Recommended** |

- Humans should log in via an **IdP (SAML 2.0 / OIDC)** or **IAM Identity Center**.

### Role Types (by trusted principal)
1. **AWS Service Role:** EC2, Lambda, ECS etc. call AWS APIs on your behalf.
2. **Cross-Account Role:** identities from Account A assume a role in Account B (no duplicate users).
3. **Federated Role:** SAML 2.0 (Okta, Entra ID) or OIDC (Cognito, Google).
4. **Custom Trust Policy:** custom conditions (source IP, MFA, tags).

### Trust Policy Examples
A trust policy defines **who** can assume the role.

#### Service Role (EC2)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### Cross-Account + External ID
Prevents the **Confused Deputy** problem (third-party access).
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::ACCOUNT_B_ID:root" },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": { "sts:ExternalId": "UniqueClientToken123" }
      }
    }
  ]
}
```

#### SAML 2.0 Federation
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::ACCOUNT_ID:saml-provider/Okta" },
      "Action": "sts:AssumeRoleWithSAML",
      "Condition": {
        "StringEquals": { "SAML:aud": "https://signin.aws.amazon.com/saml" }
      }
    }
  ]
}
```

### Cross-Account Access
- An AWS account is the **hard security boundary**. Default: implicit deny across accounts.
- Within one account: identity-based or resource-based policies are enough.
- Cross-account via role needs **both sides**:
  1. **Account B (target):** role with trust policy trusting Account A + permissions policy.
  2. **Account A (source):** IAM policy allowing `sts:AssumeRole` on the role's ARN in B.

### Credentials Report vs Access Advisor

| | Credentials Report | Access Advisor |
|---|---|---|
| Scope | **Account-level** | **Per user / role / group / policy** |
| Format | **CSV** download | Console UI / API |
| Shows | Password age, MFA status, access keys, last rotation | **Last accessed time per service** |
| Use case | Compliance audit, find old/unused keys | **Least privilege**, remove unused permissions |

### Exam Tips
- Need temporary credentials → **STS / roles**, not IAM users.
- EC2 needs AWS access → **instance role**, never access keys on the instance.
- Third-party access to your account → **cross-account role + External ID**.
- Find unused permissions → **Access Advisor**. Audit credentials → **Credentials Report**.
- Restrict even root in member accounts → **SCP**.