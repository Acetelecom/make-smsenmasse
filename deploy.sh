#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# deploy.sh — Push the SMS en Masse Make integration to the Make platform
#
# Usage:
#   ./deploy.sh           → update all sections of an existing app
#   ./deploy.sh --init    → create the app, connection, webhook & modules first
#
# Prerequisites:
#   1. Copy .env.example to .env and fill in MAKE_API_KEY and MAKE_ZONE
#   2. npm install (installs @makehq/cli)
#   3. Run ./deploy.sh --init once to bootstrap the app on Make
#   4. Run ./deploy.sh for every subsequent update
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Load environment ──────────────────────────────────────────────────────────
if [ -f .env ]; then
  set -a; source .env; set +a
fi

: "${MAKE_API_KEY:?MAKE_API_KEY is required — see .env.example}"
: "${MAKE_ZONE:?MAKE_ZONE is required — see .env.example}"

APP_NAME="${MAKE_APP_NAME:-smsenmasse}"
APP_VERSION="${MAKE_APP_VERSION:-1}"
INIT_MODE=false
[[ "${1:-}" == "--init" ]] && INIT_MODE=true

CLI="npx --yes @makehq/cli --api-key=$MAKE_API_KEY --zone=$MAKE_ZONE"

log() { echo "→ $*"; }
ok()  { echo "✓ $*"; }

# ── INIT: create app, connection, webhook, modules ────────────────────────────
if $INIT_MODE; then
  log "Creating app '$APP_NAME'..."
  $CLI sdk-apps create \
    --name="$APP_NAME" \
    --label="SMS en Masse" \
    --description="Send SMS campaigns and manage your SMS en Masse account directly from Make." \
    --theme="#0055FF" \
    --language="en" \
    --audience="global" 2>/dev/null || log "App may already exist — skipping creation."
  ok "App ready."

  log "Creating connection 'apiKey'..."
  $CLI sdk-connections create \
    --app-name="$APP_NAME" \
    --type="basic" \
    --label="API Key" 2>/dev/null || log "Connection may already exist — skipping."
  ok "Connection ready."

  log "Creating webhook 'dlrReceiver'..."
  $CLI sdk-webhooks create \
    --app-name="$APP_NAME" \
    --type="web" \
    --label="DLR Receiver" 2>/dev/null || log "Webhook may already exist — skipping."
  ok "Webhook ready."

  log "Creating modules..."

  $CLI sdk-modules create \
    --app-name="$APP_NAME" \
    --app-version="$APP_VERSION" \
    --name="sendCampaignSms" \
    --type-id=4 \
    --label="Send SMS Campaign" \
    --description="Creates and sends an SMS campaign to one or more recipients via SMS en Masse." \
    2>/dev/null || log "Module sendCampaignSms may already exist — skipping."

  $CLI sdk-modules create \
    --app-name="$APP_NAME" \
    --app-version="$APP_VERSION" \
    --name="getBalance" \
    --type-id=4 \
    --label="Get Balance" \
    --description="Retrieves the number of SMS credits available on your SMS en Masse account." \
    2>/dev/null || log "Module getBalance may already exist — skipping."

  $CLI sdk-modules create \
    --app-name="$APP_NAME" \
    --app-version="$APP_VERSION" \
    --name="listCampaigns" \
    --type-id=9 \
    --label="List Campaigns" \
    --description="Lists SMS campaigns on your SMS en Masse account with optional pagination." \
    2>/dev/null || log "Module listCampaigns may already exist — skipping."

  $CLI sdk-modules create \
    --app-name="$APP_NAME" \
    --app-version="$APP_VERSION" \
    --name="campaignStatus" \
    --type-id=10 \
    --label="SMS Campaign Status Updated" \
    --description="Triggers when a campaign SMS receives a delivery status update (DLR)." \
    2>/dev/null || log "Module campaignStatus may already exist — skipping."

  ok "All modules created."
fi

# ── PUSH: set all sections ────────────────────────────────────────────────────

log "Pushing base section..."
$CLI sdk-apps set-section \
  --name="$APP_NAME" \
  --version="$APP_VERSION" \
  --section=base \
  --body="$(cat base.json)"
ok "base"

log "Pushing connection sections..."
$CLI sdk-connections set-section \
  --connection-name="apiKey" \
  --section=parameters \
  --body="$(cat connections/apiKey/parameters.json)"
ok "connection/apiKey/parameters"

$CLI sdk-connections set-section \
  --connection-name="apiKey" \
  --section=api \
  --body="$(cat connections/apiKey/api.json)"
ok "connection/apiKey/api"

log "Pushing module: sendCampaignSms..."
$CLI sdk-modules set-section \
  --app-name="$APP_NAME" --app-version="$APP_VERSION" \
  --module-name="sendCampaignSms" --section=api \
  --body="$(cat modules/sendCampaignSms/api.json)"
$CLI sdk-modules set-section \
  --app-name="$APP_NAME" --app-version="$APP_VERSION" \
  --module-name="sendCampaignSms" --section=parameters \
  --body="$(cat modules/sendCampaignSms/parameters.json)"
$CLI sdk-modules set-section \
  --app-name="$APP_NAME" --app-version="$APP_VERSION" \
  --module-name="sendCampaignSms" --section=interface \
  --body="$(cat modules/sendCampaignSms/interface.json)"
ok "sendCampaignSms"

log "Pushing module: getBalance..."
$CLI sdk-modules set-section \
  --app-name="$APP_NAME" --app-version="$APP_VERSION" \
  --module-name="getBalance" --section=api \
  --body="$(cat modules/getBalance/api.json)"
$CLI sdk-modules set-section \
  --app-name="$APP_NAME" --app-version="$APP_VERSION" \
  --module-name="getBalance" --section=interface \
  --body="$(cat modules/getBalance/interface.json)"
ok "getBalance"

log "Pushing module: listCampaigns..."
$CLI sdk-modules set-section \
  --app-name="$APP_NAME" --app-version="$APP_VERSION" \
  --module-name="listCampaigns" --section=api \
  --body="$(cat modules/listCampaigns/api.json)"
$CLI sdk-modules set-section \
  --app-name="$APP_NAME" --app-version="$APP_VERSION" \
  --module-name="listCampaigns" --section=parameters \
  --body="$(cat modules/listCampaigns/parameters.json)"
$CLI sdk-modules set-section \
  --app-name="$APP_NAME" --app-version="$APP_VERSION" \
  --module-name="listCampaigns" --section=interface \
  --body="$(cat modules/listCampaigns/interface.json)"
ok "listCampaigns"

log "Pushing module: campaignStatus..."
$CLI sdk-modules set-section \
  --app-name="$APP_NAME" --app-version="$APP_VERSION" \
  --module-name="campaignStatus" --section=interface \
  --body="$(cat modules/campaignStatus/interface.json)"
ok "campaignStatus"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅  Deployment complete — app: $APP_NAME v$APP_VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Next step: open https://www.make.com/en/hq/app-invitation/smsenmasse"
echo "  and click 'Publish' to enable the app review process."
echo ""
