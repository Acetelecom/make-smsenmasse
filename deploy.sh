#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# deploy.sh — Push the SMS en Masse Make integration to the Make platform
#
# Usage:
#   ./deploy.sh           → update all sections of an existing app
#   ./deploy.sh --init    → create the app, connection, webhook & modules first
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

CLI="npx --yes @makehq/cli --api-key=$MAKE_API_KEY --zone=$MAKE_ZONE --output=json"

log() { echo "→ $*"; }
ok()  { echo "✓ $*"; }

# Parse a field from JSON output (requires node, always available in CI)
jq_get() { echo "$1" | node -e "process.stdin.resume();let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const o=JSON.parse(d);process.stdout.write(String(o.$2??''))}catch(e){process.stdout.write('')}})"; }

# ── INIT: create app, connection, webhook, modules ────────────────────────────
if $INIT_MODE; then

  # ── App ───────────────────────────────────────────────────────────────────
  log "Creating app '$APP_NAME'..."
  APP_RESULT=$($CLI sdk-apps create \
    --name="$APP_NAME" \
    --label="SMS en Masse" \
    --description="Send SMS campaigns and manage your SMS en Masse account directly from Make." \
    --theme="#0055FF" \
    --language="en" \
    --audience="global" 2>&1) || {
    log "Create failed — checking if app already exists..."
    APP_RESULT=$($CLI sdk-apps get --name="$APP_NAME" --version="$APP_VERSION" 2>&1) || {
      echo "ERROR: Could not create or find app '$APP_NAME'. Raw output:"
      echo "$APP_RESULT"
      exit 1
    }
  }
  # Extract actual name/version returned by Make
  ACTUAL_NAME=$(echo "$APP_RESULT" | node -e "
    process.stdin.resume(); let d='';
    process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
      try { const o=JSON.parse(d); process.stdout.write(o.name||o.appId||''); }
      catch(e){ process.stdout.write(''); }
    })" <<< "$APP_RESULT")
  ACTUAL_VERSION=$(echo "$APP_RESULT" | node -e "
    process.stdin.resume(); let d='';
    process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
      try { const o=JSON.parse(d); process.stdout.write(String(o.version??'')); }
      catch(e){ process.stdout.write(''); }
    })" <<< "$APP_RESULT")

  if [ -n "$ACTUAL_NAME" ]; then
    APP_NAME="$ACTUAL_NAME"
    log "App name confirmed by API: $APP_NAME"
  fi
  if [ -n "$ACTUAL_VERSION" ]; then
    APP_VERSION="$ACTUAL_VERSION"
    log "App version confirmed by API: $APP_VERSION"
  fi
  ok "App: $APP_NAME v$APP_VERSION"

  # ── Connection ────────────────────────────────────────────────────────────
  log "Creating connection..."
  CONN_RESULT=$($CLI sdk-connections create \
    --app-name="$APP_NAME" \
    --type="basic" \
    --label="API Key" 2>&1) || {
    log "Connection create failed or already exists — listing to find name..."
    CONN_RESULT=$($CLI sdk-connections list --app-name="$APP_NAME" 2>&1)
  }
  CONN_NAME=$(echo "$CONN_RESULT" | node -e "
    process.stdin.resume(); let d='';
    process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
      try {
        const o=JSON.parse(d);
        const arr=Array.isArray(o)?o:[o];
        process.stdout.write(arr[0]?.name||arr[0]?.connectionId||'');
      } catch(e){ process.stdout.write(''); }
    })" <<< "$CONN_RESULT")
  if [ -z "$CONN_NAME" ]; then
    echo "ERROR: Could not determine connection name. Raw output:"
    echo "$CONN_RESULT"
    exit 1
  fi
  ok "Connection: $CONN_NAME"

  # ── Webhook ───────────────────────────────────────────────────────────────
  log "Creating webhook..."
  HOOK_RESULT=$($CLI sdk-webhooks create \
    --app-name="$APP_NAME" \
    --type="web" \
    --label="DLR Receiver" 2>&1) || {
    log "Webhook create failed or already exists — listing to find name..."
    HOOK_RESULT=$($CLI sdk-webhooks list --app-name="$APP_NAME" 2>&1)
  }
  HOOK_NAME=$(echo "$HOOK_RESULT" | node -e "
    process.stdin.resume(); let d='';
    process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
      try {
        const o=JSON.parse(d);
        const arr=Array.isArray(o)?o:[o];
        process.stdout.write(arr[0]?.name||arr[0]?.webhookId||'');
      } catch(e){ process.stdout.write(''); }
    })" <<< "$HOOK_RESULT")
  ok "Webhook: ${HOOK_NAME:-created}"

  # ── Modules ───────────────────────────────────────────────────────────────
  log "Creating modules..."

  create_module() {
    local name=$1 typeid=$2 label=$3 desc=$4
    $CLI sdk-modules create \
      --app-name="$APP_NAME" \
      --app-version="$APP_VERSION" \
      --name="$name" \
      --type-id="$typeid" \
      --label="$label" \
      --description="$desc" 2>&1 || log "Module $name: create failed or already exists — continuing."
    ok "Module: $name"
  }

  create_module "sendCampaignSms" 4 "Send SMS Campaign" \
    "Creates and sends an SMS campaign to one or more recipients via SMS en Masse."

  create_module "getBalance" 4 "Get Balance" \
    "Retrieves the number of SMS credits available on your SMS en Masse account."

  create_module "listCampaigns" 9 "List Campaigns" \
    "Lists SMS campaigns on your SMS en Masse account with optional pagination."

  create_module "campaignStatus" 10 "SMS Campaign Status Updated" \
    "Triggers when a campaign SMS receives a delivery status update (DLR)."

  ok "All resources initialised — APP_NAME=$APP_NAME  APP_VERSION=$APP_VERSION  CONN_NAME=$CONN_NAME"

  # Save resolved names for the push phase below
  export APP_NAME APP_VERSION CONN_NAME
