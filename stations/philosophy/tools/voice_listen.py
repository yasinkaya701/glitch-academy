#!/usr/bin/env python3
"""Mikrofondan Türkçe ses kaydı ve konuşmadan metne (STT) dönüştürücü.

Çalışma sırası:
1. sounddevice ile mikrofondan 16 kHz mono ses kaydeder (konuşma bittiğinde erken durur,
   en fazla --seconds saniye bekler).
2. ELEVEN_API_KEY (veya ELEVENLABS_API_KEY) tanımlıysa ElevenLabs Scribe STT API
   ('/v1/speech-to-text', model_id='scribe_v1', language_code='tr') ile metne çevirir.
3. Anahtar yoksa SpeechRecognition (Google Web Speech tr-TR) ile ücretsiz Türkçe metne çevirir.
4. Standart çıktıya tek satır JSON yazar: {"ok": true, "text": "..."}
"""
import io
import json
import os
import sys
import wave
from pathlib import Path

import numpy as np


def record_wav_bytes(max_seconds: float = 4.2, sr: int = 16000) -> bytes:
    import sounddevice as sd

    chunk_sec = 0.1
    chunk_samples = int(sr * chunk_sec)
    max_chunks = int(max_seconds / chunk_sec)
    frames = []
    heard_voice = False
    silent_after_voice = 0

    with sd.InputStream(samplerate=sr, channels=1, dtype="int16") as stream:
        for _ in range(max_chunks):
            data, _ = stream.read(chunk_samples)
            frames.append(data.copy())
            rms = float(np.sqrt(np.mean(data.astype(np.float32) ** 2)))
            if rms > 380.0:
                heard_voice = True
                silent_after_voice = 0
            elif heard_voice:
                silent_after_voice += 1
                if silent_after_voice >= 9:  # ~0.9 sn sessizlik -> cümle bitti
                    break

    pcm = np.concatenate(frames, axis=0) if frames else np.zeros((sr,), dtype=np.int16)
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(pcm.tobytes())
    return buf.getvalue()


def stt_elevenlabs(wav_bytes: bytes, api_key: str) -> str:
    import requests

    r = requests.post(
        "https://api.elevenlabs.io/v1/speech-to-text",
        headers={"xi-api-key": api_key},
        files={"file": ("speech.wav", wav_bytes, "audio/wav")},
        data={"model_id": "scribe_v1", "language_code": "tr"},
        timeout=15,
    )
    r.raise_for_status()
    return str(r.json().get("text", "")).strip()


def stt_google_tr(wav_bytes: bytes) -> str:
    import speech_recognition as sr

    rec = sr.Recognizer()
    with sr.AudioFile(io.BytesIO(wav_bytes)) as src:
        audio = rec.record(src)
    return str(rec.recognize_google(audio, language="tr-TR")).strip()


def main() -> None:
    seconds = 4.2
    for a in sys.argv[1:]:
        if a.startswith("--seconds="):
            seconds = float(a.split("=", 1)[1])

    try:
        wav_bytes = record_wav_bytes(max_seconds=seconds)
        api_key = os.environ.get("ELEVEN_API_KEY") or os.environ.get("ELEVENLABS_API_KEY") or ""
        text = ""
        if api_key:
            try:
                text = stt_elevenlabs(wav_bytes, api_key)
            except Exception:
                text = ""
        if not text:
            text = stt_google_tr(wav_bytes)
        print(json.dumps({"ok": bool(text), "text": text}, ensure_ascii=False))
    except Exception as exc:
        print(json.dumps({"ok": False, "text": "", "error": str(exc)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
