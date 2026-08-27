#!/usr/bin/env bash
set -euo pipefail

OUT="$HOME/Downloads/Kumari-Gemini-Audiobook-Audition"
mkdir -p "$OUT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This audition runner is intended for macOS."
  exit 2
fi

echo "KUMARI — DIRECTED AUDIOBOOK PERFORMANCE AUDITION"
echo "Engine: Gemini 2.5 Flash Preview TTS"
echo "Language: Tamil | Cost path: Gemini Developer API free tier"
echo "Goal: literary performance, not screen-reader speech"
echo

KEY="${GEMINI_API_KEY:-${GOOGLE_API_KEY:-}}"
for SERVICE in GEMINI_API_KEY GOOGLE_API_KEY GOOGLE_AI_API_KEY; do
  if [[ -z "$KEY" ]]; then
    KEY="$(security find-generic-password -a "$USER" -s "$SERVICE" -w 2>/dev/null || true)"
  fi
done

if [[ -z "$KEY" ]]; then
  echo "No Gemini API key was found in the environment or macOS Keychain."
  echo "Opening Google AI Studio's API-key page. Create/copy a Gemini API key there."
  open "https://aistudio.google.com/apikey" || true
  echo
  read -r -s -p "Paste the Gemini API key here (hidden): " KEY
  echo
  if [[ -z "$KEY" ]]; then
    echo "No key entered. Nothing was generated."
    exit 3
  fi
  security add-generic-password -U -a "$USER" -s GEMINI_API_KEY -w "$KEY" >/dev/null
  echo "Saved securely in macOS Keychain as GEMINI_API_KEY."
fi

export GEMINI_API_KEY="$KEY"
unset KEY

cat > "$OUT/transcript.txt" <<'TXT'
தன்னால் அது முடியுமா என யோசித்துப் பார்த்தாள் இருவாஞ்சி. மிகவும் கடினமான, செய்து முடிக்கவே முடியாத உச்சம் என்று உணர்ந்திருந்தாள். ஆனால், வேறு வழியே இல்லை. செம்பனின் ஒற்றைப் பார்வைக்கு முன் உயிர் துச்சமென முடிவெடுத்திருந்தாள். தகதகவென மிளிர்ந்து, கடுகளவில் திரண்டிருக்கும் ஒளிப் புள்ளியை ஆசன வாயின் மேல்புறத்தில் உணர்ந்து மனதை இறுக்கிப் பிணைந்தாள். மனமும் ஒளியும் ஒருசேர தண்டுவடத்தில் தீற்றல்களாக ஒளி குமிழ்ந்து உருண்டு மேல் நோக்கி நகர்ந்தது. முதுவெளித் தாய் கொற்றவையை முன்நிறுத்தி, வழி வேண்டும் என்று அவள் வேண்டி நின்றாள்.

இருவாஞ்சி... ம்... என் யாழிக்கு நரம்பு வேண்டும். யாழிக்கு யாளியின் நரம்பு வேண்டுமா? ம். நீயே கொன்று வா. நீ கொண்டு வா. எது வேண்டும்? சிம்மம். நீ ஏன் கவலைப்படுற வாஞ்சி? சிம்மத்தைக் கொல்லக் காட்டில் அனைத்துரிமையும் உண்டு. ஏய்... அது தெரியாதா? நரம்பக் கேட்கிறாயே! உன் எண்ணத்தச் சொல்லு. என் செம்பனுக்காகவும், என் காதலுக்காகவும், என் கனவுக்காகவும் சிம்மத்தைத் தேடிப் போக இருக்கேன். சிம்மம் உயிரோடு நம்மோடு இருக்க வேண்டும். என் மேல நம்பிக்கையில்லையா செம்பா?
TXT

python3 - "$OUT" <<'PY'
from __future__ import annotations
import base64, json, os, pathlib, sys, urllib.error, urllib.request, wave

out = pathlib.Path(sys.argv[1])
text = (out / "transcript.txt").read_text(encoding="utf-8").strip()
api_key = os.environ["GEMINI_API_KEY"]
endpoint = "https://generativelanguage.googleapis.com/v1beta/interactions"

