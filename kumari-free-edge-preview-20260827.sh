#!/usr/bin/env bash
set -euo pipefail

REPO="vamsikrishnajallipalli/accessibility-resources"
BRANCH="master"
REMOTE_DIR="listen/kumari-lokesh-preview-20260827/neural"
OUT="$HOME/Downloads/Kumari-Free-Tamil-Neural-Preview"
PAGE="https://raw.githack.com/vamsikrishnajallipalli/accessibility-resources/master/k.html"
VENV="$HOME/Library/Caches/mavrik-kumari-edge-tts-v2"
mkdir -p "$OUT" "$HOME/Library/Caches"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This launcher is intended for macOS."
  exit 2
fi

echo "KUMARI — FREE TAMIL NEURAL AUDITION"
echo "Provider: Microsoft Edge online neural TTS"
echo "Voices: Pallavi + Valluvar | Tamil: ta-IN"
echo "Cost/API key: NONE"
echo "IMPORTANT: this script contains NO Sarvam API call."
echo

if [[ ! -x "$VENV/bin/edge-tts" ]]; then
  echo "Preparing isolated edge-tts runtime..."
  python3 -m venv "$VENV"
  "$VENV/bin/python" -m pip install --quiet --upgrade pip
  "$VENV/bin/python" -m pip install --quiet --upgrade edge-tts
fi

cat > "$OUT/narration.txt" <<'TXT'
தன்னால் அது முடியுமா என யோசித்துப் பார்த்தாள் இருவாஞ்சி. மிகவும் கடினமான, செய்து முடிக்கவே முடியாத உச்சம் என்று உணர்ந்திருந்தாள். ஆனால், வேறு வழியே இல்லை. செம்பனின் ஒற்றைப் பார்வைக்கு முன் உயிர் துச்சமென முடிவெடுத்திருந்தாள். தகதகவென மிளிர்ந்து, கடுகளவில் திரண்டிருக்கும் ஒளிப் புள்ளியை ஆசன வாயின் மேல்புறத்தில் உணர்ந்து மனதை இறுக்கிப் பிணைந்தாள். மனமும் ஒளியும் ஒருசேர தண்டுவடத்தில் தீற்றல்களாக ஒளி குமிழ்ந்து உருண்டு மேல் நோக்கி நகர்ந்தது. முதுவெளித் தாய் கொற்றவையை முன்நிறுத்தி, வழி வேண்டும் என்று அவள் வேண்டி நின்றாள்.
TXT

cat > "$OUT/dialogue.txt" <<'TXT'
இருவாஞ்சி... ம்... என் யாழிக்கு நரம்பு வேண்டும். யாழிக்கு யாளியின் நரம்பு வேண்டுமா? ம். நீயே கொன்று வா. நீ கொண்டு வா. எது வேண்டும்? சிம்மம். நீ ஏன் கவலைப்படுற வாஞ்சி? சிம்மத்தைக் கொல்லக் காட்டில் அனைத்துரிமையும் உண்டு. ஏய்... அது தெரியாதா? நரம்பக் கேட்கிறாயே! உன் எண்ணத்தச் சொல்லு. என் செம்பனுக்காகவும், என் காதலுக்காகவும், என் கனவுக்காகவும் சிம்மத்தைத் தேடிப் போக இருக்கேன். சிம்மம் உயிரோடு நம்மோடு இருக்க வேண்டும். என் மேல நம்பிக்கையில்லையா செம்பா?
TXT

render_voice() {
  local slug="$1" voice="$2" rate="$3"
  echo "Generating ${slug} narration..."
  "$VENV/bin/edge-tts" --voice "$voice" --rate="$rate" --file "$OUT/narration.txt" --write-media "$OUT/${slug}-narration.mp3"
  echo "Generating ${slug} dialogue..."
  "$VENV/bin/edge-tts" --voice "$voice" --rate="$rate" --file "$OUT/dialogue.txt" --write-media "$OUT/${slug}-dialogue.mp3"
}

render_voice "pallavi" "ta-IN-PallaviNeural" "-6%"
render_voice "valluvar" "ta-IN-ValluvarNeural" "-5%"

