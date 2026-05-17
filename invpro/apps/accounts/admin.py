from django.contrib import admin

from .models import AuditLog, CustomUser, OTPCode, Session


@admin.register(CustomUser)
class CustomUserAdmin(admin.ModelAdmin):
    list_display = ("email", "username", "rol", "email_verified", "is_active", "date_joined")
    list_filter = ("rol", "email_verified", "is_active")


@admin.register(OTPCode)
class OTPCodeAdmin(admin.ModelAdmin):
    list_display = ("user", "purpose", "is_used", "expires_at", "created_at")
    list_filter = ("purpose", "is_used")


@admin.register(Session)
class SessionAdmin(admin.ModelAdmin):
    list_display = ("user", "ip_address", "is_active", "expires_at", "created_at")
    list_filter = ("is_active",)


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ("action", "entity", "user", "http_status", "created_at")
    list_filter = ("action", "entity")

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def get_readonly_fields(self, request, obj=None):
        return [f.name for f in self.model._meta.fields]
