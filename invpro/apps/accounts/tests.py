from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status
from apps.accounts.models import CustomUser
from apps.accounts.services import (
    validate_password_strength,
    register_user,
)


class PasswordValidationTests(TestCase):
    def test_weak_password_too_short(self):
        with self.assertRaises(Exception):
            validate_password_strength("Ab1!")

    def test_weak_password_no_uppercase(self):
        with self.assertRaises(Exception):
            validate_password_strength("abcd1234!")

    def test_weak_password_no_special(self):
        with self.assertRaises(Exception):
            validate_password_strength("Abcd1234")

    def test_strong_password_passes(self):
        validate_password_strength("InvPro123!")


class RegisterAPITests(APITestCase):
    def test_register_success(self):
        data = {
            "username": "testuser",
            "email": "test@unipamplona.edu.co",
            "password": "InvPro123!",
            "password_confirm": "InvPro123!",
        }
        response = self.client.post(
            "/api/v1/auth/register/", data, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data["success"])

    def test_register_duplicate_email(self):
        CustomUser.objects.create_user(
            username="existing",
            email="existing@test.com",
            password="InvPro123!",
        )
        data = {
            "username": "newuser",
            "email": "existing@test.com",
            "password": "InvPro123!",
            "password_confirm": "InvPro123!",
        }
        response = self.client.post(
            "/api/v1/auth/register/", data, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_password_mismatch(self):
        data = {
            "username": "testuser2",
            "email": "test2@test.com",
            "password": "InvPro123!",
            "password_confirm": "Different123!",
        }
        response = self.client.post(
            "/api/v1/auth/register/", data, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_check_email_available(self):
        response = self.client.get(
            "/api/v1/auth/check-email/?email=new@test.com"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["data"]["available"])

    def test_check_email_taken(self):
        CustomUser.objects.create_user(
            username="taken",
            email="taken@test.com",
            password="InvPro123!",
        )
        response = self.client.get(
            "/api/v1/auth/check-email/?email=taken@test.com"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data["data"]["available"])


class PasswordResetAPITests(APITestCase):
    def test_password_reset_request_always_200(self):
        response = self.client.post(
            "/api/v1/auth/password-reset/",
            {"email": "nonexistent@test.com"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["success"])


class AuthRoleTests(APITestCase):
    def setUp(self):
        self.superadmin = CustomUser.objects.create_user(
            username="sa",
            email="sa@test.com",
            password="InvPro123!",
            rol="superadmin",
            email_verified=True,
        )
        self.admin = CustomUser.objects.create_user(
            username="admin",
            email="admin@test.com",
            password="InvPro123!",
            rol="admin",
            email_verified=True,
        )

    def test_me_endpoint_requires_auth(self):
        response = self.client.get("/api/v1/auth/me/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_me_endpoint_returns_user(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get("/api/v1/auth/me/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["data"]["email"], "admin@test.com")
