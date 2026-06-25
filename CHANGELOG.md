# Changelog — SMS en Masse Make Integration

## 1.0.4

### Fixed
- `sendCampaignSms`: champs optionnels (`name`, `sender`, `sendAt`, `country`, `identifier`, `webhookUrl`) utilisent désormais `{{if(param; param; omit)}}` — les champs vides ne sont plus envoyés à l'API (évite les rejets liés aux valeurs nulles)
- `sendCampaignSms`: type de `sendAt` corrigé de `date` (ISO 8601) à `text` pour correspondre au format attendu par l'API (`YYYY-MM-DD HH:mm:ss`)
- `campaignStatus`: suppression de la propriété `statut_labels` qui n'est pas un champ valide du schéma Make

## 1.0.3

Initial release adapted from the Zapier integration v1.0.3.

### Features
- **Module**: Send SMS Campaign — creates and sends an SMS campaign to one or more recipients
- **Module**: Get Balance — retrieves available SMS credits on the account
- **Module**: List Campaigns — lists SMS campaigns with pagination
- **Trigger**: SMS Campaign Status Updated — instant trigger (webhook) for DLR delivery updates
- API Key authentication via `X-API-KEY` header
