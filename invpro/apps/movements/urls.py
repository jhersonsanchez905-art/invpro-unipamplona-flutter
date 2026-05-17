from django.urls import path, include
from rest_framework.routers import DefaultRouter

from apps.movements.views import MovimientoViewSet

router = DefaultRouter()
router.register(r"movimientos", MovimientoViewSet, basename="movimientos")

urlpatterns = [
    path("", include(router.urls)),
]
