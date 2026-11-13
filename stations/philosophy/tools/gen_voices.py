#!/usr/bin/env python3
"""Filozof replikleri için TTS ses (.mp3) ve 50 Hz dudak senkronu (.json) üreticisi.

Nasıl çalışır?
1. ELEVEN_API_KEY (veya ELEVENLABS_API_KEY) ortam değişkeni tanımlıysa:
   ElevenLabs '/v1/text-to-speech/{voice_id}/with-timestamps' uç noktasını (eleven_multilingual_v2)
   kullanır. Hem .mp3 dosyasını hem de harf zamanlaması + ses zarfından 50 Hz dudak açıklığı
   eğrisini (<line_id>.json) üretir. Metin değişmediyse tekrar API çağırmaz (kota koruma).
2. ELEVEN_API_KEY henüz verilmemişse (veya --engine=edge seçilirse):
   edge-tts (tr-TR-AhmetNeural, filozof yaş/ton ayarıyla) üzerinden Türkçe erkek sesi üretir
   ve macOS 'afconvert' ile ses dalgası zarfından 50 Hz dudak senkronu eğrisini çıkarır.

Kullanım:
  ELEVEN_API_KEY="..." python3 stations/philosophy/tools/gen_voices.py socrates
  python3 stations/philosophy/tools/gen_voices.py socrates   # anahtar yoksa edge-tts yedeğiyle üretir
"""
import asyncio
import base64
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np
import requests

ROOT = Path(__file__).resolve().parents[1]
LINES_PATH = ROOT / "data" / "lines.json"
AUDIO_DIR = ROOT / "audio"
FPS = 50  # 20 ms dudak senkronu adımı

OPEN_VOWELS = set("aAeEıIoOöÖuUüÜ")
ROUND_VOWELS = set("oOöÖuUüÜ")
CLOSED_CONSONANTS = set("bBmMpP")


