"""
Natural Neural Text-To-Speech (TTS) Service
Supports Indian Regional Languages: Kannada, Hindi, English, Tamil, Telugu, Marathi, Bengali, Gujarati, Malayalam.
Uses Microsoft Edge Neural voices (Azure Neural quality) with gTTS fallback and in-memory audio caching.
"""

import os
import io
import base64
import hashlib
import asyncio
import logging
from typing import Dict, Optional, Tuple

logger = logging.getLogger(__name__)

# Official Natural Indian Neural Voice Mapping
NEURAL_VOICES: Dict[str, str] = {
    'kn': 'kn-IN-SapnaNeural',     # Kannada (Female, Natural)
    'hi': 'hi-IN-SwaraNeural',     # Hindi (Female, Natural)
    'en': 'en-IN-NeerjaNeural',    # Indian English (Female, Natural)
    'ta': 'ta-IN-PallaviNeural',   # Tamil (Female, Natural)
    'te': 'te-IN-ShrutiNeural',    # Telugu (Female, Natural)
    'mr': 'mr-IN-AarohiNeural',    # Marathi (Female, Natural)
    'bn': 'bn-IN-TanishaaNeural',  # Bengali (Female, Natural)
    'gu': 'gu-IN-DhwaniNeural',    # Gujarati (Female, Natural)
    'ml': 'ml-IN-SobhanaNeural',   # Malayalam (Female, Natural)
}

# In-memory cache for ultra-fast instant playback of repeated station announcements
_TTS_CACHE: Dict[str, bytes] = {}
_MAX_CACHE_SIZE = 100


class NaturalTTSService:
    @staticmethod
    def _cache_key(text: str, lang: str) -> str:
        raw = f"{lang.lower().strip()}:{text.strip()}"
        return hashlib.md5(raw.encode('utf-8')).hexdigest()

    @classmethod
    async def synthesize(cls, text: str, lang: str = 'kn') -> Tuple[bytes, str, str]:
        """
        Synthesizes natural speech audio in MP3 format for the given text and language.
        Returns: (audio_bytes, engine_name, voice_name)
        """
        clean_text = text.strip()
        if not clean_text:
            return b"", "none", "none"

        lang_code = lang.lower().strip()
        if lang_code not in NEURAL_VOICES:
            lang_code = 'en'

        voice = NEURAL_VOICES[lang_code]
        key = cls._cache_key(clean_text, lang_code)

        # Check Cache
        if key in _TTS_CACHE:
            return _TTS_CACHE[key], "edge_tts_cache", voice

        # 1. Primary: Edge-TTS Neural Voice
        try:
            import edge_tts
            communicate = edge_tts.Communicate(clean_text, voice)
            audio_buffer = bytearray()
            async for chunk in communicate.stream():
                if chunk["type"] == "audio":
                    audio_buffer.extend(chunk["data"])

            if audio_buffer:
                audio_bytes = bytes(audio_buffer)
                if len(_TTS_CACHE) < _MAX_CACHE_SIZE:
                    _TTS_CACHE[key] = audio_bytes
                return audio_bytes, "edge_tts_neural", voice
        except Exception as e:
            logger.warning(f"Edge-TTS synthesis error for {lang_code}: {e}, falling back to gTTS")

        # 2. Secondary Fallback: gTTS
        try:
            from gtts import gTTS
            # gTTS language code mapping
            gtts_lang = lang_code
            if gtts_lang not in ['kn', 'hi', 'en', 'ta', 'te', 'mr', 'bn', 'gu', 'ml']:
                gtts_lang = 'en'
            
            tts = gTTS(text=clean_text, lang=gtts_lang, slow=False)
            fp = io.BytesIO()
            tts.write_to_fp(fp)
            fp.seek(0)
            audio_bytes = fp.read()
            if audio_bytes:
                if len(_TTS_CACHE) < _MAX_CACHE_SIZE:
                    _TTS_CACHE[key] = audio_bytes
                return audio_bytes, "gtts", f"gtts_{gtts_lang}"
        except Exception as e:
            logger.error(f"gTTS fallback error for {lang_code}: {e}")

        return b"", "error", "none"

    @classmethod
    def synthesize_sync(cls, text: str, lang: str = 'kn') -> Tuple[bytes, str, str]:
        """Synchronous wrapper for synthesize."""
        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                # In running event loop, create task or new loop in thread
                import concurrent.futures
                with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
                    future = pool.submit(asyncio.run, cls.synthesize(text, lang))
                    return future.result()
            else:
                return loop.run_until_complete(cls.synthesize(text, lang))
        except RuntimeError:
            return asyncio.run(cls.synthesize(text, lang))


tts_service = NaturalTTSService()
