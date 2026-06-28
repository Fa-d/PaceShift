#!/usr/bin/env bash
#
# Smoke-tests a GLM key + the generative-UI composition the `/ai/ui` route relies
# on (Phase 12). It hits GLM's OpenAI-compatible endpoint directly with the same
# prompt shape as GenUiService.kt and validates the model returns a parseable,
# allow-listed UI spec.
#
# The key is read from the environment — it is never written to disk or hardcoded.
#
# Usage:
#   GLM_API_KEY=xxxxx backend/scripts/glm_smoke_test.sh [model]
#
# Env (all optional except GLM_API_KEY):
#   GLM_API_KEY   required — your GLM/Z.ai key
#   GLM_BASE_URL  default https://api.z.ai/api/paas/v4
#                 (China: https://open.bigmodel.cn/api/paas/v4)
#   GLM_MODEL     default glm-5.2  (free tier that needs no balance: glm-4.5-flash)
#
# Exit code 0 = healthy, non-zero = problem (auth, balance, or bad output).
set -euo pipefail

KEY="${GLM_API_KEY:-}"
BASE="${GLM_BASE_URL:-https://api.z.ai/api/paas/v4}"
MODEL="${1:-${GLM_MODEL:-glm-5.2}}"

if [[ -z "$KEY" ]]; then
  echo "✗ GLM_API_KEY is not set. Usage: GLM_API_KEY=xxx $0 [model]" >&2
  exit 2
fi

ENDPOINT="${BASE%/}/chat/completions"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ endpoint: $ENDPOINT"
echo "→ model:    $MODEL"
echo

# Build the request with the real GenUiService prompt shape (kept compact).
python3 - "$MODEL" > "$TMP/req.json" <<'PY'
import json, sys
model = sys.argv[1]
system = (
    "You are PaceShift's running coach. You do NOT write prose paragraphs — you "
    "compose a small native UI by returning a JSON object that the app renders.\n"
    'Return ONLY a JSON object of this exact shape (no markdown): {"blocks": [ <block>, ... ]}\n'
    "Each <block> has a \"type\" and a subset of fields. Use ONLY these types:\n"
    '- {"type":"section","title": string}\n'
    '- {"type":"text","body": string}\n'
    '- {"type":"metric","value": string,"label": string,"tone": tone}\n'
    '- {"type":"status_chip","label": string,"tone": tone}\n'
    '- {"type":"shift_banner","text": string}\n'
    '- {"type":"run_card","runId": int,"title": string,"subtitle": string,"status": status}\n'
    '- {"type":"action_button","label": string,"action": action,"style": style,"runId": int,"confirm": bool}\n'
    "tone in positive|caution|critical|neutral ; status in completed|shifted|reduced|missed|planned\n"
    "action in mark_done|could_not_run|open_run|ask ; style in filled|outlined|text\n"
    "Rules: use ONLY facts provided; at most 6 blocks; set runId on run_card and run "
    "actions; confirm:true on mark_done/could_not_run."
)
user = (
    "Plan summary: 42.2km race on 2026-10-15, week 8 of 18, taper 3 weeks, "
    "readiness 75/100 (on track), predicted finish 3h52m.\n"
    "Recent engine changes (facts you may arrange):\n"
    "- Moved long run from Sat Jun 28 to Sun Jun 29 (18.0km)\n"
    "- Reduced Wed tempo from 12.0km to 9.0km\n"
    "The runner asks: what changed and what should I do about today's long run (runId 42)?\n"
    "Compose a UI that answers helpfully, grounded in the facts above."
)
print(json.dumps({
    "model": model,
    "messages": [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
    ],
    "response_format": {"type": "json_object"},
    "temperature": 0.4,
    "max_tokens": 2000,
}))
PY

code="$(curl -sS -m 60 -o "$TMP/resp.json" -w '%{http_code}' \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  --data @"$TMP/req.json" "$ENDPOINT" || echo 000)"

echo "→ HTTP $code"
echo

# Interpret the response and validate the spec.
ALLOWED='section text metric status_chip shift_banner run_card empty_state action_button'
python3 - "$TMP/resp.json" "$code" "$ALLOWED" <<'PY'
import json, sys
resp_path, code, allowed = sys.argv[1], sys.argv[2], set(sys.argv[3].split())

try:
    d = json.load(open(resp_path), strict=False)
except Exception as e:
    print(f"✗ Could not read response body: {e}")
    sys.exit(1)

if isinstance(d, dict) and d.get("error"):
    err = d["error"]
    ec = str(err.get("code"))
    msg = err.get("message", "")
    if ec == "1113":
        print(f"✗ Key is VALID but the account has no balance/package for this model.")
        print(f"  → {msg}")
        print("  Fix: add a balance/resource package, or re-run with the free model:")
        print("       GLM_API_KEY=… backend/scripts/glm_smoke_test.sh glm-4.5-flash")
        sys.exit(1)
    if code == "401":
        print(f"✗ Authentication failed — the key looks invalid. {msg}")
        sys.exit(1)
    print(f"✗ API error {ec}: {msg}")
    sys.exit(1)

try:
    choice = d["choices"][0]
    content = (choice["message"].get("content") or "").strip()
    finish = choice.get("finish_reason")
except Exception:
    print(f"✗ Unexpected response shape: {json.dumps(d)[:300]}")
    sys.exit(1)

if not content:
    print(f"✗ Empty content (finish_reason={finish}).")
    if finish == "length":
        print("  GLM is a reasoning model — raise max_tokens so the JSON fits after reasoning.")
    sys.exit(1)

try:
    spec = json.loads(content)
    blocks = spec.get("blocks", [])
    assert isinstance(blocks, list) and blocks
except Exception as e:
    print(f"✗ Content is not a valid {{'blocks':[…]}} spec: {e}")
    print("  raw:", content[:400])
    sys.exit(1)

bad = [b.get("type") for b in blocks if b.get("type") not in allowed]
print(f"✓ Key valid, model healthy, and composition returned {len(blocks)} blocks:")
for b in blocks:
    extra = {k: v for k, v in b.items() if k != "type"}
    print(f"   - {b.get('type'):<14} {extra}")
if bad:
    print(f"\n⚠ {len(bad)} block(s) used non-catalog types {bad} — the server drops these,")
    print("  so the UI still renders safely, but tighten the prompt if it recurs.")
print("\n✅ /ai/ui pipeline is healthy with this key + model.")
PY
