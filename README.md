# make-smsenmasse

Official [SMS en Masse](https://www.smsenmasse.fr) integration for [Make](https://www.make.com) (formerly Integromat).

Send SMS campaigns, check your credit balance, and list your campaigns directly from your Make scenarios — no code required.

---

## Features

- **Trigger**: SMS Campaign Status Updated — instant webhook trigger fired when a delivery status (DLR) is updated
- **Module**: Send SMS Campaign — create and send an SMS to one or more recipients instantly or on a schedule
- **Module**: Get Balance — retrieve the number of SMS credits available on your account
- **Module**: List Campaigns — list your SMS campaigns with pagination

---

## Prerequisites

- A [Make](https://www.make.com) account
- An **SMS en Masse** account with an API key → [Sign up free](https://www.smsenmasse.fr/v1/public/register/) (20 free SMS included)

---

## Authentication

API Key authentication. Your key is sent via the `X-API-KEY` header on every request.

Find your API key in your SMS en Masse account under **Settings → Authentication → apiKeyAuth**.

---

## Development

### Option A — VS Code (recommended for daily development)

1. Install the [Make Apps Editor](https://marketplace.visualstudio.com/items?itemName=Integromat.apps-sdk) extension in VS Code
2. Add your Make API key and zone in the extension settings
3. Edit the `makecomapp.json` file → update the `baseUrl` to match your zone (`eu1.make.com`, `us1.make.com`…)
4. Create the `.secrets/apikey` file with your Make API key (already gitignored)
5. Right-click any component file → **Deploy to Make (beta)** to push changes

### Option B — CLI (CI/CD and automation)

```bash
# Install dependencies
npm install

# Copy and fill environment variables
cp .env.example .env
# Edit .env: MAKE_API_KEY, MAKE_ZONE, MAKE_APP_NAME

# First deployment — creates the app, connection, webhook and modules
npm run deploy:init

# Subsequent deployments — updates all code sections
npm run deploy
```

---

## GitHub Actions CI/CD

The workflow `.github/workflows/deploy-make.yml` auto-deploys on every push to `main`.

**One-time setup** (repo Settings → Secrets → Actions):

| Secret | Value |
|---|---|
| `MAKE_API_KEY` | Your Make API key |
| `MAKE_ZONE` | Your Make zone (e.g. `eu1.make.com`) |
| `MAKE_APP_NAME` | Internal app name on Make (e.g. `smsenmasse`) |

**Bootstrap** (first deployment):
1. Go to **Actions → Deploy to Make → Run workflow**
2. Select mode = `init`
3. Run

All subsequent pushes to `main` deploy automatically (mode = `update`).

---

## Publishing to the Make Marketplace

The CLI and CI/CD handle **code deployment** only. The publication process requires additional manual steps:

### Step 1 — Prepare test scenarios

Before submitting for review, Make requires:
- Every module used in **at least one test scenario** on your account
- Test scenarios **run immediately** before requesting review
- Execution logs **must not contain** personal or sensitive data

### Step 2 — Publish the app

Open your app in the Make developer portal → click **Publish**.
This splits the app into a development version (only you) and a public version (pending review).

### Step 3 — Request review

A **Review** tab appears after publishing. Fill in:
- API documentation link → [https://www.smsenmasse.fr/docs](https://www.smsenmasse.fr/docs)
- Links to your test scenarios
- App categories: `marketing`, `communication`
- Contact / support information

Click **Request review**. Make QA will review the app (typical duration: 4–6 weeks).

### Step 4 — After approval

Make publishes the app to all users. Future code changes pushed via CI/CD go to your **development version** only — you must request a new review to update the public version.

---

## Project structure

```
make-smsenmasse/
├── makecomapp.json           # VS Code extension project file (origins, components)
├── app.json                  # App metadata (label, version, description)
├── base.json                 # Base URL and shared headers
├── connections/
│   └── apiKey/
│       ├── api.json          # Validation request (GET /sms/balance)
│       └── parameters.json   # API Key input field
├── modules/
│   ├── sendCampaignSms/
│   │   ├── meta.json         # type-id, label, description
│   │   ├── api.json          # POST /sms communication
│   │   ├── parameters.json   # Input fields
│   │   └── interface.json    # Output fields
│   ├── getBalance/
│   │   ├── meta.json
│   │   ├── api.json
│   │   └── interface.json
│   ├── listCampaigns/
│   │   ├── meta.json
│   │   ├── api.json
│   │   ├── parameters.json
│   │   └── interface.json
│   └── campaignStatus/
│       ├── meta.json         # type-id=10 (instant trigger)
│       └── interface.json    # Webhook payload fields
├── webhooks/
│   └── dlrReceiver/
│       └── meta.json         # DLR webhook receiver definition
├── deploy.sh                 # Deploy script (CLI-based)
├── package.json              # @makehq/cli dependency + npm scripts
└── .github/
    └── workflows/
        └── deploy-make.yml   # CI/CD: auto-deploy on push to main
```

---

## Module type IDs

| Module | type-id | Make type |
|---|---|---|
| `sendCampaignSms` | 4 | Action |
| `getBalance` | 4 | Action |
| `listCampaigns` | 9 | Search |
| `campaignStatus` | 10 | Instant Trigger |

---

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

---

## License

MIT — © [Acetelecom / SMS en Masse](https://www.smsenmasse.fr)
