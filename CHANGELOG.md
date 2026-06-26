# Changelog — SMS en Masse Make Integration

## 1.0.5

### Make review compliance fixes
- **Connection**: rename label to "SMS en Masse" (matches app name)
- **Connection**: add `X-API-KEY` header explicitly in validation request (parameter was not used)
- **Connection**: add `"editable": true` on `apiKey` parameter
- **Connection**: add optional `accountLabel` parameter + metadata for connection identification
- **Connection**: add log sanitization for `X-API-KEY` header
- **Connection**: improve error format to `[statusCode] message`
- **Modules**: set `"public": true` on all 4 modules (Get Balance, List Campaigns, Send SMS Campaign, SMS Campaign Status Updated)
- **Modules**: standardize error format to `[{{statusCode}}] {{body.message}}` across all modules
- **Universal module**: add "Make an API Call" module for custom endpoint access
- **Webhook**: add `detach` RPC on DLR Receiver

## 1.0.4

### Fixed
- `sendCampaignSms`: champs optionnels utilisent désormais `{{if(param; param; omit)}}` — les champs vides ne sont plus envoyés à l'API
- `sendCampaignSms`: type de `sendAt` corrigé de `date` (ISO 8601) à `text`
- `campaignStatus`: suppression de la propriété `statut_labels` invalide

## 1.0.3

Initial release adapted from the Zapier integration v1.0.3.

### Features
- **Module**: Send SMS Campaign — creates and sends an SMS campaign to one or more recipients
- **Module**: Get Balance — retrieves available SMS credits on the account
- **Module**: List Campaigns — lists SMS campaigns with pagination
- **Trigger**: SMS Campaign Status Updated — instant trigger (webhook) for DLR delivery updates
- API Key authentication via `X-API-KEY` header
