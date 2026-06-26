# Changelog — SMS en Masse Make Integration

## 1.1.0

### Changed
- Project restructured to section-based format compatible with the Make CLI (`@makehq/cli`) and VS Code Make Apps Editor extension
- Each module split into `api.json`, `parameters.json`, `interface.json` sections
- Connection split into `api.json` (validation) and `parameters.json` (input fields)
- Added `makecomapp.json` — VS Code extension project file (origins, components registry)
- Added `deploy.sh` — CLI-based deploy script for CI/CD
- Added `package.json` — npm scripts (`deploy`, `deploy:init`)
- Added `.github/workflows/deploy-make.yml` — GitHub Actions auto-deploy on push to main
- Added `app.json` — full app metadata including `privacyPolicy` and `termsOfService` URLs
- Added `webhooks/dlrReceiver/` — explicit webhook definition for the DLR instant trigger
- Updated `README.md` — complete deployment and publication guide

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
