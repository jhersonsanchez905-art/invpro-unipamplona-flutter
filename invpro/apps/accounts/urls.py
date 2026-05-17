from django.urls import path

from apps.accounts.views import (
    CheckEmailView,
    LoginView,
    LogoutView,
    MeView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    RegisterView,
    ResendOTPView,
    VerifyEmailView,
    VerifyLoginOTPView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="auth-register"),
    path("verify-email/", VerifyEmailView.as_view(), name="auth-verify-email"),
    path("login/", LoginView.as_view(), name="auth-login"),
    path("verify-otp/", VerifyLoginOTPView.as_view(), name="auth-verify-otp"),
    path("resend-otp/", ResendOTPView.as_view(), name="auth-resend-otp"),
    path("password-reset/", PasswordResetRequestView.as_view(), name="auth-password-reset"),
    path("password-reset/confirm/", PasswordResetConfirmView.as_view(), name="auth-password-reset-confirm"),
    path("me/", MeView.as_view(), name="auth-me"),
    path("logout/", LogoutView.as_view(), name="auth-logout"),
    path("check-email/", CheckEmailView.as_view(), name="auth-check-email"),
]
