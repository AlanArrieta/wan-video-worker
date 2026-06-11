# Imagen mínima para Wan 2.2 i2v en RunPod serverless.
# Los MODELOS NO van aquí: viven en el Network Volume (/runpod-volume/models/...).
# Aquí horneamos: (1) VideoHelperSuite (nodo de salida MP4) y
#                 (2) un parche al handler para que ENTREGUE ese MP4 por R2.
#
# Build (desde la carpeta que contiene este Dockerfile):
#   docker build --platform linux/amd64 -t TU_USUARIO/wan-i2v-worker:1.1 .
#   docker push TU_USUARIO/wan-i2v-worker:1.1
#
# Alternativa sin Docker local: sube esta carpeta a un repo de GitHub y usa
# la integración GitHub de RunPod Serverless (build automático en cada push).
FROM runpod/worker-comfyui:5.8.5-base

# Nodo necesario para entregar video (.mp4).
RUN comfy-node-install comfyui-videohelpersuite

# --- Parche de entrega de video ---
# VHS_VideoCombine escribe el .mp4 bajo la clave "gifs"; el handler oficial solo
# recolecta "images". El script normaliza gifs->images ANTES del loop existente,
# así el .mp4 se sube a R2 con la MISMA lógica de subida (sin tocarla).
# Si el ancla no existe (cambió el handler), el build FALLA aquí a propósito
# para no gastar GPU con un parche que no aplicó.
COPY patch_handler.py /tmp/patch_handler.py
RUN python3 /tmp/patch_handler.py

# (Opcional) SageAttention para ganar algo de velocidad. Si lo activas, vuelve a
# meter el nodo PatchSageAttentionKJ en el workflow. Por robustez headless va FUERA.
# RUN comfy-node-install comfyui-kjnodes && pip install sageattention

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
