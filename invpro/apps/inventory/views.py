from rest_framework import generics, serializers, status
from rest_framework.views import APIView
from rest_framework.decorators import action
from rest_framework.filters import OrderingFilter, SearchFilter
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet, ReadOnlyModelViewSet
from django_filters.rest_framework import DjangoFilterBackend

from apps.accounts.permissions import (
    EsAdmin,
    EsAuditor,
    EsVisualizador,
    PuedeCrearProducto,
    PuedeEliminarProducto,
)
from apps.inventory.models import Categoria, Producto, StockAlerta
from apps.inventory.serializers import (
    CategoriaSerializer,
    ProductoCreateSerializer,
    ProductoDetailSerializer,
    ProductoListSerializer,
    StockAlertaSerializer,
)
from apps.inventory.services import (
    actualizar_producto,
    crear_producto,
    eliminar_producto,
)


class CategoriaViewSet(ModelViewSet):
    queryset = Categoria.objects.filter(is_active=True).order_by("-created_at")
    serializer_class = CategoriaSerializer

    def get_permissions(self):
        if self.action in ["list", "retrieve"]:
            return [EsVisualizador()]
        elif self.action in ["create", "update", "partial_update"]:
            return [EsAdmin()]
        elif self.action == "destroy":
            return [EsAdmin()]
        return [IsAuthenticated()]

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_active = False
        instance.save(update_fields=["is_active"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class ProductoViewSet(ModelViewSet):
    queryset = Producto.objects.all().order_by("-created_at")
    filter_backends = [SearchFilter, OrderingFilter, DjangoFilterBackend]
    search_fields = ["nombre", "sku"]
    ordering_fields = ["nombre", "stock_actual", "precio_unitario", "created_at"]
    ordering = ["-created_at"]
    filterset_fields = {
        "categoria": ["exact"],
        "is_active": ["exact"],
    }

    def get_permissions(self):
        if self.action in ["list", "retrieve"]:
            return [EsVisualizador()]
        elif self.action == "create":
            return [PuedeCrearProducto()]
        elif self.action in ["update", "partial_update"]:
            return [PuedeCrearProducto()]
        elif self.action == "destroy":
            return [PuedeEliminarProducto()]
        return [IsAuthenticated()]

    def get_serializer_class(self):
        if self.action in ["list"]:
            return ProductoListSerializer
        elif self.action in ["retrieve"]:
            return ProductoDetailSerializer
        elif self.action in ["create", "update", "partial_update"]:
            return ProductoCreateSerializer
        return ProductoListSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        producto = crear_producto(
            nombre=data["nombre"],
            descripcion=data.get("descripcion", ""),
            categoria_id=str(data["categoria"].id),
            stock_minimo=data.get("stock_minimo", 0),
            precio_unitario=data.get("precio_unitario", 0),
            usuario=request.user,
        )

        output = ProductoDetailSerializer(producto)
        return Response(
            {"success": True, "data": output.data, "message": "Producto creado exitosamente."},
            status=status.HTTP_201_CREATED,
        )

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)

        datos = {k: v for k, v in serializer.validated_data.items()}
        # Convert categoria object to id for actualizar_producto
        if "categoria" in datos:
            datos["categoria_id"] = str(datos.pop("categoria").id)
        else:
            # Ensure categoria is explicitly included if partial update didn't change it
            pass

        producto = actualizar_producto(
            producto_id=str(instance.id),
            datos=datos,
            usuario=request.user,
        )

        output = ProductoDetailSerializer(producto)
        return Response(
            {"success": True, "data": output.data, "message": "Producto actualizado exitosamente."}
        )

    def partial_update(self, request, *args, **kwargs):
        kwargs["partial"] = True
        return self.update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        eliminar_producto(producto_id=str(instance.id), usuario=request.user)
        return Response(
            {"success": True, "message": "Producto eliminado exitosamente."},
            status=status.HTTP_200_OK,
        )

    @action(detail=True, methods=["get"], url_path="alertas")
    def alertas(self, request, pk=None):
        producto = self.get_object()
        alertas = StockAlerta.objects.filter(producto=producto).order_by("-created_at")
        serializer = StockAlertaSerializer(alertas, many=True)
        return Response(
            {"success": True, "data": serializer.data, "message": "Alertas de stock obtenidas."}
        )


class DashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from django.utils import timezone
        from django.db.models import Sum, Count
        from apps.movements.models import Movimiento

        today = timezone.now().date()

        total_productos = Producto.objects.filter(is_active=True).count()
        productos_alerta = Producto.objects.filter(
            is_active=True
        ).filter(stock_actual__lte=django_models.F('stock_minimo')).count()

        movimientos_hoy = Movimiento.objects.filter(
            created_at__date=today
        ).count()

        valor_inventario = Producto.objects.filter(
            is_active=True
        ).aggregate(
            total=Sum(django_models.ExpressionWrapper(
                django_models.F('stock_actual') * django_models.F('precio_unitario'),
                output_field=django_models.DecimalField()
            ))
        )['total'] or 0

        ultimos_movimientos = Movimiento.objects.select_related(
            'producto', 'usuario'
        ).order_by('-created_at')[:5]

        movimientos_data = [{
            'id': str(m.id),
            'tipo': m.tipo,
            'producto_sku': m.producto.sku,
            'producto_nombre': m.producto.nombre,
            'cantidad': float(m.cantidad),
            'usuario': m.usuario.username,
            'fecha': m.created_at.strftime('%d/%m/%Y %H:%M'),
        } for m in ultimos_movimientos]

        return Response({
            'success': True,
            'data': {
                'total_productos': total_productos,
                'productos_alerta': productos_alerta,
                'movimientos_hoy': movimientos_hoy,
                'valor_inventario': float(valor_inventario),
                'ultimos_movimientos': movimientos_data,
            }
        })


class StockAlertaViewSet(ReadOnlyModelViewSet):
    queryset = StockAlerta.objects.all().order_by("-created_at")
    serializer_class = StockAlertaSerializer
    permission_classes = [EsAuditor]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = {
        "resuelta": ["exact"],
    }
