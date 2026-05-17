"""
RBAC permission classes for InvPro API.
Each class extends BasePermission and checks user roles.
Principle: deny by default.
"""
from rest_framework.permissions import BasePermission


class EsSuperAdmin(BasePermission):
    """Only superadmin role can access."""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.user.rol == 'superadmin':
            return True
        self.message = (
            f"No tienes permisos para esta acción. "
            f"Tu rol es '{request.user.rol}'. Se requiere: 'superadmin'."
        )
        return False


class EsAdmin(BasePermission):
    """Admin or superior role required."""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.user.es_admin():
            return True
        self.message = (
            f"No tienes permisos para esta acción. "
            f"Tu rol es '{request.user.rol}'. Se requiere: 'admin o superior'."
        )
        return False


class EsAlmacenista(BasePermission):
    """Almacenista or superior role required."""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.user.es_almacenista():
            return True
        self.message = (
            f"No tienes permisos para esta acción. "
            f"Tu rol es '{request.user.rol}'. Se requiere: 'almacenista o superior'."
        )
        return False


class EsAuditor(BasePermission):
    """Auditor or superior role required."""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.user.es_auditor():
            return True
        self.message = (
            f"No tienes permisos para esta acción. "
            f"Tu rol es '{request.user.rol}'. Se requiere: 'auditor o superior'."
        )
        return False


class EsVisualizador(BasePermission):
    """Any authenticated user passes."""
    def has_permission(self, request, view):
        return request.user.is_authenticated


class PuedeCrearProducto(BasePermission):
    """Only almacenistas, admins and superadmins can create products."""
    message = (
        "Solo almacenistas, administradores y superadministradores "
        "pueden crear productos."
    )
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.es_almacenista()


class PuedeEliminarProducto(BasePermission):
    """Only admins and superadmins can delete products."""
    message = (
        "Solo administradores y superadministradores "
        "pueden eliminar productos."
    )
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.es_admin()


class PuedeMovimiento(BasePermission):
    """Only almacenistas, admins and superadmins can register movements."""
    message = (
        "Solo almacenistas, administradores y superadministradores "
        "pueden registrar movimientos."
    )
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.es_almacenista()


class PuedeVerReportes(BasePermission):
    """Only auditors, admins and superadmins can view reports."""
    message = (
        "Solo auditores, administradores y superadministradores "
        "pueden ver reportes."
    )
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.es_auditor()


class PuedeGestionarUsuarios(BasePermission):
    """
    CREATE users: admin or superior.
    DELETE users: superadmin only.
    """
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.method == 'DELETE':
            if request.user.rol == 'superadmin':
                return True
            self.message = (
                f"No tienes permisos para esta acción. "
                f"Tu rol es '{request.user.rol}'. Se requiere: 'superadmin'."
            )
            return False
        if request.user.es_admin():
            return True
        self.message = (
            f"No tienes permisos para esta acción. "
            f"Tu rol es '{request.user.rol}'. Se requiere: 'admin o superior'."
        )
        return False