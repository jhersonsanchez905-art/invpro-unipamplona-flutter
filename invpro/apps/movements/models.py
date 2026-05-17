import uuid

from django.conf import settings
from django.db import models


class Movimiento(models.Model):
    """
    Registro inmutable de movimiento de inventario (entrada, salida o ajuste).
    Una vez creado no puede ser modificado ni eliminado.
    """

    TIPO_CHOICES = [
        ("entrada", "Entrada"),
        ("salida", "Salida"),
        ("ajuste", "Ajuste"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tipo = models.CharField(max_length=10, choices=TIPO_CHOICES)
    producto = models.ForeignKey(
        "inventory.Producto", on_delete=models.PROTECT, related_name="movimientos"
    )
    cantidad = models.DecimalField(max_digits=12, decimal_places=2)
    nota = models.TextField(blank=True, max_length=500)
    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="movimientos",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Movimiento"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.get_tipo_display()} - {self.producto} ({self.cantidad})"
