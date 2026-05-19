# apps/accounts/api_urls.py
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.accounts.views import AuditLogViewSet, UsuariosViewSet

router = DefaultRouter()
router.register(r"auditoria", AuditLogViewSet, basename="auditoria")
router.register(r"usuarios", UsuariosViewSet, basename="usuarios")

urlpatterns = [
    path("", include(router.urls)),
]