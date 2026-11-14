#!/usr/bin/env python3
"""Filozof ve Tarih replikleri için TTS ses (.mp3) ve 50 Hz dudak senkronu (.json) üreticisi.

Nasıl çalışır?
1. ELEVEN_API_KEY (veya user://elevenlabs_key.txt, .env, --api-key) tanımlıysa:
   ElevenLabs '/v1/text-to-speech/{voice_id}/with-timestamps' uç noktasını (eleven_multilingual_v2)
   kullanır. Hem .mp3 dosyasını hem de harf zamanlaması + ses dalgası RMS zarfından 50 Hz dudak açıklığı
   eğrisini (<line_id>.json) üretir. Metin değişmediyse tekrar API çağırmaz (kota koruma).
2. ELEVEN_API_KEY verilmemişse (veya --engine=edge seçilirse):
   edge-tts (tr-TR-AhmetNeural) üzerinden Türkçe erkek sesi üretir ve macOS 'afconvert' ile ses dalgası
   zarfından 50 Hz dudak senkronu eğrisini çıkarır.

Kullanım:
  # Tek filozof üretimi (ElevenLabs):
  python3 stations/philosophy/tools/gen_voices.py socrates --engine=elevenlabs --api-key="<KEY>"
  # Tüm filozofları aynı sesle üret:
  python3 stations/philosophy/tools/gen_voices.py all --voice-id=pNInz6obpgDQGcFmaJgB
  # Tarih figürlerini üret:
  python3 stations/philosophy/tools/gen_voices.py all --station=history
  # Canlı tek replik üret:
  python3 stations/philosophy/tools/gen_voices.py --who=socrates --text="Merhaba dünya" --out=/path/to/test.mp3
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

ROOT = Path(__file__).resolve().parents[3] if "stations" in str(Path(__file__).resolve()) else Path(__file__).resolve().parents[1]
# Varsayılan paths
PHILOSOPHY_ROOT = ROOT / "stations" / "philosophy"
HISTORY_ROOT = ROOT / "stations" / "history"
FPS = 50  # 20 ms dudak senkronu adımı

OPEN_VOWELS = set("aAeEıIoOöÖuUüÜ")
ROUND_VOWELS = set("oOöÖuUüÜ")
CLOSED_CONSONANTS = set("bBmMpP")

DEFAULT_ELEVEN_VOICE = "CwhRBWXzGAHq8TQ4Fs17"  # Roger / Kallavi yaşlı bilge filozof sesi


def resolve_api_key(cli_key: str | None = None) -> str:
    """Sırasıyla CLI argümanı, ortam değişkenleri, Godot user:// dizini ve .env dosyasından anahtarı arar."""
    if cli_key and cli_key.strip():
        return cli_key.strip()

    for k in ("ELEVEN_API_KEY", "ELEVENLABS_API_KEY", "XI_API_KEY"):
        val = os.environ.get(k)
        if val and val.strip():
            return val.strip()

    # Godot app_userdata kontrolü (macOS ve Linux/Windows uyumlu)
    godot_paths = [
        Path.home() / "Library" / "Application Support" / "Godot" / "app_userdata" / "3 Cisim 1 Dünya" / "elevenlabs_key.txt",
        Path.home() / ".local" / "share" / "godot" / "app_userdata" / "3 Cisim 1 Dünya" / "elevenlabs_key.txt",
        Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata" / "3 Cisim 1 Dünya" / "elevenlabs_key.txt"
    ]
    for p in godot_paths:
        if p.exists():
            try:
                content = p.read_text(encoding="utf-8").strip()
                if content:
                    return content
            except Exception:
                pass

    # Çalışma alanı veya kök .env kontrolü
    for env_path in (ROOT / ".env", Path.cwd() / ".env"):
        if env_path.exists():
            try:
                for line in env_path.read_text(encoding="utf-8").splitlines():
                    line = line.strip()
                    if line.startswith("#") or "=" not in line:
                        continue
                    k, v = line.split("=", 1)
                    k = k.strip()
                    v = v.strip().strip("'\"")
                    if k in ("ELEVEN_API_KEY", "ELEVENLABS_API_KEY", "XI_API_KEY") and v:
                        return v
            except Exception:
                pass

    return ""


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
        "voice_settings": {"stability": 0.68, "similarity_boost": 0.85, "style": 0.05, "use_speaker_boost": True},
    }
    r = requests.post(url, headers=headers, json=payload, timeout=45)
    if r.status_code != 200:
        raise RuntimeError(f"ElevenLabs API Hatası [{r.status_code}]: {r.text}")
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


