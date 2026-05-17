import re

from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.validators import EmailValidator
from rest_framework import serializers

from apps.accounts.models import CustomUser
from apps.accounts.services import validate_password_strength


class RegisterSerializer(serializers.Serializer):
    username = serializers.CharField()
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    password_confirm = serializers.CharField(write_only=True)
    first_name = serializers.CharField(required=False, allow_blank=True, default="")
    last_name = serializers.CharField(required=False, allow_blank=True, default="")
    fecha_nacimiento = serializers.DateField(required=False, allow_null=True, default=None)

    def validate_email(self, value):
        validator = EmailValidator(message="El formato del correo electrónico no es válido.")
        try:
            validator(value)
        except DjangoValidationError as e:
            raise serializers.ValidationError(e.messages)
        return value

    def validate_password(self, value):
        try:
            validate_password_strength(value)
        except DjangoValidationError as e:
            raise serializers.ValidationError(e.messages)
        return value

    def validate(self, attrs):
        if attrs["password"] != attrs["password_confirm"]:
            raise serializers.ValidationError("Las contraseñas no coinciden.")
        return attrs

    def create(self, validated_data):
        validated_data.pop("password_confirm")
        return validated_data


class VerifyEmailSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()
    code = serializers.CharField(max_length=6)

    def validate_code(self, value):
        if not re.fullmatch(r"\d{6}", value):
            raise serializers.ValidationError("El código debe tener exactamente 6 dígitos.")
        return value


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True, allow_blank=False)
    password = serializers.CharField(required=True, allow_blank=False, write_only=True)


class VerifyOTPSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()
    code = serializers.CharField(max_length=6)

    def validate_code(self, value):
        if not re.fullmatch(r"\d{6}", value):
            raise serializers.ValidationError("El código debe tener exactamente 6 dígitos.")
        return value


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        validator = EmailValidator(message="El formato del correo electrónico no es válido.")
        try:
            validator(value)
        except DjangoValidationError as e:
            raise serializers.ValidationError(e.messages)
        return value


class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6)
    new_password = serializers.CharField(write_only=True)
    new_password_confirm = serializers.CharField(write_only=True)

    def validate_code(self, value):
        if not re.fullmatch(r"\d{6}", value):
            raise serializers.ValidationError("El código debe tener exactamente 6 dígitos.")
        return value

    def validate(self, attrs):
        if attrs["new_password"] != attrs["new_password_confirm"]:
            raise serializers.ValidationError("Las contraseñas no coinciden.")
        return attrs


class UserSerializer(serializers.ModelSerializer):
    edad = serializers.SerializerMethodField()
    created_at = serializers.DateTimeField(source="date_joined", read_only=True)

    class Meta:
        model = CustomUser
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "fecha_nacimiento",
            "edad",
            "rol",
            "email_verified",
            "created_at",
        ]
        read_only_fields = fields

    def get_edad(self, instance):
        return instance.edad


class CheckEmailSerializer(serializers.Serializer):
    email = serializers.EmailField()
