---
name: security
description: Use for any feature that stores data, handles auth, secrets, network calls, user input, or financial/personal data.
---

# Security

- Encrypt sensitive data at rest (local DB, files). Use HTTPS only.
- Secrets live in env/secure storage, never in code or git.
- Auth tokens in secure storage; session timeout; least privilege.
- Sanitize inputs; protect against injection.
- Financial/personal data: offer an app lock option; keep data out of
  logs and screenshots where possible.
