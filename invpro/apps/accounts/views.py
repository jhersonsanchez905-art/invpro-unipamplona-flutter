from django.core.exceptions import ValidationError
from django.db import transaction
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.viewsets import ReadOnlyModelViewSet, GenericViewSet
from rest_framework.mixins import ListModelMixin
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from apps.accounts.models import AuditLog, CustomUser
from apps.accounts.permissions import EsAuditor, EsAdmin
from apps.accounts.serializers import (
    AuditLogSerializer,
    CheckEmailSerializer,
    LoginSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterSerializer,
    UserSerializer,
    UsuarioListSerializer,
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


class AuditLogViewSet(ReadOnlyModelViewSet):
    """
    GET /api/v1/auditoria/       — lista paginada de logs
    GET /api/v1/auditoria/{id}/  — detalle de un log
    Solo admin y auditor pueden acceder.
    """
    queryset = AuditLog.objects.select_related("user").order_by("-created_at")
    serializer_class = AuditLogSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = {
        "action": ["exact"],
        "entity": ["exact"],
        "http_status": ["exact"],
    }
    search_fields = ["entity", "user__username"]
    ordering_fields = ["created_at", "action", "entity"]
    ordering = ["-created_at"]

    def get_permissions(self):
        return [EsAuditor()]

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return Response({"success": True, "data": serializer.data})


class UsuariosViewSet(GenericViewSet, ListModelMixin):
    """
    GET /api/v1/usuarios/  — lista de usuarios del sistema
    Solo admin y superior pueden listar.
    """
    queryset = CustomUser.objects.order_by("-date_joined")
    serializer_class = UsuarioListSerializer
    filter_backends = [SearchFilter, DjangoFilterBackend, OrderingFilter]
    search_fields = ["username", "email", "first_name", "last_name"]
    filterset_fields = {
        "rol": ["exact"],
        "is_active": ["exact"],
        "email_verified": ["exact"],
    }
    ordering_fields = ["date_joined", "username", "rol"]
    ordering = ["-date_joined"]

    def get_permissions(self):
        return [EsAdmin()]

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return Response({"success": True, "data": serializer.data})