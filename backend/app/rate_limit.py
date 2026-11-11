from slowapi import Limiter
from slowapi.util import get_remote_address

from .config import get_settings

# Instancia compartida del limitador. Vive en su propio módulo para que las rutas
# puedan usar @limiter.limit(...) sin importar main.py (evita importaciones circulares).
# Nota: detrás de un proxy inverso hay que configurar el proxy para enviar la IP real
# (por ejemplo, uvicorn --proxy-headers --forwarded-allow-ips=<ip del proxy>).
limiter = Limiter(key_func=get_remote_address, enabled=get_settings().rate_limit_enabled)
