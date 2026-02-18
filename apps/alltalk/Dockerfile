FROM erew123/alltalk_tts:latest

ENV TORCH_FORCE_NO_WEIGHTS_ONLY_LOAD=1

RUN set -eux; \
    python3 -m pip uninstall -y torch torchaudio || true; \
    python3 -m pip install --no-cache-dir --upgrade --force-reinstall \
      torch torchaudio --index-url https://download.pytorch.org/whl/cu124; \
    python3 -m pip install --no-cache-dir "networkx<3"
