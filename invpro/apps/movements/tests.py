from django.core.exceptions import ValidationError
from rest_framework.test import APITestCase
from rest_framework import status
from apps.accounts.models import CustomUser
from apps.inventory.models import Categoria, Producto
from apps.movements.services import registrar_movimiento


class MovimientoTests(APITestCase):
    def setUp(self):
        self.admin = CustomUser.objects.create_user(
            username="admin",
            email="admin@test.com",
            password="InvPro123!",
            rol="admin",
            email_verified=True,
        )
        self.categoria = Categoria.objects.create(
            nombre="Test", prefijo_sku="TES"
        )
        self.producto = Producto.objects.create(
            nombre="Producto Test",
            sku="INV-TES-0001",
            categoria=self.categoria,
            stock_actual=100,
            stock_minimo=10,
            precio_unitario=50000,
        )

    def test_entrada_suma_stock(self):
        registrar_movimiento(
            "entrada", str(self.producto.id), 50, self.admin
        )
        self.producto.refresh_from_db()
        self.assertEqual(self.producto.stock_actual, 150)

    def test_salida_resta_stock(self):
        registrar_movimiento(
            "salida", str(self.producto.id), 30, self.admin
        )
        self.producto.refresh_from_db()
        self.assertEqual(self.producto.stock_actual, 70)

    def test_salida_stock_insuficiente(self):
        with self.assertRaises(ValidationError):
            registrar_movimiento(
                "salida", str(self.producto.id), 200, self.admin
            )

    def test_ajuste_reemplaza_stock(self):
        registrar_movimiento(
            "ajuste", str(self.producto.id), 75, self.admin
        )
        self.producto.refresh_from_db()
        self.assertEqual(self.producto.stock_actual, 75)

    def test_cantidad_cero_invalida(self):
        with self.assertRaises(ValidationError):
            registrar_movimiento(
                "entrada", str(self.producto.id), 0, self.admin
            )
