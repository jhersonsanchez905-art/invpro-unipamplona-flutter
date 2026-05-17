from django.contrib import admin

from .models import HttpStatusCatalog


@admin.register(HttpStatusCatalog)
class HttpStatusCatalogAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "category")
    list_filter = ("category",)
    ordering = ("code",)

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def get_readonly_fields(self, request, obj=None):
        return [f.name for f in self.model._meta.fields]
