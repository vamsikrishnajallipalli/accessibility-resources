#!/usr/bin/env bash
set -euo pipefail

OUT="$HOME/Downloads/Kumari-Gemini-Performance-v3"
mkdir -p "$OUT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This audition runner is intended for macOS."
  exit 2
fi

echo "KUMARI — PERFORMANCE-FOCUSED AUDIOBOOK AUDITION v3"
echo "Engine: Gemini 3.1 Flash TTS Preview"
echo "Purpose: improve the acting/performance itself, not merely swap voices"
echo "Outputs: same-voice neutral vs directed A/B + one contrasting directed take"
echo "Delivery: mastered MP3 for WhatsApp; WAV retained only as internal master"
echo

KEY="${GEMINI_API_KEY:-${GOOGLE_API_KEY:-}}"
for SERVICE in GEMINI_API_KEY GOOGLE_API_KEY GOOGLE_AI_API_KEY; do
  if [[ -z "$KEY" ]]; then
    KEY="$(security find-generic-password -a "$USER" -s "$SERVICE" -w 2>/dev/null || true)"
  fi
done
if [[ -z "$KEY" ]]; then
  echo "No Gemini API key found in environment or macOS Keychain."
  open "https://aistudio.google.com/apikey" || true
  read -r -s -p "Paste Gemini API key here (hidden): " KEY
  echo
  if [[ -z "$KEY" ]]; then
    echo "No key entered. Nothing generated."
    exit 3
  fi
  security add-generic-password -U -a "$USER" -s GEMINI_API_KEY -w "$KEY" >/dev/null
fi
export GEMINI_API_KEY="$KEY"
unset KEY

cat > "$OUT/source.txt" <<'TXT'
தன்னால் அது முடியுமா என யோசித்துப் பார்த்தாள் இருவாஞ்சி. மிகவும் கடினமான, செய்து முடிக்கவே முடியாத உச்சம் என்று உணர்ந்திருந்தாள். ஆனால், வேறு வழியே இல்லை. செம்பனின் ஒற்றைப் பார்வைக்கு முன் உயிர் துச்சமென முடிவெடுத்திருந்தாள். தகதகவென மிளிர்ந்து, கடுகளவில் திரண்டிருக்கும் ஒளிப் புள்ளியை ஆசன வாயின் மேல்புறத்தில் உணர்ந்து மனதை இறுக்கிப் பிணைந்தாள். மனமும் ஒளியும் ஒருசேர தண்டுவடத்தில் தீற்றல்களாக ஒளி குமிழ்ந்து உருண்டு மேல் நோக்கி நகர்ந்தது. முதுவெளித் தாய் கொற்றவையை முன்நிறுத்தி, வழி வேண்டும் என்று அவள் வேண்டி நின்றாள்.

இருவாஞ்சி... ம்... என் யாழிக்கு நரம்பு வேண்டும். யாழிக்கு யாளியின் நரம்பு வேண்டுமா? ம். நீயே கொன்று வா. நீ கொண்டு வா. எது வேண்டும்? சிம்மம். நீ ஏன் கவலைப்படுற வாஞ்சி? சிம்மத்தைக் கொல்லக் காட்டில் அனைத்துரிமையும் உண்டு. ஏய்... அது தெரியாதா? நரம்பக் கேட்கிறாயே! உன் எண்ணத்தச் சொல்லு. என் செம்பனுக்காகவும், என் காதலுக்காகவும், என் கனவுக்காகவும் சிம்மத்தைத் தேடிப் போக இருக்கேன். சிம்மம் உயிரோடு நம்மோடு இருக்க வேண்டும். என் மேல நம்பிக்கையில்லையா செம்பா?
TXT

python3 - "$OUT" <<'PY'
from __future__ import annotations
import base64, json, os, pathlib, subprocess, sys, urllib.error, urllib.request, wave

out = pathlib.Path(sys.argv[1])
source = (out / "source.txt").read_text(encoding="utf-8").strip()
api_key = os.environ["GEMINI_API_KEY"]
endpoint = "https://generativelanguage.googleapis.com/v1beta/interactions"

neutral_prompt = f"""Read the following Tamil literary passage exactly as written. Do not add, omit, translate or paraphrase words. Use natural Tamil pronunciation and a calm audiobook delivery. Speak only the passage.\n\n{source}"""

