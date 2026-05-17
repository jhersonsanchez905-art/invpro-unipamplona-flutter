from django.db import models


class HttpStatusCatalog(models.Model):
    """Catálogo de referencia de códigos HTTP usados por la API."""

    CATEGORY_CHOICES = [
        ("success", "Éxito"),
        ("redirect", "Redirección"),
        ("client_error", "Error del cliente"),
        ("server_error", "Error del servidor"),
    ]

    code = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=50)
    description_es = models.TextField()
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)

    class Meta:
        verbose_name = "Código HTTP"
        ordering = ["code"]

    def __str__(self):
        return f"{self.code} {self.name}"
