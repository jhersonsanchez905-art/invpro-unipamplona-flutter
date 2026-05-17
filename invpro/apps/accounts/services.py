import secrets
import logging
from datetime import timedelta

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.mail import send_mail
from django.contrib.auth.hashers import check_password
from django.utils import timezone
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import CustomUser, OTPCode, Session

logger = logging.getLogger(__name__)


def generate_otp(user: CustomUser, purpose: str) -> str:
    """
    Genera un código OTP de 6 dígitos para un usuario y propósito específicos.
    Invalida OTPs previos del mismo usuario y propósito.
    Retorna el código en texto plano para ser enviado al usuario.
    """
    OTPCode.objects.filter(
        user=user, purpose=purpose, is_used=False
    ).update(is_used=True)

    code = f"{secrets.randbelow(1_000_000):06d}"

    OTPCode.objects.create(
        user=user,
        code=code,
        purpose=purpose,
        expires_at=timezone.now() + timedelta(minutes=5),
    )

    return code


def send_otp_email(user: CustomUser, code: str, purpose: str) -> None:
    """
    Envía un correo electrónico con el código OTP al usuario.
    El asunto y el cuerpo varían según el propósito del código.
    """
    subjects = {
        "login": "Código de verificación — InvPro",
        "verify_email": "Verifica tu correo — InvPro",
        "reset_password": "Restablecer contraseña — InvPro",
    }

    subject = subjects.get(purpose, "Código de verificación — InvPro")

    message = (
        f"Hola {user.first_name or user.username},\n\n"
        f"Tu código de verificación es:\n\n"
        f"   {code}\n\n"
        f"Este código expira en 5 minutos.\n\n"
        f"Si no solicitaste este código, ignora este mensaje.\n\n"
        f"— El equipo de InvPro"
    )

    send_mail(
        subject=subject,
        message=message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=False,
    )


def verify_otp(user: CustomUser, code: str, purpose: str) -> bool:
    """
    Verifica un código OTP para un usuario y propósito específicos.
    Busca el OTP más reciente no usado; si es válido y coincide, lo marca
    como usado y retorna True. En cualquier otro caso retorna False.
    """
    otp = (
        OTPCode.objects.filter(user=user, purpose=purpose, is_used=False)
        .order_by("-created_at")
        .first()
    )

    if otp is None:
        return False

    if not otp.is_valid():
        return False

    if not otp.verify(code):
        return False

    return True


def validate_password_strength(password: str) -> None:
    """
    Valida que la contraseña cumpla con los requisitos mínimos de seguridad.
    Lanza ValidationError con mensaje descriptivo en español si no cumple.
    """
    if len(password) < 8:
        raise ValidationError(
            "La contraseña debe tener al menos 8 caracteres."
        )
    if not any(c.isupper() for c in password):
        raise ValidationError(
            "La contraseña debe contener al menos una letra mayúscula."
        )
    if not any(c.islower() for c in password):
        raise ValidationError(
            "La contraseña debe contener al menos una letra minúscula."
        )
    if not any(c.isdigit() for c in password):
        raise ValidationError(
            "La contraseña debe contener al menos un número."
        )
    special = r"!@#$%^&*()_+-=[]{}|;:,.<>?"
    if not any(c in special for c in password):
        raise ValidationError(
            "La contraseña debe contener al menos un carácter especial "
            f"({special})."
        )


def register_user(
    username: str,
    email: str,
    password: str,
    first_name: str = "",
    last_name: str = "",
    fecha_nacimiento=None,
) -> CustomUser:
    """
    Registra un nuevo usuario en el sistema.
    Valida la contraseña, verifica unicidad de email y username,
    crea el usuario, genera un OTP de verificación de email y lo envía.
    Retorna el usuario creado.
    """
    validate_password_strength(password)

    if CustomUser.objects.filter(email__iexact=email).exists():
        raise ValidationError("Ya existe un usuario con este correo electrónico.")

    if CustomUser.objects.filter(username=username).exists():
        raise ValidationError("Ya existe un usuario con este nombre de usuario.")

    user = CustomUser.objects.create_user(
        username=username,
        email=email,
        password=password,
        first_name=first_name,
        last_name=last_name,
        fecha_nacimiento=fecha_nacimiento,
        rol="visualizador",
        email_verified=False,
    )

    code = generate_otp(user, "verify_email")
    send_otp_email(user, code, "verify_email")

    return user