directed_prompt = f"""You are not a text-to-speech announcer. You are a master Tamil audiobook performer recording a serious historical-literary novel for an adult listener with headphones.

AUDIO PROFILE
- Intimate, emotionally intelligent literary storyteller.
- Close-mic studio presence: the listener should feel the narrator is telling the story to one person, not addressing an audience.
- Natural Tamil speech rhythm; never use assistant/newsreader/screen-reader cadence.
- Avoid sing-song intonation and repeated sentence-final melody.

SCENE
Ir uvanchi is inwardly testing whether she can do something frightening and difficult. She is not hysterical. She is gathering resolve. The prose then moves through bodily concentration and a spiritual invocation. After that the energy shifts into earthy spoken dialogue: teasing, questioning, concern, determination and affection.

DIRECTOR'S NOTES
- Opening thought: inward, tentative, slightly hushed. Let the doubt live for a moment.
- As 'வேறு வழியே இல்லை' arrives, allow a small pause and a firmer center of gravity: she has decided.
- The bodily/concentration imagery should become focused and immersive, not hurried. Group phrases by meaning rather than punctuation alone.
- The invocation of கொற்றவை should carry restrained reverence, not devotional melodrama.
- Before the dialogue, reset the energy. The dialogue must sound like people actually speaking to one another.
- Questions must genuinely seek an answer; short replies should be crisp and alive.
- 'ஏய்...' carries familiarity and a touch of teasing impatience, not anger.
- The final declaration about செம்பன், காதல் and கனவு should build through the three phrases with conviction, then soften slightly into the final question.
- Vary timing sentence by sentence. Use silence as part of the performance.
- Do not overact. No stage-drama caricature.

INLINE PERFORMANCE CUES
Use the following cues as acting instructions; NEVER speak the bracketed English words themselves:
[quietly, inwardly] at the first sentence.
[short reflective pause] after the first sentence.
[with restrained tension] through the difficulty and impossibility.
[firmer, resolved] on the turn beginning 'ஆனால், வேறு வழியே இல்லை.'
[focused, immersive, slightly slower] through the bodily concentration imagery.
[reverent but restrained] on the invocation of கொற்றவை.
[reset; conversational, earthy] when dialogue begins.
[curious] on genuine questions.
[firm, brief] on short decisions/answers.
[mischievously, familiar] around 'ஏய்... அது தெரியாதா?'
[building conviction] through 'என் செம்பனுக்காகவும், என் காதலுக்காகவும், என் கனவுக்காகவும்'.
[soft but direct] on the final question.

NON-NEGOTIABLE TEXT FIDELITY
Speak ONLY the exact Tamil passage below. Do not speak these instructions. Do not translate, modernize, summarize, add or omit any source word. Pronounce names including இருவாஞ்சி, செம்பன், கொற்றவை, யாழி and யாளி naturally.

BEGIN EXACT PASSAGE
{source}
END EXACT PASSAGE"""

variants = [
    ("01-sulafat-neutral", "Sulafat", neutral_prompt),
    ("02-sulafat-directed", "Sulafat", directed_prompt),
    ("03-charon-directed", "Charon", directed_prompt.replace("Intimate, emotionally intelligent literary storyteller.", "Mature, grounded, emotionally intelligent literary storyteller with a lower, steadier center.")),
]

def find_audio(obj):
    if isinstance(obj, dict):
        if obj.get("type") == "audio" and isinstance(obj.get("data"), str):
            return obj["data"]
        for k in ("data", "audio_data"):
            v = obj.get(k)
            if isinstance(v, str) and len(v) > 1000:
                try:
                    base64.b64decode(v, validate=True)
                    return v
                except Exception:
                    pass
        for v in obj.values():
            f = find_audio(v)
            if f: return f
    elif isinstance(obj, list):
        for v in obj:
            f = find_audio(v)
            if f: return f
    return None

for slug, voice, prompt in variants:
    print(f"Generating {slug} with {voice}...", flush=True)
    payload = {
        "model": "gemini-3.1-flash-tts-preview",
        "input": prompt,
        "response_format": {"type": "audio"},
        "generation_config": {"speech_config": [{"voice": voice}]},
    }
    req = urllib.request.Request(
        endpoint,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"x-goog-api-key": api_key, "Content-Type": "application/json", "Api-Revision": "2026-05-20"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            body = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"Gemini API HTTP {exc.code}: {detail}")
    b64 = find_audio(body)
    if not b64:
        (out / f"{slug}-response.json").write_text(json.dumps(body, ensure_ascii=False, indent=2), encoding="utf-8")
        raise SystemExit(f"No audio block found for {slug}; response saved for inspection.")
    pcm = base64.b64decode(b64)
    wav_path = out / f"{slug}.wav"
    with wave.open(str(wav_path), "wb") as wf:
        wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(24000); wf.writeframes(pcm)

    mp3_path = out / f"{slug}.mp3"
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav_path),
           "-af", "loudnorm=I=-16:TP=-1.5:LRA=11", "-codec:a", "libmp3lame", "-b:a", "128k", str(mp3_path)]
    subprocess.run(cmd, check=True)
    if mp3_path.stat().st_size < 4096:
        raise SystemExit(f"MP3 unexpectedly small: {mp3_path.name}")
    print(f"saved WhatsApp-ready: {mp3_path}")

(out / "README.txt").write_text(
    "A/B TEST:\n"
    "01 and 02 use the SAME voice (Sulafat). The only meaningful change is performance direction + Gemini 3.1 TTS. "
    "If 02 is not clearly more engaging than 01, the direction layer has failed. "
    "03 tests a contrasting timbre using the same directed performance prompt. WAVs are internal masters; MP3s are sharing/listening files.\n",
    encoding="utf-8",
)
PY

unset GEMINI_API_KEY

echo
echo "A/B PERFORMANCE TEST — SAME VOICE FIRST"
echo "1) Neutral Sulafat"
afplay "$OUT/01-sulafat-neutral.mp3" || true
echo
echo "2) Directed Sulafat — SAME VOICE, performance should be materially better"
afplay "$OUT/02-sulafat-directed.mp3" || true
echo
echo "3) Directed Charon — timbre comparison only after the performance A/B"
afplay "$OUT/03-charon-directed.mp3" || true

echo
echo "WhatsApp-ready MP3s are in: $OUT"
open "$OUT" || true
echo "Judge 01 vs 02 first. That isolates performance improvement from voice swapping."
