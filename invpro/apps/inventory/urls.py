from django.urls import path, include
from rest_framework.routers import DefaultRouter

from apps.inventory.report_views import ReporteView
from apps.inventory.views import (
    CategoriaViewSet,
    ProductoViewSet,
    StockAlertaViewSet,
)

router = DefaultRouter()
router.register(r"categorias", CategoriaViewSet, basename="categorias")
router.register(r"productos", ProductoViewSet, basename="productos")
router.register(r"alertas", StockAlertaViewSet, basename="alertas")

urlpatterns = [
    path("", include(router.urls)),
    path("reports/<str:tipo>/", ReporteView.as_view(), name="reporte"),
]
