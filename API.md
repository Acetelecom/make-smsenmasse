# SMS en Masse — REST API Documentation

**Base URL:** `https://api.smsenmasse.fr/api/v1`

> **Geographic restriction:** SMS en Masse supports **French phone numbers only** (+33). Recipients must be French mobile numbers in international format.

All requests require an API key passed via the `X-API-KEY` header.

---

## Authentication

Every request must include:

```
X-API-KEY: <your-api-key>
Content-Type: application/json
```

Get your API key: [smsenmasse.fr → Settings → Authentication → apiKeyAuth](https://www.smsenmasse.fr/v1/account-settings)

---

## Endpoints

### Send SMS Campaign

**`POST /sms`**

Creates and sends an SMS campaign to one or more recipients.

**Request body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `recipients` | string | Yes | French phone numbers in international format, comma-separated (e.g. `33645332637,33667656608`). **Only French numbers (+33) are supported as recipients.** |
| `message` | string | Yes | SMS content. Max 160 characters per SMS; longer messages are split automatically. |
| `name` | string | No | Internal campaign name |
| `sender` | string | No | Sender name (3–11 characters, must start with a letter). Defaults to a short number. |
| `sendAt` | string | No | Scheduled send date. Format: `YYYY-MM-DD HH:mm:ss`. Omit for immediate sending. |
| `country` | string | No | ISO 3166-1 alpha-2 country code (default: `FR`) |
| `identifier` | string | No | Custom internal reference |
| `webhookUrl` | string | No | URL to receive delivery status updates (DLR) via POST |

**Example request:**

```json
POST /sms
{
  "recipients": "33645332637,33667656608",
  "message": "Hello! Your order is ready.",
  "sender": "MyBrand",
  "country": "FR",
  "webhookUrl": "https://hook.eu1.make.com/abc123"
}
```

**Response `201 Created`:**

```json
{
  "id": 4821,
  "campagneId": 4821
}
```

**Error codes:**

| Code | Description |
|---|---|
| `400` | Invalid or missing API key |
| `401` | Invalid or missing API key |
| `403` | Forbidden |
| `422` | Invalid SMS parameters or insufficient credits |

---

### Get SMS Credit Balance

**`GET /sms/balance`**

Returns the number of SMS credits available on the account.

**Response `200 OK`:**

```json
{
  "balance": 1250
}
```

---

### List SMS Campaigns

**`GET /sms`**

Returns a paginated list of SMS campaigns.

**Query parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `page` | integer | No | Page number, starting at 1 (default: 1) |
| `limit` | integer | No | Results per page, max 100 (default: 20) |

**Example:**

```
GET /sms?page=1&limit=20
```

**Response `200 OK`:**

```json
[
  {
    "id": 4821,
    "name": "Promo Summer",
    "state": 1,
    "nbTel": 150,
    "nbSms": 150,
    "sendAt": "2026-06-15T10:00:00.000Z",
    "finishedAt": "2026-06-15T10:02:34.000Z",
    "sender": "MyBrand",
    "message": "Summer sale — 20% off!",
    "identifier": "promo-summer-2026"
  }
]
```

**Campaign states:**

| State | Description |
|---|---|
| `-3` | OTP verification |
| `-2` | BAT (test send) |
| `-1` | Draft |
| `0` | Scheduled |
| `1` | Sent |
| `2` | Delivered |
| `3–5` | Failed |
| `6` | Excluded |
| `7` | Filtered |

---

## Delivery Status Webhook (DLR)

When `webhookUrl` is provided in a campaign, SMS en Masse POSTs a delivery update to that URL for each recipient as their message is delivered or fails.

**Payload sent to your webhook URL:**

```json
{
  "event": "dlr",
  "id_message": 4821,
  "statut": 2,
  "numero": "33645332637"
}
```

| Field | Type | Description |
|---|---|---|
| `event` | string | Always `"dlr"` |
| `id_message` | integer | Campaign ID |
| `statut` | integer | Delivery status code (see campaign states above) |
| `numero` | string | Recipient phone number |

---

## Rate limits

- No hard rate limit documented. For high-volume sending, contact support.

---

## Support

- Website: [smsenmasse.fr](https://www.smsenmasse.fr)
- Sign up (20 free SMS): [smsenmasse.fr/v1/public/register](https://www.smsenmasse.fr/v1/public/register/)
- Email: support@smsenmasse.fr
