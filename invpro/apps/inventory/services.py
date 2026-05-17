import re
from decimal import Decimal

from django.db import transaction
from django.core.exceptions import ValidationError
from django.utils import timezone

from apps.inventory.models import Categoria, Producto, StockAlerta


def generar_sku(categoria: Categoria) -> str:
    """Genera un SKU único para una categoría dada."""
    prefix = categoria.prefijo_sku

    ultimo = (
        Producto.objects.filter(categoria=categoria, sku__isnull=False)
        .exclude(sku="")
        .order_by("-created_at")
        .first()
    )

    if ultimo:
        match = re.search(r"INV-[A-Z]{3}-(\d{4})", ultimo.sku)
        if match:
            siguiente = int(match.group(1)) + 1
        else:
            siguiente = 1
    else:
        siguiente = 1

    return f"INV-{prefix}-{siguiente:04d}"


def crear_producto(
    nombre: str,
    descripcion: str = "",
    categoria_id=None,
    stock_minimo=0,
    precio_unitario=0,
    usuario=None,
) -> Producto:
    """Crea un nuevo producto en el sistema."""
    if categoria_id is None:
        raise ValidationError("La categoría es obligatoria.")

    try:
        categoria = Categoria.objects.get(id=categoria_id, is_active=True)
    except Categoria.DoesNotExist:
        raise ValidationError("La categoría no existe o está inactiva.")

    sku = generar_sku(categoria)

    producto = Producto.objects.create(
        nombre=nombre,
        descripcion=descripcion,
        categoria=categoria,
        sku=sku,
        stock_actual=0,
        stock_minimo=stock_minimo,
        precio_unitario=precio_unitario,
    )

    verificar_alertas_stock(producto)
    return producto


def actualizar_producto(producto_id, datos: dict, usuario=None) -> Producto:
    """Actualiza un producto existente."""
    try:
        producto = Producto.objects.get(id=producto_id, is_active=True)
    except Producto.DoesNotExist:
        raise ValidationError("El producto no existe o está inactivo.")

    # Nunca permitir cambiar SKU
    datos.pop("sku", None)

    allowed_fields = {"nombre", "descripcion", "stock_minimo", "precio_unitario", "categoria_id"}

    for field, value in datos.items():
        if field not in allowed_fields:
            continue

        if field == "categoria_id":
            try:
                categoria = Categoria.objects.get(id=value, is_active=True)
            except Categoria.DoesNotExist:
                raise ValidationError("La categoría no existe o está inactiva.")
            producto.categoria = categoria
        else:
            setattr(producto, field, value)

    producto.save()
    verificar_alertas_stock(producto)
    return producto


def eliminar_producto(producto_id, usuario=None) -> None:
    """Realiza un soft delete de un producto."""
    try:
        producto = Producto.objects.get(id=producto_id, is_active=True)
    except Producto.DoesNotExist:
        raise ValidationError("El producto no existe o ya fue eliminado.")

    producto.is_active = False
    producto.save(update_fields=["is_active"])


def verificar_alertas_stock(producto: Producto) -> None:
    """Verifica y actualiza alertas de stock para un producto."""
    # Crear alerta si está por debajo del mínimo y no hay alerta activa
    if producto.stock_actual <= producto.stock_minimo:
        if not StockAlerta.objects.filter(producto=producto, resuelta=False).exists():
            StockAlerta.objects.create(
                producto=producto,
                stock_al_momento=producto.stock_actual,
                stock_minimo_al_momento=producto.stock_minimo,
            )
    else:
        # Marcar alertas activas como resueltas
        StockAlerta.objects.filter(producto=producto, resuelta=False).update(
            resuelta=True, resolved_at=timezone.now()
        )
