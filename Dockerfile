# Imagen mínima para Wan 2.2 i2v en RunPod serverless.
# Los MODELOS NO van aquí: viven en el Network Volume (/runpod-volume/models/...).
# Aquí solo horneamos el custom node que falta en la base: VideoHelperSuite (nodo de salida MP4).
#
# Build (desde la carpeta que contiene este Dockerfile):
#   docker build --platform linux/amd64 -t TU_USUARIO/wan-i2v-worker:1.0 .
#   docker push TU_USUARIO/wan-i2v-worker:1.0
#
# Alternativa sin Docker local: sube este Dockerfile a un repo de GitHub y usa
# la integración GitHub de RunPod Serverless (build automático en cada push).

FROM runpod/worker-comfyui:5.1.0-base

# Nodo necesario para entregar video (.mp4). Es el único custom node del workflow limpio.
RUN comfy-node-install comfyui-videohelpersuite

# (Opcional) Si más adelante quieres re-activar SageAttention para ganar algo de velocidad,
# descomenta la línea siguiente. Si lo haces, vuelve a meter el nodo PatchSageAttentionKJ
# en el workflow. Por defecto lo dejamos FUERA por robustez en headless.
# RUN comfy-node-install comfyui-kjnodes && pip install sageattention
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