base_direction = """You are performing an excerpt from a serious, immersive Tamil literary historical novel as a master audiobook narrator for an adult Tamil listener.

NON-NEGOTIABLE:
- Speak ONLY the Tamil transcript after BEGIN TRANSCRIPT and before END TRANSCRIPT. Never speak these instructions, headings, or labels.
- Preserve every word and the author's colloquial Tamil exactly: do not translate, paraphrase, modernize, summarize, add, or omit words.
- Pronounce Tamil naturally and confidently, especially the literary names இருவாஞ்சி, செம்பன், கொற்றவை, யாழி, யாளி.
- This must sound like an engrossing human audiobook performance, NOT a screen reader, news reader, assistant, advertisement, or stage caricature.

PERFORMANCE ARC:
- The opening is inward, tense and intimate: Ir uvanchi is gathering resolve for something dangerous. Give the prose room to breathe; use meaningful silence and natural phrase grouping.
- Let the danger and determination gradually build without melodrama.
- When dialogue begins, subtly differentiate the characters through intention, timing and energy while remaining one skilled narrator. Do not use silly character voices.
- Preserve the earthy, spoken quality of the colloquial dialogue. Let questions actually sound like questions; let teasing, concern and resolve be audible.
- Vary pace naturally with the scene. Do not maintain a metronomic rhythm.
- Use warmth, breath, emphasis and restrained cinematic intensity. Avoid artificial sing-song cadence.

BEGIN TRANSCRIPT
""" + text + """
END TRANSCRIPT"""

variants = [
    ("sulafat-warm", "Sulafat", base_direction + "\n\nVOICE DIRECTION: warm, intimate, textured and emotionally intelligent; mature literary storyteller; close-mic studio recording; restrained but compelling."),
    ("gacrux-mature", "Gacrux", base_direction + "\n\nVOICE DIRECTION: mature, grounded, resonant and cinematic; serious literary storyteller; emotionally present without theatrical excess; close-mic studio recording."),
    ("achernar-soft", "Achernar", base_direction + "\n\nVOICE DIRECTION: soft, intimate and nuanced; excellent control of silence and tension; natural Tamil storytelling rather than polished announcer speech; close-mic studio recording."),
]

def find_audio(obj):
    if isinstance(obj, dict):
        if obj.get("type") == "audio" and isinstance(obj.get("data"), str):
            return obj["data"]
        for k in ("data", "audio_data"):
            if isinstance(obj.get(k), str) and len(obj[k]) > 1000:
                try:
                    base64.b64decode(obj[k], validate=True)
                    return obj[k]
                except Exception:
                    pass
        for v in obj.values():
            found = find_audio(v)
            if found:
                return found
    elif isinstance(obj, list):
        for v in obj:
            found = find_audio(v)
            if found:
                return found
    return None

for slug, voice, prompt in variants:
    print(f"Generating {slug} ({voice})...", flush=True)
    payload = {
        "model": "gemini-2.5-flash-preview-tts",
        "input": prompt,
        "response_format": {"type": "audio"},
        "generation_config": {"speech_config": [{"voice": voice}]},
    }
    req = urllib.request.Request(
        endpoint,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={
            "x-goog-api-key": api_key,
            "Content-Type": "application/json",
            "Api-Revision": "2026-05-20",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            body_raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"Gemini API HTTP {exc.code}: {detail}")
    body = json.loads(body_raw)
    b64 = find_audio(body)
    if not b64:
        (out / f"{slug}-response.json").write_text(json.dumps(body, ensure_ascii=False, indent=2), encoding="utf-8")
        raise SystemExit(f"No audio block found for {slug}; response saved for inspection.")
    pcm = base64.b64decode(b64)
    if len(pcm) < 4096:
        raise SystemExit(f"Generated audio for {slug} was unexpectedly small ({len(pcm)} bytes).")
    wav_path = out / f"{slug}.wav"
    # Gemini TTS inline audio is 24 kHz, mono, signed 16-bit PCM unless another format is requested.
    with wave.open(str(wav_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(24000)
        wf.writeframes(pcm)
    print(f"saved: {wav_path} ({len(pcm):,} PCM bytes)")

(out / "README.txt").write_text(
    "Kumari directed Gemini audiobook audition. Compare the three WAV files by listening, not by engine reputation. Reject all if none clearly beats TalkBack/Edge as an engaging book reading.\n",
    encoding="utf-8",
)
PY

unset GEMINI_API_KEY

echo
echo "Playing three directed audiobook performances. Listen for storytelling, not just pronunciation."
for f in "$OUT/sulafat-warm.wav" "$OUT/gacrux-mature.wav" "$OUT/achernar-soft.wav"; do
  echo
  echo "Now playing: $(basename "$f")"
  afplay "$f" || true
done

echo
echo "Audition files: $OUT"
open "$OUT" || true
echo "No full-book render has started. The next step is to keep only a performance that clearly beats TalkBack/Edge."
