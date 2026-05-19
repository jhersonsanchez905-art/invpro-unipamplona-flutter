from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/v1/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    path("api/v1/auth/", include("apps.accounts.urls")),
    path("api/v1/", include("apps.accounts.api_urls")),
    path("api/v1/", include("apps.inventory.urls")),
    path("api/v1/", include("apps.movements.urls")),
]