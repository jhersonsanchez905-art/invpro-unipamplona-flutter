from rest_framework import serializers

from apps.inventory.models import Categoria, Producto, StockAlerta
from apps.movements.models import Movimiento


class CategoriaSerializer(serializers.ModelSerializer):
    productos_count = serializers.SerializerMethodField()

    class Meta:
        model = Categoria
        fields = [
            "id",
            "nombre",
            "descripcion",
            "color_hex",
            "prefijo_sku",
            "is_active",
            "created_at",
            "productos_count",
        ]
        read_only_fields = ["id", "prefijo_sku", "created_at", "productos_count"]

    def get_productos_count(self, instance):
        return instance.productos.filter(is_active=True).count()


class ProductoListSerializer(serializers.ModelSerializer):
    tiene_alerta = serializers.SerializerMethodField()

    class Meta:
        model = Producto
        fields = [
            "id",
            "nombre",
            "sku",
            "categoria_id",
            "stock_actual",
            "stock_minimo",
            "precio_unitario",
            "tiene_alerta",
            "is_active",
            "created_at",
        ]

    def get_tiene_alerta(self, instance):
        return instance.tiene_alerta

    def to_representation(self, instance):
        representation = super().to_representation(instance)
        # categoria_id should be read-only and populated
        representation["categoria_id"] = str(instance.categoria_id) if instance.categoria_id else None
        return representation


class ProductoDetailSerializer(serializers.ModelSerializer):
    categoria = CategoriaSerializer(read_only=True)
    tiene_alerta = serializers.SerializerMethodField()

    class Meta:
        model = Producto
        fields = [
            "id",
            "nombre",
            "sku",
            "descripcion",
            "categoria",
            "stock_actual",
            "stock_minimo",
            "precio_unitario",
            "tiene_alerta",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "sku", "created_at", "updated_at"]

    def get_tiene_alerta(self, instance):
        return instance.tiene_alerta


class ProductoCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Producto
        fields = [
            "nombre",
            "descripcion",
            "categoria",
            "stock_minimo",
            "precio_unitario",
        ]

    def validate_stock_minimo(self, value):
        if value < 0:
            raise serializers.ValidationError("El stock mínimo no puede ser negativo.")
        return value

    def validate_precio_unitario(self, value):
        if value < 0:
            raise serializers.ValidationError("El precio unitario no puede ser negativo.")
        return value


class MovimientoSerializer(serializers.ModelSerializer):
    producto = serializers.SerializerMethodField()
    usuario = serializers.SerializerMethodField()

    class Meta:
        model = Movimiento
        fields = ["id", "tipo", "producto", "cantidad", "nota", "usuario", "created_at"]

    def get_producto(self, instance):
        return {
            "id": str(instance.producto.id),
            "sku": instance.producto.sku,
            "nombre": instance.producto.nombre,
        }

    def get_usuario(self, instance):
        return {
            "id": str(instance.usuario.id),
            "username": instance.usuario.username,
        }


class MovimientoCreateSerializer(serializers.Serializer):
    tipo = serializers.ChoiceField(choices=Movimiento.TIPO_CHOICES)
    producto_id = serializers.UUIDField()
    cantidad = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0.01)
    nota = serializers.CharField(max_length=500, required=False, allow_blank=True)

    def validate_tipo(self, value):
        if value not in ["entrada", "salida", "ajuste"]:
            raise serializers.ValidationError("El tipo de movimiento debe ser 'entrada', 'salida' o 'ajuste'.")
        return value


class StockAlertaSerializer(serializers.ModelSerializer):
    producto = serializers.SerializerMethodField()

    class Meta:
        model = StockAlerta
        fields = [
            "id",
            "producto",
            "stock_al_momento",
            "stock_minimo_al_momento",
            "resuelta",
            "created_at",
            "resolved_at",
        ]

    def get_producto(self, instance):
        return {
            "id": str(instance.producto.id),
            "sku": instance.producto.sku,
            "nombre": instance.producto.nombre,
        }
