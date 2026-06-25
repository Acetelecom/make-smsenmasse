# make-smsenmasse

Official [SMS en Masse](https://www.smsenmasse.fr) integration for [Make](https://www.make.com) (formerly Integromat).

Send SMS campaigns, check your credit balance, and list your campaigns directly from your Make scenarios — no code required.

---

## Features

- **Trigger**: SMS Campaign Status Updated — instant trigger (webhook) fired when a delivery status (DLR) is updated
- **Module**: Send SMS Campaign — create and send an SMS to one or more recipients instantly or on a schedule
- **Module**: Get Balance — retrieve the number of SMS credits available on your account
- **Module**: List Campaigns — list your SMS campaigns with pagination

---

## Prerequisites

- A [Make](https://www.make.com) account
- An **SMS en Masse** account with an API key → [Sign up free](https://www.smsenmasse.fr/v1/public/register/) (20 free SMS included)

---

## Authentication

This integration uses **API Key** authentication. Your API key is sent via the `X-API-KEY` header on every request.

Find your API key in your SMS en Masse account under **Settings → API**.

---

## Modules

### Trigger — SMS Campaign Status Updated

Instant webhook trigger fired when the delivery status of one of your SMS campaigns is updated (DLR).

Returns: campaign ID, status code, status label, number of recipients, delivered count, failed count.

### Module — Send SMS Campaign

Creates and sends an SMS campaign to one or more recipients.

| Field | Required | Description |
|---|---|---|
| Recipients | Yes | Phone numbers in international format, comma-separated (e.g. `33645332637,33667656608`) |
| Message | Yes | SMS content. Max 160 characters per SMS; longer messages are split automatically. |
| Campaign Name | No | Internal name to identify the campaign in your SMS en Masse account. |
| Sender Name | No | 3 to 11 characters, must start with a letter. Leave empty to use the default short number. |
| Scheduled Send Date | No | Format: `YYYY-MM-DD HH:mm:ss`. Leave empty for immediate sending. |
| Country | No | ISO 3166-1 alpha-2 code (default: `FR`). |
| Custom Identifier | No | Your internal reference for this campaign. |
| Webhook URL (DLR) | No | URL to receive delivery status updates. Use a **SMS Campaign Status Updated** trigger webhook URL. |

### Module — Get Balance

Returns the number of SMS credits available on your account.

### Module — List Campaigns

Lists your SMS campaigns with pagination.

| Field | Required | Description |
|---|---|---|
| Page | No | Page number (default: 1) |
| Per Page | No | Results per page (default: 20, max: 100) |

---

## App Structure

```
make-smsenmasse/
├── app.json              # App metadata (name, version, description)
├── base.json             # Base URL and shared headers
├── connections/
│   └── apiKey.json       # API Key authentication connection
├── modules/
│   ├── campaignStatus.json   # Instant trigger (webhook DLR)
│   ├── getBalance.json       # Get Balance module
│   ├── listCampaigns.json    # List Campaigns module
│   └── sendCampaignSms.json  # Send SMS Campaign module
└── CHANGELOG.md
```

---

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

---

## License

MIT — © [Acetelecom / SMS en Masse](https://www.smsenmasse.fr)