def login_user(
    email: str,
    password: str,
    ip: str = "",
    user_agent: str = "",
) -> dict:
    """
    Autentica un usuario por email y contraseña.
    Gestiona bloqueos por intentos fallidos, verifica que el email
    esté confirmado y genera un OTP de inicio de sesión.
    Retorna un diccionario con user_id y requires_otp.
    """
    try:
        user = CustomUser.objects.get(email__iexact=email)
    except CustomUser.DoesNotExist:
        raise ValidationError(
            "Credenciales inválidas. Verifica tu correo y contraseña."
        )

    if user.esta_bloqueado():
        remaining = user.locked_until - timezone.now()
        minutes = int(remaining.total_seconds() // 60)
        seconds = int(remaining.total_seconds() % 60)
        raise ValidationError(
            f"Cuenta bloqueada. Intenta de nuevo en {minutes} minutos y "
            f"{seconds} segundos."
        )

    if not check_password(password, user.password):
        user.failed_login_attempts += 1
        if user.failed_login_attempts >= 5:
            user.locked_until = timezone.now() + timedelta(minutes=15)
        user.save(update_fields=["failed_login_attempts", "locked_until"])
        raise ValidationError(
            "Credenciales inválidas. Verifica tu correo y contraseña."
        )

    user.failed_login_attempts = 0
    user.save(update_fields=["failed_login_attempts"])

    if not user.email_verified:
        raise ValidationError(
            "Debes verificar tu correo electrónico antes de iniciar sesión."
        )

    code = generate_otp(user, "login")
    send_otp_email(user, code, "login")

    return {"user_id": str(user.id), "requires_otp": True}


def verify_login_otp(
    user_id: str,
    code: str,
    ip: str = "",
    user_agent: str = "",
) -> dict:
    """
    Verifica el OTP de inicio de sesión, genera los tokens JWT
    y crea un registro de sesión activa.
    Retorna un diccionario con los tokens access y refresh.
    """
    try:
        user = CustomUser.objects.get(id=user_id)
    except (CustomUser.DoesNotExist, ValueError):
        raise ValidationError("Código inválido o expirado.")

    if not verify_otp(user, code, "login"):
        raise ValidationError("Código inválido o expirado.")

    refresh = RefreshToken.for_user(user)
    access_token = refresh.access_token

    Session.objects.create(
        user=user,
        ip_address=ip or None,
        user_agent=user_agent,
        jwt_jti=str(access_token["jti"]),
        expires_at=timezone.now() + timedelta(days=7),
    )

    return {
        "access": str(access_token),
        "refresh": str(refresh),
    }


def request_password_reset(email: str) -> None:
    """
    Inicia el flujo de restablecimiento de contraseña.
    Si el email existe, genera un OTP y lo envía por correo.
    Si no existe, retorna silenciosamente para no revelar la existencia
    de cuentas registradas.
    """
    try:
        user = CustomUser.objects.get(email__iexact=email)
    except CustomUser.DoesNotExist:
        return

    code = generate_otp(user, "reset_password")
    send_otp_email(user, code, "reset_password")


def reset_password(email: str, code: str, new_password: str) -> bool:
    """
    Restablece la contraseña de un usuario verificando el OTP primero.
    Valida la nueva contraseña, la actualiza e invalida todas las sesiones
    activas del usuario.
    Retorna True si el restablecimiento fue exitoso.
    """
    try:
        user = CustomUser.objects.get(email__iexact=email)
    except CustomUser.DoesNotExist:
        raise ValidationError(
            "No se pudo restablecer la contraseña. Verifica los datos ingresados."
        )

    if not verify_otp(user, code, "reset_password"):
        raise ValidationError(
            "Código inválido o expirado."
        )

    validate_password_strength(new_password)

    user.set_password(new_password)
    user.sessions.update(is_active=False)
    user.save()

    return True
