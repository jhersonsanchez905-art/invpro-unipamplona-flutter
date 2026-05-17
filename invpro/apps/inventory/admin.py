from django.contrib import admin

from .models import Categoria, Producto, StockAlerta


@admin.register(Categoria)
class CategoriaAdmin(admin.ModelAdmin):
    list_display = ("nombre", "prefijo_sku", "color_hex", "is_active", "created_at")
    list_filter = ("is_active",)


@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = ("nombre", "sku", "categoria", "stock_actual", "precio_unitario", "is_active")
    list_filter = ("categoria", "is_active")


@admin.register(StockAlerta)
class StockAlertaAdmin(admin.ModelAdmin):
    list_display = ("producto", "stock_al_momento", "stock_minimo_al_momento", "resuelta", "created_at")
    list_filter = ("resuelta",)
