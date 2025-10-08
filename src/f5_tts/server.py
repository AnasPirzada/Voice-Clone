from __future__ import annotations

import io
import os
from typing import Optional

from flask import Flask, jsonify, request, send_file

from f5_tts.api import F5TTS


app = Flask(__name__)


_model: Optional[F5TTS] = None


def get_model() -> F5TTS:
    global _model
    if _model is None:
        # Allow overrides via env for quick testing
        model_name = os.getenv("F5TTS_MODEL", "F5TTS_v1_Base")
        ckpt_file = os.getenv("F5TTS_CKPT", "")
        vocab_file = os.getenv("F5TTS_VOCAB", "")
        ode_method = os.getenv("F5TTS_ODE_METHOD", "euler")
        use_ema = os.getenv("F5TTS_USE_EMA", "true").lower() == "true"
        vocoder_local_path = os.getenv("F5TTS_VOCODER_LOCAL_PATH")
        device = os.getenv("F5TTS_DEVICE")
        hf_cache_dir = os.getenv("HF_HOME")
        _model = F5TTS(
            model=model_name,
            ckpt_file=ckpt_file,
            vocab_file=vocab_file,
            ode_method=ode_method,
            use_ema=use_ema,
            vocoder_local_path=vocoder_local_path,
            device=device,
            hf_cache_dir=hf_cache_dir,
        )
    return _model


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/tts")
def tts():
    """
    Multipart/form-data or JSON:
    - If multipart: fields: ref_text (str, optional), gen_text (str, required), file 'ref_audio' (required)
    - If JSON: fields: ref_audio_path (str, required), ref_text (str, optional), gen_text (str, required)

    Query params (optional, with defaults): target_rms, cross_fade_duration, sway_sampling_coef, cfg_strength,
    nfe_step, speed, fix_duration, remove_silence.

    Returns: audio/wav bytes.
    """
    m = get_model()

    # Gather generation params
    def get_float_arg(name: str, default: Optional[float]):
        val = request.args.get(name)
        if val is None:
            return default
        try:
            return float(val)
        except ValueError:
            return default

    target_rms = get_float_arg("target_rms", 0.1)
    cross_fade_duration = get_float_arg("cross_fade_duration", 0.15)
    sway_sampling_coef = get_float_arg("sway_sampling_coef", -1.0)
    cfg_strength = get_float_arg("cfg_strength", 2.0)
    nfe_step = int(get_float_arg("nfe_step", 32))
    speed = get_float_arg("speed", 1.0)
    fix_duration = get_float_arg("fix_duration", None)
    remove_silence = request.args.get("remove_silence", "false").lower() == "true"

    ref_audio_path: Optional[str] = None
    ref_text: Optional[str] = None
    gen_text: Optional[str] = None

    if request.content_type and request.content_type.startswith("multipart/form-data"):
        if "ref_audio" not in request.files:
            return jsonify({"error": "ref_audio file is required"}), 400
        ref_audio_file = request.files["ref_audio"]
        if ref_audio_file.filename == "":
            return jsonify({"error": "ref_audio file is required"}), 400
        tmp_path = os.path.join(app.instance_path, "uploads")
        os.makedirs(tmp_path, exist_ok=True)
        local_path = os.path.join(tmp_path, ref_audio_file.filename)
        ref_audio_file.save(local_path)
        ref_audio_path = local_path
        ref_text = request.form.get("ref_text", "")
        gen_text = request.form.get("gen_text", "")
    else:
        data = request.get_json(silent=True) or {}
        ref_audio_path = data.get("ref_audio_path")
        ref_text = data.get("ref_text", "")
        gen_text = data.get("gen_text", "")

    if not ref_audio_path:
        return jsonify({"error": "ref_audio or ref_audio_path is required"}), 400
    if not gen_text:
        return jsonify({"error": "gen_text is required"}), 400

    wav, sr, _ = m.infer(
        ref_file=ref_audio_path,
        ref_text=ref_text or "",
        gen_text=gen_text,
        show_info=lambda *args, **kwargs: None,
        progress=None,
        target_rms=target_rms,
        cross_fade_duration=cross_fade_duration,
        sway_sampling_coef=sway_sampling_coef,
        cfg_strength=cfg_strength,
        nfe_step=nfe_step,
        speed=speed,
        fix_duration=fix_duration,
        remove_silence=remove_silence,
        file_wave=None,
        file_spec=None,
        seed=None,
    )

    # Stream as WAV in-memory
    import soundfile as sf

    buf = io.BytesIO()
    sf.write(buf, wav, sr, format="WAV")
    buf.seek(0)
    return send_file(buf, mimetype="audio/wav", as_attachment=False, download_name="tts.wav")


def main():
    # Ensure instance folder exists for uploads
    os.makedirs(app.instance_path, exist_ok=True)
    host = os.getenv("F5TTS_API_HOST", "127.0.0.1")
    port = int(os.getenv("F5TTS_API_PORT", "8000"))
    debug = os.getenv("F5TTS_API_DEBUG", "false").lower() == "true"
    # Lazy-initialize on first request to reduce startup time
    app.run(host=host, port=port, debug=debug)
