from django.urls import path, include
from rest_framework.routers import DefaultRouter

from apps.accounts.views import AuditLogViewSet, UsuariosViewSet

router = DefaultRouter()
router.register(r"auditoria", AuditLogViewSet, basename="auditoria")
router.register(r"usuarios", UsuariosViewSet, basename="usuarios")

urlpatterns = [
    path("", include(router.urls)),
]