def build_character(
    cid: str,
    lines_path: Path,
    audio_dir: Path,
    api_key: str,
    force_engine: str | None = None,
    override_voice_id: str | None = None,
    force_rebuild: bool = False,
) -> None:
    db = json.loads(lines_path.read_text(encoding="utf-8"))
    voices = db.get("voices", {})
    chars = db.get("philosophers") or db.get("figures") or {}
    cdata = chars.get(cid)
    if not cdata:
        raise SystemExit(f"'{cid}' için {lines_path.name} kaydı bulunamadı.")
    vcfg = voices.get(cid, {})
    voice_id = override_voice_id or vcfg.get("elevenlabs_voice_id") or DEFAULT_ELEVEN_VOICE

    engine = force_engine or ("elevenlabs" if api_key else "edge_tts")

    out_dir = audio_dir / cid
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n▶ [{cid}] Ses üretimi başlıyor (motor: {engine}, voice_id: {voice_id})...")

    for line_id, text in cdata.get("lines", {}).items():
        mp3_path = out_dir / f"{line_id}.mp3"
        meta_path = out_dir / f"{line_id}.json"
        sig = hashlib.sha256(f"{engine}:{voice_id}:{text}".encode("utf-8")).hexdigest()[:16]

        if not force_rebuild and mp3_path.exists() and meta_path.exists():
            try:
                old = json.loads(meta_path.read_text(encoding="utf-8"))
                if old.get("hash") == sig and old.get("engine") == engine:
                    print(f"  [önbellek] {cid}/{line_id}.mp3 ({old.get('duration')}s, {engine})")
                    continue
            except Exception:
                pass

        if engine == "elevenlabs":
            if not api_key:
                raise RuntimeError("ElevenLabs seçildi ancak API anahtarı bulunamadı!")
            try:
                track = generate_elevenlabs(text, voice_id, api_key, mp3_path)
            except Exception as e:
                print(f"  [UYARI] ElevenLabs çağrısı başarısız ({e}), yerel yedek (edge_tts) ile üretiliyor...")
                track = asyncio.run(generate_edge(text, vcfg, mp3_path))
        else:
            track = asyncio.run(generate_edge(text, vcfg, mp3_path))

        track["hash"] = sig
        track["text"] = text
        meta_path.write_text(json.dumps(track, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"  [üretildi] {cid}/{line_id}.mp3 ({track['duration']}s, {track['engine']}, {len(track['levels'])} kare)")


if __name__ == "__main__":
    live_who = None
    live_text = None
    live_out = None
    forced = None
    cli_key = None
    station = "philosophy"
    override_voice = None
    force_flag = False
    targets = []

    for a in sys.argv[1:]:
        if a.startswith("--engine="):
            forced = a.split("=", 1)[1]
        elif a.startswith("--api-key="):
            cli_key = a.split("=", 1)[1]
        elif a.startswith("--station="):
            station = a.split("=", 1)[1]
        elif a.startswith("--voice-id="):
            override_voice = a.split("=", 1)[1]
        elif a in ("--force", "-f"):
            force_flag = True
        elif a.startswith("--who="):
            live_who = a.split("=", 1)[1]
        elif a.startswith("--text="):
            live_text = a.split("=", 1)[1]
        elif a.startswith("--out="):
            live_out = a.split("=", 1)[1]
        elif not a.startswith("--"):
            targets.append(a)

    api_key = resolve_api_key(cli_key)

    # Canlı tek replik üretimi
    if live_who and live_text and live_out:
        lines_p = (HISTORY_ROOT if station == "history" else PHILOSOPHY_ROOT) / "data" / "lines.json"
        db = json.loads(lines_p.read_text(encoding="utf-8"))
        vcfg = db.get("voices", {}).get(live_who, {})
        voice_id = override_voice or vcfg.get("elevenlabs_voice_id", DEFAULT_ELEVEN_VOICE)
        mp3_out = Path(live_out)
        mp3_out.parent.mkdir(parents=True, exist_ok=True)
        meta_out = mp3_out.with_suffix(".json")
        if api_key and forced != "edge_tts":
            track = generate_elevenlabs(live_text, voice_id, api_key, mp3_out)
        else:
            track = asyncio.run(generate_edge(live_text, vcfg, mp3_out))
        track["text"] = live_text
        meta_out.write_text(json.dumps(track, ensure_ascii=False), encoding="utf-8")
        print(f"Canlı TTS üretildi: {live_out}")
        raise SystemExit(0)

    # Hedef istasyon dizinleri
    if station == "history":
        lines_path = HISTORY_ROOT / "data" / "lines.json"
        audio_dir = HISTORY_ROOT / "audio"
    else:
        lines_path = PHILOSOPHY_ROOT / "data" / "lines.json"
        audio_dir = PHILOSOPHY_ROOT / "audio"

    db = json.loads(lines_path.read_text(encoding="utf-8"))
    available_chars = list((db.get("philosophers") or db.get("figures") or {}).keys())

    if not targets or targets == ["all"]:
        targets = available_chars

    print(f"=== Glitch Academy TTS Üretici ===")
    print(f"İstasyon: {station}")
    print(f"Kayıt: {lines_path}")
    print(f"API Anahtarı: {'Mevcut (uzunluk: ' + str(len(api_key)) + ')' if api_key else 'Bulunamadı (edge_tts kullanılacak)'}")
    print(f"Ortak Ses ID: {override_voice or DEFAULT_ELEVEN_VOICE}")
    print(f"Hedefler: {', '.join(targets)}")

    for t in targets:
        build_character(
            cid=t,
            lines_path=lines_path,
            audio_dir=audio_dir,
            api_key=api_key,
            force_engine=forced,
            override_voice_id=override_voice,
            force_rebuild=force_flag,
        )
    print("\n✅ Tüm sesler başarıyla işlendi.")
