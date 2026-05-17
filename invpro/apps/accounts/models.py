import uuid
from datetime import date

from django.contrib.auth.hashers import check_password, make_password
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class CustomUser(AbstractUser):
    """
    Modelo de usuario personalizado con UUID como PK y roles de acceso.
    """

    ROLES = [
        ("superadmin", "Super Administrador"),
        ("admin", "Administrador"),
        ("almacenista", "Almacenista"),
        ("auditor", "Auditor"),
        ("visualizador", "Visualizador"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, blank=False, null=False)
    fecha_nacimiento = models.DateField(null=True, blank=True)
    rol = models.CharField(max_length=20, choices=ROLES, default="visualizador")
    email_verified = models.BooleanField(default=False)
    failed_login_attempts = models.IntegerField(default=0)
    locked_until = models.DateTimeField(null=True, blank=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    class Meta:
        verbose_name = "Usuario"
        verbose_name_plural = "Usuarios"
        ordering = ["-date_joined"]

    @property
    def edad(self):
        """Calcula la edad a partir de fecha_nacimiento. Retorna None si no está definida."""
        if self.fecha_nacimiento is None:
            return None
        today = date.today()
        return today.year - self.fecha_nacimiento.year - (
            (today.month, today.day) < (self.fecha_nacimiento.month, self.fecha_nacimiento.day)
        )

    def es_superadmin(self):
        return self.rol == "superadmin"

    def es_admin(self):
        return self.rol in ("superadmin", "admin")

    def es_almacenista(self):
        return self.rol in ("superadmin", "admin", "almacenista")

    def es_auditor(self):
        return self.rol in ("superadmin", "admin", "auditor")

    def es_visualizador(self):
        return True

    def esta_bloqueado(self):
        if self.locked_until is None:
            return False
        return timezone.now() < self.locked_until


class OTPCode(models.Model):
    """
    Almacena códigos OTP hasheados para verificación de email,
    restablecimiento de contraseña e inicio de sesión.
    """

    PURPOSE_CHOICES = [
        ("login", "Inicio de sesión"),
        ("verify_email", "Verificación de email"),
        ("reset_password", "Restablecimiento de contraseña"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name="otp_codes")
    code = models.CharField(max_length=128)
    purpose = models.CharField(max_length=20, choices=PURPOSE_CHOICES)
    is_used = models.BooleanField(default=False)
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def save(self, *args, **kwargs):
        """Hashea el code en texto plano antes de guardar por primera vez."""
        if not self._state.adding:
            return super().save(*args, **kwargs)
        if not self.code.startswith("pbkdf2_sha256$"):
            self.code = make_password(self.code)
        return super().save(*args, **kwargs)

    def is_valid(self):
        """Retorna True si el código no ha sido usado y no ha expirado."""
        return not self.is_used and self.expires_at > timezone.now()

    def verify(self, plain_code):
        """
        Verifica un código en texto plano contra el hash almacenado.
        Si es válido, lo marca como usado y guarda. Retorna bool.
        """
        if not check_password(plain_code, self.code):
            return False
        self.is_used = True
        self.save(update_fields=["is_used"])
        return True


class Session(models.Model):
    """
    Registro de sesiones JWT activas para control y cierre de sesión remoto.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name="sessions")
    ip_address = models.GenericIPAddressField(null=True)
    user_agent = models.TextField(blank=True)
    jwt_jti = models.CharField(max_length=255, unique=True)
    is_active = models.BooleanField(default=True)
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class AuditLog(models.Model):
    """
    Registro de auditoría para acciones significativas del sistema.
    """

    ACTION_CHOICES = [
        ("login", "Login"),
        ("logout", "Logout"),
        ("failed_login", "Login fallido"),
        ("create", "Creación"),
        ("update", "Actualización"),
        ("delete", "Eliminación"),
        ("export", "Exportación"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        CustomUser, on_delete=models.SET_NULL, null=True, blank=True
    )
    action = models.CharField(max_length=30, choices=ACTION_CHOICES)
    entity = models.CharField(max_length=50, blank=True)
    entity_id = models.UUIDField(null=True, blank=True)
    changes = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    http_status = models.IntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Log de auditoría"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user"]),
            models.Index(fields=["entity"]),
        ]
