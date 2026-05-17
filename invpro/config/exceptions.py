"""
Custom exception handler for Django REST Framework.

Wraps all error responses in a standard format with Spanish messages
and human-readable error codes mapped from HTTP status codes.
"""

from rest_framework.views import exception_handler
from rest_framework.response import Response


def custom_exception_handler(exc, context):
    """
    Custom exception handler for DRF that wraps all error responses
    in a standard format with Spanish messages and human-readable codes.

    Args:
        exc: The exception that was raised.
        context: A dictionary containing the request and view context.

    Returns:
        Response: A DRF Response object with the standardized error format.
    """
    response = exception_handler(exc, context)

    error_mapping = {
        400: ("VALIDATION_ERROR", "Los datos enviados no son válidos."),
        401: ("NOT_AUTHENTICATED", "Debes iniciar sesión para acceder a este recurso."),
        403: ("PERMISSION_DENIED", "No tienes permisos para realizar esta acción."),
        404: ("NOT_FOUND", "El recurso solicitado no existe."),
        405: ("METHOD_NOT_ALLOWED", "Método HTTP no permitido."),
        429: ("RATE_LIMIT_EXCEEDED", "Demasiadas solicitudes. Espera un momento e intenta de nuevo."),
        500: ("SERVER_ERROR", "Error interno del servidor. Contacta al administrador."),
    }

    if response is not None:
        status_code = response.status_code
        code, message = error_mapping.get(status_code, ("UNEXPECTED_ERROR", "Ha ocurrido un error inesperado."))
    else:
        return Response(
            {
                "success": False,
                "error": {
                    "code": "SERVER_ERROR",
                    "message": "Error interno del servidor. Contacta al administrador."
                }
            },
            status=500
        )

    response.data = {
        "success": False,
        "error": {
            "code": code,
            "message": message
        }
    }
    response.status_code = status_code

    return response