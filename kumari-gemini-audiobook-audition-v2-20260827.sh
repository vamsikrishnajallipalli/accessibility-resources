#!/usr/bin/env bash
set -euo pipefail

OUT="$HOME/Downloads/Kumari-Gemini-Audiobook-Audition-v2"
mkdir -p "$OUT"

KEY="${GEMINI_API_KEY:-${GOOGLE_API_KEY:-}}"
for SERVICE in GEMINI_API_KEY GOOGLE_API_KEY GOOGLE_AI_API_KEY; do
  if [[ -z "$KEY" ]]; then KEY="$(security find-generic-password -a "$USER" -s "$SERVICE" -w 2>/dev/null || true)"; fi
done
if [[ -z "$KEY" ]]; then
  echo "No Gemini API key found in environment/Keychain."
  exit 3
fi
export GEMINI_API_KEY="$KEY"; unset KEY

cat > "$OUT/transcript.txt" <<'TXT'
தன்னால் அது முடியுமா என யோசித்துப் பார்த்தாள் இருவாஞ்சி. மிகவும் கடினமான, செய்து முடிக்கவே முடியாத உச்சம் என்று உணர்ந்திருந்தாள். ஆனால், வேறு வழியே இல்லை. செம்பனின் ஒற்றைப் பார்வைக்கு முன் உயிர் துச்சமென முடிவெடுத்திருந்தாள். தகதகவென மிளிர்ந்து, கடுகளவில் திரண்டிருக்கும் ஒளிப் புள்ளியை ஆசன வாயின் மேல்புறத்தில் உணர்ந்து மனதை இறுக்கிப் பிணைந்தாள். மனமும் ஒளியும் ஒருசேர தண்டுவடத்தில் தீற்றல்களாக ஒளி குமிழ்ந்து உருண்டு மேல் நோக்கி நகர்ந்தது. முதுவெளித் தாய் கொற்றவையை முன்நிறுத்தி, வழி வேண்டும் என்று அவள் வேண்டி நின்றாள்.

இருவாஞ்சி... ம்... என் யாழிக்கு நரம்பு வேண்டும். யாழிக்கு யாளியின் நரம்பு வேண்டுமா? ம். நீயே கொன்று வா. நீ கொண்டு வா. எது வேண்டும்? சிம்மம். நீ ஏன் கவலைப்படுற வாஞ்சி? சிம்மத்தைக் கொல்லக் காட்டில் அனைத்துரிமையும் உண்டு. ஏய்... அது தெரியாதா? நரம்பக் கேட்கிறாயே! உன் எண்ணத்தச் சொல்லு. என் செம்பனுக்காகவும், என் காதலுக்காகவும், என் கனவுக்காகவும் சிம்மத்தைத் தேடிப் போக இருக்கேன். சிம்மம் உயிரோடு நம்மோடு இருக்க வேண்டும். என் மேல நம்பிக்கையில்லையா செம்பா?
TXT

python3 - "$OUT" <<'PY'
from __future__ import annotations
import base64,json,os,pathlib,sys,urllib.request,urllib.error,wave
out=pathlib.Path(sys.argv[1]); text=(out/'transcript.txt').read_text(encoding='utf-8').strip(); key=os.environ['GEMINI_API_KEY']
endpoint='https://generativelanguage.googleapis.com/v1beta/interactions'
base='''Perform this Tamil historical-literary novel excerpt as a compelling adult audiobook. Speak ONLY the Tamil transcript. Preserve every word exactly. Avoid screen-reader, assistant, announcer and sing-song cadence. Use scene-aware pacing, silence, breath, tension and restrained cinematic intensity. Dialogue must sound conversational and intentional, with subtle character differentiation but no caricature. Questions must sound like questions. Names must be pronounced naturally: இருவாஞ்சி, செம்பன், கொற்றவை, யாழி, யாளி.\n\nBEGIN TRANSCRIPT\n'''+text+'\nEND TRANSCRIPT'
# Broader timbre audition. Google documents style labels, not voice gender; these are selected to explore lower/grounded as well as warm/soft timbres.
variants=[
('charon-grounded','Charon','grounded, low, serious, intimate storyteller; restrained and cinematic'),
('orus-firm','Orus','firm, resonant, mature storyteller; warm authority, never announcer-like'),
('algenib-gravelly','Algenib','textured, gravelly, mature storyteller; intimate and emotionally controlled'),
('sulafat-warm','Sulafat','warm, intimate, textured literary storyteller'),
('achernar-soft','Achernar','soft, nuanced, close-mic literary storyteller with excellent silence control'),
]
def find_audio(o):
    if isinstance(o,dict):
        if o.get('type')=='audio' and isinstance(o.get('data'),str): return o['data']
        for v in o.values():
            r=find_audio(v)
            if r:return r
    if isinstance(o,list):
        for v in o:
            r=find_audio(v)
            if r:return r
for slug,voice,direction in variants:
    print('Generating',slug,voice,flush=True)
    payload={'model':'gemini-2.5-flash-preview-tts','input':base+'\nVOICE DIRECTION: '+direction,'response_format':{'type':'audio'},'generation_config':{'speech_config':[{'voice':voice}]}}
    req=urllib.request.Request(endpoint,data=json.dumps(payload,ensure_ascii=False).encode(),headers={'x-goog-api-key':key,'Content-Type':'application/json','Api-Revision':'2026-05-20'},method='POST')
    try:
        with urllib.request.urlopen(req,timeout=180) as r: body=json.loads(r.read().decode())
    except urllib.error.HTTPError as e: raise SystemExit(f'Gemini API HTTP {e.code}: '+e.read().decode(errors='replace'))
    b64=find_audio(body)
    if not b64: raise SystemExit('No audio returned for '+slug)
    pcm=base64.b64decode(b64)
    wav=out/(slug+'.wav')
    with wave.open(str(wav),'wb') as wf:
        wf.setnchannels(1);wf.setsampwidth(2);wf.setframerate(24000);wf.writeframes(pcm)
PY
unset GEMINI_API_KEY

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is required to make WhatsApp-ready MP3 files."; exit 4
fi
for wav in "$OUT"/*.wav; do
  mp3="${wav%.wav}.mp3"
  ffmpeg -hide_banner -loglevel error -y -i "$wav" -codec:a libmp3lame -b:a 128k -ar 44100 "$mp3"
done

echo "Playing mixed-timbre MP3 audition..."
for f in "$OUT"/*.mp3; do echo "Now playing: $(basename "$f")"; afplay "$f" || true; done

echo
printf 'WhatsApp-ready MP3 files are in: %s\n' "$OUT"
open "$OUT" || true
