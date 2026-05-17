"""
Middleware de auditoría automática para InvPro.

Registra en AuditLog toda operación POST, PUT, PATCH, DELETE realizada
por usuarios autenticados. Omite GET, HEAD, OPTIONS y todas las rutas
bajo /api/v1/auth/ (por seguridad de contraseñas y OTPs).

Nunca interrumpe la request si el log falla.
"""

import logging

logger = logging.getLogger(__name__)

PATH_ENTITY_MAP = {
    "productos": "Producto",
    "categorias": "Categoria",
    "movimientos": "Movimiento",
    "auth": "Auth",
}

METHOD_ACTION_MAP = {
    "POST": "create",
    "PUT": "update",
    "PATCH": "update",
    "DELETE": "delete",
}

SKIP_METHODS = frozenset({"GET", "HEAD", "OPTIONS"})
SKIP_PREFIX = "/api/v1/auth/"


class AuditoriaMiddleware:
    """
    Middleware que registra automáticamente acciones significativas
    (create, update, delete) en el modelo AuditLog.

    Omite:
    - Métodos GET, HEAD, OPTIONS
    - Rutas bajo /api/v1/auth/ (protegen credenciales y OTPs)
    - Usuarios no autenticados
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        self.log_action(request, response)
        return response

    def log_action(self, request, response):
        try:
            if request.method in SKIP_METHODS:
                return

            if not request.user.is_authenticated:
                return

            path = request.path_info

            if path.startswith(SKIP_PREFIX):
                return

            forwarded = request.META.get("HTTP_X_FORWARDED_FOR")
            if forwarded:
                ip_address = forwarded.split(",")[0].strip()
            else:
                ip_address = request.META.get("REMOTE_ADDR", "")

            action = METHOD_ACTION_MAP.get(request.method, "unknown")

            parts = [p for p in path.split("/") if p]
            entity = "Unknown"
            for part in parts:
                if part in PATH_ENTITY_MAP:
                    entity = PATH_ENTITY_MAP[part]
                    break

            from apps.accounts.models import AuditLog

            AuditLog.objects.create(
                user=request.user,
                action=action,
                entity=entity,
                ip_address=ip_address or None,
                user_agent=request.META.get("HTTP_USER_AGENT", ""),
                http_status=response.status_code,
            )

        except Exception:
            logger.exception("Error al registrar auditoría para %s %s", request.method, request.path_info)