python3 - "$OUT" <<'PY'
import hashlib, json, pathlib, sys
from datetime import datetime, timezone
out=pathlib.Path(sys.argv[1])
files=["pallavi-narration.mp3","pallavi-dialogue.mp3","valluvar-narration.mp3","valluvar-dialogue.mp3"]
manifest={"generated_at":datetime.now(timezone.utc).isoformat(),"provider":"microsoft-edge-online-tts","cost":"free/no-api-key","language_code":"ta-IN","voices":{"pallavi":"ta-IN-PallaviNeural","valluvar":"ta-IN-ValluvarNeural"},"files":{}}
for name in files:
    p=out/name; b=p.read_bytes()
    if len(b)<1024: raise SystemExit(f"Generated file unexpectedly small: {name}")
    manifest["files"][name]={"bytes":len(b),"sha256":hashlib.sha256(b).hexdigest()}
(out/"status.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf-8")
PY

echo
echo "Playing Pallavi (female) narration..."
afplay "$OUT/pallavi-narration.mp3" || true
echo "Playing Valluvar (male) narration..."
afplay "$OUT/valluvar-narration.mp3" || true

publish_with_gh() {
  command -v gh >/dev/null 2>&1 || return 1
  gh auth status -h github.com >/dev/null 2>&1 || return 1
  python3 - "$OUT" "$REPO" "$BRANCH" "$REMOTE_DIR" <<'PY'
import base64,json,pathlib,subprocess,sys,tempfile
out=pathlib.Path(sys.argv[1]);repo=sys.argv[2];branch=sys.argv[3];remote=sys.argv[4]
for name in ["pallavi-narration.mp3","pallavi-dialogue.mp3","valluvar-narration.mp3","valluvar-dialogue.mp3","status.json"]:
    p=out/name; target=f"{remote}/{name}"
    get=subprocess.run(["gh","api",f"repos/{repo}/contents/{target}?ref={branch}","--jq",".sha"],text=True,capture_output=True)
    payload={"message":f"Publish Kumari free neural Tamil preview: {name}","content":base64.b64encode(p.read_bytes()).decode("ascii"),"branch":branch}
    if get.returncode==0 and get.stdout.strip(): payload["sha"]=get.stdout.strip()
    with tempfile.NamedTemporaryFile("w",encoding="utf-8",delete=False) as f: json.dump(payload,f); tmp=f.name
    put=subprocess.run(["gh","api","--method","PUT",f"repos/{repo}/contents/{target}","--input",tmp],text=True,capture_output=True)
    pathlib.Path(tmp).unlink(missing_ok=True)
    if put.returncode!=0: raise SystemExit(put.stderr or f"GitHub upload failed for {name}")
    print(f"published: {target}")
PY
}

publish_with_git() {
  local tmp repo_dir
  tmp="$(mktemp -d)"; repo_dir="$tmp/repo"
  if ! GIT_TERMINAL_PROMPT=0 git clone --quiet --depth 1 --branch "$BRANCH" "https://github.com/$REPO.git" "$repo_dir"; then rm -rf "$tmp"; return 1; fi
  mkdir -p "$repo_dir/$REMOTE_DIR"
  cp "$OUT/pallavi-narration.mp3" "$OUT/pallavi-dialogue.mp3" "$OUT/valluvar-narration.mp3" "$OUT/valluvar-dialogue.mp3" "$OUT/status.json" "$repo_dir/$REMOTE_DIR/"
  git -C "$repo_dir" config user.name "Mavrik Labs Mac Preview" >/dev/null
  git -C "$repo_dir" config user.email "noreply@mavrik.local" >/dev/null
  git -C "$repo_dir" add "$REMOTE_DIR"
  git -C "$repo_dir" commit -m "Publish Kumari free neural Tamil preview" >/dev/null || true
  if ! GIT_TERMINAL_PROMPT=0 git -C "$repo_dir" push --quiet origin "$BRANCH"; then rm -rf "$tmp"; return 1; fi
  rm -rf "$tmp"
}

PUBLISHED=0
if publish_with_gh; then PUBLISHED=1
elif publish_with_git; then PUBLISHED=1
fi

if [[ "$PUBLISHED" == "1" ]]; then
  echo
  echo "FREE neural preview published successfully."
  echo "$PAGE"
  echo "Pallavi direct audio: https://cdn.jsdelivr.net/gh/$REPO@$BRANCH/$REMOTE_DIR/pallavi-narration.mp3"
  echo "Valluvar direct audio: https://cdn.jsdelivr.net/gh/$REPO@$BRANCH/$REMOTE_DIR/valluvar-narration.mp3"
  open "$PAGE" || true
else
  echo
  echo "Audio generated locally at: $OUT"
  echo "Automatic GitHub publishing could not authenticate; the audio itself is complete."
fi

echo
echo "Done. No paid TTS was used. Full-book synthesis has NOT started; voice quality is the gate."
