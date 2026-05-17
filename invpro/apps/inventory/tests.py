from rest_framework.test import APITestCase
from rest_framework import status
from apps.accounts.models import CustomUser
from apps.inventory.models import Categoria, Producto
from apps.inventory.services import crear_producto, generar_sku


class CategoriaTests(APITestCase):
    def setUp(self):
        self.admin = CustomUser.objects.create_user(
            username="admin",
            email="admin@test.com",
            password="InvPro123!",
            rol="admin",
            email_verified=True,
        )
        self.client.force_authenticate(user=self.admin)

    def test_crear_categoria(self):
        data = {
            "nombre": "Electrónica",
            "descripcion": "Equipos electrónicos",
            "color_hex": "#AD3333",
        }
        response = self.client.post(
            "/api/v1/categorias/", data, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_categoria_case_sensitive(self):
        Categoria.objects.create(nombre="Electrónica")
        data = {"nombre": "electrónica"}
        response = self.client.post(
            "/api/v1/categorias/", data, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)


class ProductoTests(APITestCase):
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
        self.client.force_authenticate(user=self.admin)

    def test_sku_auto_generado(self):
        producto = crear_producto(
            nombre="Laptop Test",
            categoria_id=str(self.categoria.id),
            usuario=self.admin,
        )
        self.assertTrue(producto.sku.startswith("INV-TES-"))

    def test_sku_secuencial(self):
        p1 = crear_producto(
            nombre="Producto 1",
            categoria_id=str(self.categoria.id),
            usuario=self.admin,
        )
        p2 = crear_producto(
            nombre="Producto 2",
            categoria_id=str(self.categoria.id),
            usuario=self.admin,
        )
        seq1 = int(p1.sku.split("-")[-1])
        seq2 = int(p2.sku.split("-")[-1])
        self.assertEqual(seq2, seq1 + 1)

    def test_visualizador_no_puede_crear(self):
        visualizador = CustomUser.objects.create_user(
            username="viz",
            email="viz@test.com",
            password="InvPro123!",
            rol="visualizador",
            email_verified=True,
        )
        self.client.force_authenticate(user=visualizador)
        data = {
            "nombre": "Test",
            "categoria_id": str(self.categoria.id),
        }
        response = self.client.post(
            "/api/v1/productos/", data, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class StockAlertaTests(APITestCase):
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
        self.client.force_authenticate(user=self.admin)

    def test_alerta_se_crea_bajo_stock(self):
        from apps.inventory.services import verificar_alertas_stock
        producto = Producto.objects.create(
            nombre="Alert Test",
            sku="INV-TES-TEST",
            categoria=self.categoria,
            stock_actual=3,
            stock_minimo=5,
            precio_unitario=1000,
        )
        verificar_alertas_stock(producto)
        from apps.inventory.models import StockAlerta
        self.assertTrue(
            StockAlerta.objects.filter(
                producto=producto, resuelta=False
            ).exists()
        )

    def test_alerta_se_resuelve_al_recuperar(self):
        from apps.inventory.services import verificar_alertas_stock
        from apps.inventory.models import StockAlerta
        producto = Producto.objects.create(
            nombre="Alert Test",
            sku="INV-TES-TEST2",
            categoria=self.categoria,
            stock_actual=2,
            stock_minimo=5,
            precio_unitario=1000,
        )
        verificar_alertas_stock(producto)
        self.assertTrue(
            StockAlerta.objects.filter(
                producto=producto, resuelta=False
            ).exists()
        )
        producto.stock_actual = 10
        producto.save()
        verificar_alertas_stock(producto)
        self.assertTrue(
            StockAlerta.objects.filter(
                producto=producto, resuelta=True
            ).exists()
        )
