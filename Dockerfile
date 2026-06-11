# syntax=docker/dockerfile:1
# Imagen mínima para Wan 2.2 i2v en RunPod serverless.
# Los MODELOS NO van aquí: viven en el Network Volume (/runpod-volume/models/...).
# Aquí horneamos: (1) VideoHelperSuite (nodo de salida MP4) y
#                 (2) un parche al handler para que ENTREGUE ese MP4 por R2.
#
# Alternativa sin Docker local: este archivo + extra_model_paths.yaml en un repo
# de GitHub, con la integración GitHub de RunPod Serverless (build en cada push).
FROM runpod/worker-comfyui:5.8.5-base

# Nodo necesario para entregar video (.mp4).
RUN comfy-node-install comfyui-videohelpersuite

# --- Parche de entrega de video (inline, sin archivos externos) ---
# VHS_VideoCombine escribe el .mp4 bajo la clave "gifs"; el handler oficial solo
# recolecta "images". Normalizamos gifs->images ANTES del loop existente, así el
# .mp4 se sube a R2 con la MISMA lógica de subida (sin tocarla).
# Si el ancla no existe (cambió el handler), el build FALLA aquí a propósito,
# en CPU (gratis), nunca en una corrida de GPU.
RUN python3 <<'PY'
import subprocess, sys
ANCHOR = 'if "images" in node_output:'
res = subprocess.run(
    ["bash", "-lc", "find / -maxdepth 6 -name handler.py 2>/dev/null"],
    capture_output=True, text=True,
)
cands = sorted([p for p in res.stdout.splitlines() if p.strip()], key=len)
target = None
for p in cands:
    try:
        if ANCHOR in open(p, encoding="utf-8").read():
            target = p
            break
    except Exception:
        pass
if not target:
    sys.exit(f"[patch-mp4] ERROR: handler con ancla no encontrado. Candidatos: {cands}")
src = open(target, encoding="utf-8").read()
if 'node_output["images"] = node_output["gifs"]' in src:
    print(f"[patch-mp4] ya parcheado -> {target}")
else:
    indent = next(l[: len(l) - len(l.lstrip())] for l in src.splitlines() if ANCHOR in l)
    inject = (
        f'{indent}# [patch-mp4] tratar la salida de video (gifs) como images\n'
        f'{indent}if "gifs" in node_output and "images" not in node_output:\n'
        f'{indent}    node_output["images"] = node_output["gifs"]\n'
    )
    src = src.replace(indent + ANCHOR, inject + indent + ANCHOR, 1)
    open(target, "w", encoding="utf-8").write(src)
    print(f"[patch-mp4] OK -> {target}")
PY

# (Opcional) SageAttention. Si lo activas, vuelve a meter PatchSageAttentionKJ
# en el workflow. Por robustez headless va FUERA por defecto.
# RUN comfy-node-install comfyui-kjnodes && pip install sageattention

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
