---
name: cloud-accounts
description: Use when a project needs Google Cloud, Firebase, Google sign-in, Supabase or other cloud services — creating the cloud project, enabling auth, and getting API keys and config on your own using the account details the owner gives for that project.
---

# Cloud Accounts

Account details are **project-specific**. The owner gives them per
project (at kickoff or when a feature needs a service). With them, you
create the cloud project, get the keys and configure the app yourself —
no further help needed.

## 1. Get the account details

At kickoff (or first time a service is needed), ask the owner in ONE
message which services the project uses and for their details:

| Service | What to ask for |
|---------|-----------------|
| Google Cloud / Firebase | Service-account key JSON (Owner role), billing account ID, org/folder ID if any |
| Google sign-in | OAuth client ID + secret (or permission to use the one in the GCP project) |
| Supabase | Personal access token, org ID, DB password, region |
| Others (Stripe, OpenAI, etc.) | API key / token for that service |

Best: owner puts them as **environment variables in this project's
Claude Code cloud environment** (survives every session). Suggested names:
`GCP_SA_KEY_JSON`, `GCP_BILLING_ACCOUNT_ID`, `GCP_PARENT`,
`GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`,
`SUPABASE_ACCESS_TOKEN`, `SUPABASE_ORG_ID`, `SUPABASE_DB_PASSWORD`.

If the owner pastes them in chat instead → save to `.env` (gitignored)
and tell the owner to also add them to the cloud environment, because
`.env` is lost when the session ends.

## 2. Log in

```bash
printf '%s' "$GCP_SA_KEY_JSON" > /tmp/gcp-sa.json && chmod 600 /tmp/gcp-sa.json
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp-sa.json
gcloud auth activate-service-account --key-file=/tmp/gcp-sa.json
npx -y firebase-tools projects:list      # uses GOOGLE_APPLICATION_CREDENTIALS
npx -y supabase projects list            # uses SUPABASE_ACCESS_TOKEN
```

## 3. Create and configure

**Firebase / Google Cloud**
1. `gcloud projects create <id> [--organization|--folder]`, link billing,
   then `npx -y firebase-tools projects:addfirebase <id>`.
   Creation blocked (service account has no org)? Ask the owner to
   create the project once and add the service-account email as Owner.
2. `gcloud services enable <apis> --project <id>`
3. `npx -y firebase-tools apps:create <WEB|ANDROID|IOS> <name> --project <id>`
4. `npx -y firebase-tools apps:sdkconfig <platform> <appId> --project <id>`
   → write into the app's config files.

**Google sign-in**
- Firebase: enable the Google provider with the OAuth client.
- Supabase: `PATCH https://api.supabase.com/v1/projects/<ref>/config/auth`
  with `external_google_enabled`, `external_google_client_id`,
  `external_google_secret`.
- Redirect URIs / authorized domains can't be set by API → send the
  owner the exact URIs to add in Google Cloud Console, in one message.

**Supabase**
1. `npx -y supabase projects create <name> --org-id "$SUPABASE_ORG_ID" --db-password "$SUPABASE_DB_PASSWORD" --region <region>`
2. `npx -y supabase projects api-keys --project-ref <ref>`

## 4. Save and record

- Keys → `.env` (gitignored). Keep `.env.example` with names only.
- Public keys (Firebase web config, Supabase anon/publishable key) may
  go in client code. Secret keys (service_role, OAuth secret, service
  accounts) → server side only.
- In `docs/PROJECT.md` → "Cloud accounts": service, project ID/ref,
  region, account email. **No secret values.**

## Rules

- Never commit, log, or paste secret values in chat or PRs. Show only
  the variable name or last 4 characters.
- Ask the owner before creating paid resources or deleting anything.
- Network blocked (`*.googleapis.com`, `api.supabase.com`, ...) → tell
  the owner to allow it in the cloud environment's network settings.
