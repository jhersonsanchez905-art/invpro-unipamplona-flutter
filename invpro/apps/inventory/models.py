import uuid
import unicodedata

from django.db import models


def _sin_tildes(texto):
    """Elimina tildes y caracteres diacríticos de un texto."""
    nfkd = unicodedata.normalize("NFKD", texto)
    return "".join(c for c in nfkd if not unicodedata.combining(c))


class Categoria(models.Model):
    """Categoría de productos con prefijo SKU autogenerado."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nombre = models.CharField(max_length=100, unique=True)
    descripcion = models.TextField(blank=True)
    color_hex = models.CharField(max_length=7, default="#6B7280")
    prefijo_sku = models.CharField(max_length=3, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Categoría"
        ordering = ["-created_at"]

    def save(self, *args, **kwargs):
        if not self.prefijo_sku:
            limpio = _sin_tildes(self.nombre).replace(" ", "")
            self.prefijo_sku = limpio[:3].upper()
        super().save(*args, **kwargs)

    def __str__(self):
        return self.nombre


class Producto(models.Model):
    """Producto perteneciente a una categoría."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nombre = models.CharField(max_length=200)
    sku = models.CharField(max_length=20, unique=True, editable=False, blank=True)
    descripcion = models.TextField(blank=True)
    categoria = models.ForeignKey(
        Categoria, on_delete=models.PROTECT, related_name="productos"
    )
    stock_actual = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    stock_minimo = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    precio_unitario = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Producto"
        ordering = ["-created_at"]

    @property
    def tiene_alerta(self):
        """Retorna True si el stock actual es menor o igual al stock mínimo."""
        return self.stock_actual <= self.stock_minimo

    def __str__(self):
        return f"{self.nombre} ({self.sku or 'SKU pendiente'})"
