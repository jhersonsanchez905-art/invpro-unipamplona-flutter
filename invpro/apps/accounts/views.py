from django.core.exceptions import ValidationError
from django.db import transaction
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import CustomUser
from apps.accounts.serializers import (
    CheckEmailSerializer,
    LoginSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterSerializer,
    UserSerializer,
    VerifyEmailSerializer,
    VerifyOTPSerializer,
)
from apps.accounts.services import (
    generate_otp,
    login_user,
    register_user,
    request_password_reset,
    reset_password,
    send_otp_email,
    verify_login_otp,
    verify_otp,
)


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        data.pop("password_confirm")

        try:
            user = register_user(**data)
        except ValidationError as e:
            return Response(
                {"success": False, "error": {"code": "VALIDATION_ERROR", "message": str(e)}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                "success": True,
                "data": {"user_id": str(user.id)},
                "message": "Cuenta creada. Revisa tu correo para verificarla.",
            },
            status=status.HTTP_201_CREATED,
        )


class VerifyEmailView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyEmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user = CustomUser.objects.get(id=serializer.validated_data["user_id"])
        except (CustomUser.DoesNotExist, ValueError):
            return Response(
                {"success": False, "error": {"code": "VALIDATION_ERROR", "message": "Código inválido o expirado."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if verify_otp(user, serializer.validated_data["code"], "verify_email"):
            user.email_verified = True
            user.save(update_fields=["email_verified"])
            return Response(
                {"success": True, "message": "Correo verificado exitosamente."},
                status=status.HTTP_200_OK,
            )

        return Response(
            {"success": False, "error": {"code": "VALIDATION_ERROR", "message": "Código inválido o expirado."}},
            status=status.HTTP_400_BAD_REQUEST,
        )


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        ip = request.META.get("REMOTE_ADDR", "")
        user_agent = request.META.get("HTTP_USER_AGENT", "")

        try:
            result = login_user(
                email=serializer.validated_data["email"],
                password=serializer.validated_data["password"],
                ip=ip,
                user_agent=user_agent,
            )
        except ValidationError as e:
            return Response(
                {"success": False, "error": {"code": "VALIDATION_ERROR", "message": str(e)}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                "success": True,
                "data": result,
                "message": "Código enviado a tu correo.",
            },
            status=status.HTTP_200_OK,
        )


class VerifyLoginOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        ip = request.META.get("REMOTE_ADDR", "")
        user_agent = request.META.get("HTTP_USER_AGENT", "")

        try:
            result = verify_login_otp(
                user_id=str(serializer.validated_data["user_id"]),
                code=serializer.validated_data["code"],
                ip=ip,
                user_agent=user_agent,
            )
        except ValidationError as e:
            return Response(
                {"success": False, "error": {"code": "VALIDATION_ERROR", "message": str(e)}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                "success": True,
                "data": result,
                "message": "Sesión iniciada exitosamente.",
            },
            status=status.HTTP_200_OK,
        )


class ResendOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        user_id = request.data.get("user_id")
        purpose = request.data.get("purpose")

        if not user_id or not purpose:
            return Response(
                {"success": False, "error": {"code": "VALIDATION_ERROR", "message": "user_id y purpose son requeridos."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = CustomUser.objects.get(id=user_id)
        except (CustomUser.DoesNotExist, ValueError):
            return Response(
                {"success": False, "error": {"code": "VALIDATION_ERROR", "message": "Usuario no encontrado."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if purpose not in ("login", "verify_email", "reset_password"):
            return Response(
                {"success": False, "error": {"code": "VALIDATION_ERROR", "message": "Propósito inválido."}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        code = generate_otp(user, purpose)
        send_otp_email(user, code, purpose)

        return Response(
            {"success": True, "message": "Código reenviado a tu correo."},
            status=status.HTTP_200_OK,
        )


class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        request_password_reset(serializer.validated_data["email"])

        return Response(
            {
                "success": True,
                "message": "Si el correo existe, recibirás un código en breve.",
            },
            status=status.HTTP_200_OK,
        )


class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            reset_password(
                email=serializer.validated_data["email"],
                code=serializer.validated_data["code"],
                new_password=serializer.validated_data["new_password"],
            )
        except ValidationError as e:
            return Response(
                {"success": False, "error": {"code": "VALIDATION_ERROR", "message": str(e)}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {"success": True, "message": "Contraseña restablecida exitosamente."},
            status=status.HTTP_200_OK,
        )


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(
            {"success": True, "data": serializer.data},
            status=status.HTTP_200_OK,
        )


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        request.user.sessions.filter(is_active=True).update(is_active=False)
        return Response(
            {"success": True, "message": "Sesión cerrada exitosamente."},
            status=status.HTTP_200_OK,
        )


class CheckEmailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        serializer = CheckEmailSerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)

        exists = CustomUser.objects.filter(
            email__iexact=serializer.validated_data["email"]
        ).exists()

        return Response(
            {"success": True, "data": {"available": not exists}},
            status=status.HTTP_200_OK,
        )
