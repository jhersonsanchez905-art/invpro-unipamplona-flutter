from django.contrib import admin

from .models import Categoria, Producto


@admin.register(Categoria)
class CategoriaAdmin(admin.ModelAdmin):
    list_display = ("nombre", "prefijo_sku", "color_hex", "is_active", "created_at")
    list_filter = ("is_active",)


@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = ("nombre", "sku", "categoria", "stock_actual", "precio_unitario", "is_active")
    list_filter = ("categoria", "is_active")
