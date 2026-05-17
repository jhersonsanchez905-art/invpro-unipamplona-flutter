from datetime import date, datetime, timedelta

from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models import Sum
from django.utils import timezone

from apps.inventory.models import Producto
from apps.inventory.services import verificar_alertas_stock
from apps.movements.models import Movimiento


def registrar_movimiento(tipo, producto_id, cantidad, usuario, nota="") -> Movimiento:
    """Registra un movimiento de inventario con lógica transaccional."""
    if cantidad <= 0:
        raise ValidationError("La cantidad debe ser mayor a 0.")

    with transaction.atomic():
        try:
            producto = Producto.objects.select_for_update().get(
                id=producto_id, is_active=True
            )
        except Producto.DoesNotExist:
            raise ValidationError("El producto no existe o está inactivo.")

        if tipo == "entrada":
            producto.stock_actual += cantidad
        elif tipo == "salida":
            if producto.stock_actual < cantidad:
                raise ValidationError(
                    f"Stock insuficiente. Disponible: {producto.stock_actual}"
                )
            producto.stock_actual -= cantidad
        elif tipo == "ajuste":
            producto.stock_actual = cantidad
        else:
            raise ValidationError("Tipo de movimiento no válido.")

        producto.save(update_fields=["stock_actual", "updated_at"])

        movimiento = Movimiento.objects.create(
            tipo=tipo,
            producto=producto,
            cantidad=cantidad,
            nota=nota,
            usuario=usuario,
        )

        verificar_alertas_stock(producto)

    return movimiento


def obtener_resumen_movimientos(dias=7) -> list:
    """Retorna entradas y salidas agrupadas por día para los últimos N días."""
    desde = timezone.now() - timedelta(days=dias)

    movimientos = Movimiento.objects.filter(created_at__gte=desde)

    # Obtener fechas únicas ordenadas
    fechas = (
        Movimiento.objects.filter(created_at__gte=desde)
        .dates("created_at", "day")
        .order_by("created_at__date")
    )

    resumen = []
    for fecha_obj in fechas:
        fecha_dt = datetime.combine(fecha_obj, datetime.min.time())
        fecha_fin = datetime.combine(fecha_obj, datetime.max.time())

        entradas = movimientos.filter(
            tipo="entrada", created_at__date=fecha_obj
        ).aggregate(total=Sum("cantidad"))["total"] or 0

        salidas = movimientos.filter(
            tipo="salida", created_at__date=fecha_obj
        ).aggregate(total=Sum("cantidad"))["total"] or 0

        resumen.append(
            {
                "fecha": fecha_obj.strftime("%d/%m"),
                "entradas": float(entradas),
                "salidas": float(salidas),
            }
        )

    return resumen