fi

# ── If not init, resolve real app name + connection name from Make ────────────
if ! $INIT_MODE; then
  # Find the app by label "SMS en Masse" (resilient if Make appended a suffix to the name)
  ALL_APPS=$($CLI sdk-apps list 2>&1)
  RESOLVED=$(echo "$ALL_APPS" | node -e "
    process.stdin.resume(); let d='';
    process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
      try {
        const arr=JSON.parse(d);
        const app=arr.find(a=>a.label==='SMS en Masse');
        process.stdout.write(JSON.stringify(app||null));
      } catch(e){ process.stdout.write('null'); }
    })" <<< "$ALL_APPS")
  if [ "$RESOLVED" = "null" ] || [ -z "$RESOLVED" ]; then
    echo "ERROR: App 'SMS en Masse' not found on Make. Run with --init first."
    exit 1
  fi
  APP_NAME=$(echo "$RESOLVED" | node -e "process.stdin.resume();let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const o=JSON.parse(d);process.stdout.write(o.name||'')})" <<< "$RESOLVED")
  APP_VERSION=$(echo "$RESOLVED" | node -e "process.stdin.resume();let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const o=JSON.parse(d);process.stdout.write(String(o.version??1))})" <<< "$RESOLVED")
  log "App resolved by label: $APP_NAME v$APP_VERSION"

  CONN_RESULT=$($CLI sdk-connections list --app-name="$APP_NAME" 2>&1)
  CONN_NAME=$(echo "$CONN_RESULT" | node -e "
    process.stdin.resume(); let d='';
    process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
      try {
        const o=JSON.parse(d);
        const arr=Array.isArray(o)?o:[o];
        process.stdout.write(arr[0]?.name||arr[0]?.connectionId||'');
      } catch(e){ process.stdout.write(''); }
    })" <<< "$CONN_RESULT")
  if [ -z "$CONN_NAME" ]; then
    echo "ERROR: No connection found for app '$APP_NAME'."
    exit 1
  fi
  log "Connection resolved: $CONN_NAME"
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
  --connection-name="$CONN_NAME" \
  --section=parameters \
  --body="$(cat connections/apiKey/parameters.json)"
ok "connection/parameters"

$CLI sdk-connections set-section \
  --connection-name="$CONN_NAME" \
  --section=api \
  --body="$(cat connections/apiKey/api.json)"
ok "connection/api"

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

log "Uploading app icon (512×512)..."
ICON_B64=$(base64 < logo-512.png | tr -d '\n')
$CLI sdk-apps set-icon \
  --name="$APP_NAME" \
  --version="$APP_VERSION" \
  --data-base64="$ICON_B64"
ok "icon uploaded"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅  Deployment complete"
echo "      app: $APP_NAME  version: $APP_VERSION  conn: $CONN_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