def envelope_from_mp3(mp3_path: Path) -> tuple[float, list[float]]:
    """MP3 dosyasını afconvert ile geçici WAV'a çevirip 50 Hz RMS ağız açıklığı eğrisi çıkarır."""
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = Path(tmp.name)
    try:
        subprocess.run(
            ["/usr/bin/afconvert", "-f", "WAVE", "-d", "LEI16@22050", "-c", "1", str(mp3_path), str(wav_path)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        with wave.open(str(wav_path), "rb") as wf:
            sr = wf.getframerate()
            raw = wf.readframes(wf.getnframes())
        samples = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
        duration = len(samples) / float(sr)
        step = max(int(sr / FPS), 1)
        levels = []
        for i in range(0, len(samples), step):
            chunk = samples[i : i + step]
            rms = float(np.sqrt(np.mean(chunk * chunk) + 1e-9))
            levels.append(rms)
        if not levels:
            return 0.0, [0.0]
        arr = np.array(levels, dtype=np.float32)
        p95 = float(np.percentile(arr, 95)) if len(arr) > 4 else float(arr.max())
        norm = np.clip((arr - 0.012) / max(p95 - 0.012, 0.05), 0.0, 1.0)
        # Hafif yumuşatma: çene titremesini önler
        kernel = np.array([0.2, 0.6, 0.2], dtype=np.float32)
        smooth = np.convolve(norm, kernel, mode="same")
        return round(duration, 3), [round(float(x), 3) for x in smooth]
    finally:
        wav_path.unlink(missing_ok=True)


def blend_alignment_curve(levels: list[float], alignment: dict) -> list[float]:
    """ElevenLabs harf zamanlaması varsa ünlü/ünsüz ağırlığını RMS eğrisiyle birleştirir."""
    chars = alignment.get("characters", [])
    starts = alignment.get("character_start_times_seconds", [])
    ends = alignment.get("character_end_times_seconds", [])
    if not (chars and len(chars) == len(starts) == len(ends)):
        return levels
    out = list(levels)
    for ch, t0, t1 in zip(chars, starts, ends):
        i0 = max(int(t0 * FPS), 0)
        i1 = min(int(t1 * FPS) + 1, len(out))
        for idx in range(i0, i1):
            if ch in CLOSED_CONSONANTS:
                out[idx] = round(out[idx] * 0.25, 3)
            elif ch in OPEN_VOWELS:
                out[idx] = round(min(max(out[idx], 0.55) * 1.15, 1.0), 3)
    return out


def generate_elevenlabs(text: str, voice_id: str, api_key: str, mp3_out: Path) -> dict:
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}/with-timestamps"
    headers = {"xi-api-key": api_key, "Content-Type": "application/json"}
    payload = {
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {"stability": 0.52, "similarity_boost": 0.78, "style": 0.22, "use_speaker_boost": True},
    }
    r = requests.post(url, headers=headers, json=payload, timeout=45)
    r.raise_for_status()
    body = r.json()
    mp3_bytes = base64.b64decode(body["audio_base64"])
    mp3_out.write_bytes(mp3_bytes)
    duration, levels = envelope_from_mp3(mp3_out)
    alignment = body.get("alignment") or {}
    levels = blend_alignment_curve(levels, alignment)
    return {"engine": "elevenlabs", "duration": duration, "fps": FPS, "levels": levels}


async def generate_edge(text: str, voice_cfg: dict, mp3_out: Path) -> dict:
    import edge_tts

    comm = edge_tts.Communicate(
        text=text,
        voice=voice_cfg.get("edge_voice", "tr-TR-AhmetNeural"),
        pitch=voice_cfg.get("edge_pitch", "-10Hz"),
        rate=voice_cfg.get("edge_rate", "-6%"),
    )
    await comm.save(str(mp3_out))
    duration, levels = envelope_from_mp3(mp3_out)
    return {"engine": "edge_tts", "duration": duration, "fps": FPS, "levels": levels}


def build_philosopher(pid: str, force_engine: str | None = None) -> None:
    db = json.loads(LINES_PATH.read_text())
    voices = db.get("voices", {})
    pdata = db.get("philosophers", {}).get(pid)
    if not pdata:
        raise SystemExit(f"'{pid}' için lines.json kaydı bulunamadı.")
    vcfg = voices.get(pid, {})
    api_key = os.environ.get("ELEVEN_API_KEY") or os.environ.get("ELEVENLABS_API_KEY") or ""
    engine = force_engine or ("elevenlabs" if api_key else "edge_tts")

    out_dir = AUDIO_DIR / pid
    out_dir.mkdir(parents=True, exist_ok=True)

    for line_id, text in pdata.get("lines", {}).items():
        mp3_path = out_dir / f"{line_id}.mp3"
        meta_path = out_dir / f"{line_id}.json"
        sig = hashlib.sha256(f"{engine}:{vcfg.get('elevenlabs_voice_id','')}:{text}".encode("utf-8")).hexdigest()[:16]

        if mp3_path.exists() and meta_path.exists():
            old = json.loads(meta_path.read_text())
            if old.get("hash") == sig and old.get("engine") == engine:
                print(f"  [önbellek] {pid}/{line_id}.mp3 ({old.get('duration')}s, {engine})")
                continue

        if engine == "elevenlabs" and api_key:
            track = generate_elevenlabs(text, vcfg["elevenlabs_voice_id"], api_key, mp3_path)
        else:
            track = asyncio.run(generate_edge(text, vcfg, mp3_path))

        track["hash"] = sig
        track["text"] = text
        meta_path.write_text(json.dumps(track, indent=2, ensure_ascii=False) + "\n")
        print(f"  [üretildi] {pid}/{line_id}.mp3 ({track['duration']}s, {track['engine']}, {len(track['levels'])} kare)")


if __name__ == "__main__":
    live_who = None
    live_text = None
    live_out = None
    forced = None
    targets = []
    for a in sys.argv[1:]:
        if a.startswith("--engine="):
            forced = a.split("=", 1)[1]
        elif a.startswith("--who="):
            live_who = a.split("=", 1)[1]
        elif a.startswith("--text="):
            live_text = a.split("=", 1)[1]
        elif a.startswith("--out="):
            live_out = a.split("=", 1)[1]
        elif not a.startswith("--"):
            targets.append(a)

    if live_who and live_text and live_out:
        db = json.loads(LINES_PATH.read_text())
        vcfg = db.get("voices", {}).get(live_who, {})
        api_key = os.environ.get("ELEVEN_API_KEY") or os.environ.get("ELEVENLABS_API_KEY") or ""
        mp3_out = Path(live_out)
        mp3_out.parent.mkdir(parents=True, exist_ok=True)
        meta_out = mp3_out.with_suffix(".json")
        if api_key and forced != "edge_tts":
            track = generate_elevenlabs(live_text, vcfg.get("elevenlabs_voice_id", "pNInz6obpgDQGcFmaJgB"), api_key, mp3_out)
        else:
            track = asyncio.run(generate_edge(live_text, vcfg, mp3_out))
        track["text"] = live_text
        meta_out.write_text(json.dumps(track, ensure_ascii=False))
        raise SystemExit(0)

    if not targets or targets == ["all"]:
        db = json.loads(LINES_PATH.read_text())
        targets = list(db.get("philosophers", {}).keys())
    for t in targets:
        build_philosopher(t, forced)
