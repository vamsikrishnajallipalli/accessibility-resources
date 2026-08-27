#!/usr/bin/env bash
set -euo pipefail

OUT="$HOME/Downloads/Kumari-Performance-Audition"
VENV="$HOME/Library/Caches/mavrik-kumari-performance"
mkdir -p "$OUT" "$HOME/Library/Caches"

echo "KUMARI — AUDIOBOOK PERFORMANCE AUDITION"
echo "Engine: AI4Bharat Indic Parler-TTS via official Hugging Face Space"
echo "Goal: beat screen-reader/TalkBack quality with expressive literary narration"
echo "Cost: free public demo/Zero GPU (subject to HF Space availability/rate limits)"
echo

python3 -m venv "$VENV"
"$VENV/bin/python" -m pip install --quiet --upgrade pip
"$VENV/bin/python" -m pip install --quiet --upgrade gradio_client

"$VENV/bin/python" - "$OUT" <<'PY'
from __future__ import annotations
import json, pathlib, shutil, sys
from gradio_client import Client

out = pathlib.Path(sys.argv[1])
client = Client("ai4bharat/indic-parler-tts", verbose=False)

api = None
try:
    info = client.view_api(return_format="dict")
    named = list((info or {}).get("named_endpoints", {}).keys())
    for name in named:
        if "finetuned" in name.lower():
            api = name
            break
except Exception:
    pass
if not api:
    api = "/generate_finetuned"

samples = [
    (
        "jaya-literary-narration",
        """தன்னால் அது முடியுமா என யோசித்துப் பார்த்தாள் இருவாஞ்சி. மிகவும் கடினமான, செய்து முடிக்கவே முடியாத உச்சம் என்று உணர்ந்திருந்தாள். ஆனால், வேறு வழியே இல்லை. செம்பனின் ஒற்றைப் பார்வைக்கு முன் உயிர் துச்சமென முடிவெடுத்திருந்தாள். தகதகவென மிளிர்ந்து, கடுகளவில் திரண்டிருக்கும் ஒளிப் புள்ளியை ஆசன வாயின் மேல்புறத்தில் உணர்ந்து மனதை இறுக்கிப் பிணைந்தாள். மனமும் ஒளியும் ஒருசேர தண்டுவடத்தில் தீற்றல்களாக ஒளி குமிழ்ந்து உருண்டு மேல் நோக்கி நகர்ந்தது. முதுவெளித் தாய் கொற்றவையை முன்நிறுத்தி, வழி வேண்டும் என்று அவள் வேண்டி நின்றாள்.""",
        "Jaya reads a literary Tamil historical-fantasy novel as an experienced audiobook narrator. Her voice is warm, intimate and highly expressive, with a slightly low pitch and a natural moderate pace. She builds suspense and wonder, varies cadence with the meaning of each sentence, uses meaningful pauses, and sounds emotionally present rather than like text-to-speech. The performance is restrained and believable, never melodramatic. Very clear close studio audio with no background noise."
    ),
    (
        "jaya-dialogue-performance",
        """இருவாஞ்சி... ம்... என் யாழிக்கு நரம்பு வேண்டும். யாழிக்கு யாளியின் நரம்பு வேண்டுமா? ம். நீயே கொன்று வா. நீ கொண்டு வா. எது வேண்டும்? சிம்மம். நீ ஏன் கவலைப்படுற வாஞ்சி? சிம்மத்தைக் கொல்லக் காட்டில் அனைத்துரிமையும் உண்டு. ஏய்... அது தெரியாதா? நரம்பக் கேட்கிறாயே! உன் எண்ணத்தச் சொல்லு. என் செம்பனுக்காகவும், என் காதலுக்காகவும், என் கனவுக்காகவும் சிம்மத்தைத் தேடிப் போக இருக்கேன். சிம்மம் உயிரோடு நம்மோடு இருக்க வேண்டும். என் மேல நம்பிக்கையில்லையா செம்பா?""",
        "Jaya performs an intimate, tense dialogue from a Tamil literary audiobook. She remains one narrator but subtly changes rhythm, emphasis and emotional colour between the speakers so the listener can follow the exchange. The delivery is conversational, emotionally alive, suspenseful and restrained, with natural pauses and no robotic cadence. Very clear close studio audio with no background noise."
    ),
    (
        "kavitha-literary-narration",
        """தன்னால் அது முடியுமா என யோசித்துப் பார்த்தாள் இருவாஞ்சி. மிகவும் கடினமான, செய்து முடிக்கவே முடியாத உச்சம் என்று உணர்ந்திருந்தாள். ஆனால், வேறு வழியே இல்லை. செம்பனின் ஒற்றைப் பார்வைக்கு முன் உயிர் துச்சமென முடிவெடுத்திருந்தாள். தகதகவென மிளிர்ந்து, கடுகளவில் திரண்டிருக்கும் ஒளிப் புள்ளியை ஆசன வாயின் மேல்புறத்தில் உணர்ந்து மனதை இறுக்கிப் பிணைந்தாள். மனமும் ஒளியும் ஒருசேர தண்டுவடத்தில் தீற்றல்களாக ஒளி குமிழ்ந்து உருண்டு மேல் நோக்கி நகர்ந்தது. முதுவெளித் தாய் கொற்றவையை முன்நிறுத்தி, வழி வேண்டும் என்று அவள் வேண்டி நின்றாள்.""",
        "Kavitha reads a literary Tamil historical-fantasy novel as a compelling audiobook storyteller. Her voice is warm, mature, intimate and expressive, with a balanced pitch and a measured natural pace. She creates a sense of mystery, danger and wonder, shapes each phrase around its meaning, and uses cinematic but believable pauses. The result should feel like a human narrator telling an absorbing story, not a screen reader. Very clear close studio audio with no background noise."
    )
]

manifest = {"space":"ai4bharat/indic-parler-tts","api":api,"samples":{}}
for slug, text, description in samples:
    print(f"Generating {slug} ...", flush=True)
    result = client.predict(text, description, api_name=api)
    # gradio_client may return a filepath string, FileData-like dict or tuple/list.
    candidate = result
    if isinstance(candidate, (list, tuple)) and candidate:
        candidate = candidate[0]
    if isinstance(candidate, dict):
        candidate = candidate.get("path") or candidate.get("url")
    if hasattr(candidate, "path"):
        candidate = candidate.path
    if not candidate:
        raise SystemExit(f"No audio path returned for {slug}: {result!r}")
    src = pathlib.Path(str(candidate))
    if not src.exists():
        raise SystemExit(f"Returned audio path does not exist for {slug}: {src}")
    dst = out / f"{slug}.mp3"
    shutil.copyfile(src, dst)
    manifest["samples"][slug] = {"text":text,"description":description,"bytes":dst.stat().st_size}
    print(f"saved {dst}")

(out/"manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
PY

echo
for f in "$OUT"/*.mp3; do
  echo "Playing $(basename "$f")"
  afplay "$f" || true
done

echo
echo "Saved in: $OUT"
echo "Judge only one question: does this feel like a real audiobook performance that clearly beats TalkBack?"
echo "If not, reject it; do not bulk-render the book."
