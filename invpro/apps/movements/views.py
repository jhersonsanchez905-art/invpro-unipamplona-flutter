from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import GenericViewSet
from rest_framework.mixins import ListModelMixin, CreateModelMixin
from django_filters.rest_framework import DjangoFilterBackend

from apps.accounts.permissions import EsVisualizador, PuedeMovimiento
from apps.inventory.serializers import MovimientoSerializer, MovimientoCreateSerializer
from apps.movements.models import Movimiento
from apps.movements.services import registrar_movimiento


class MovimientoViewSet(GenericViewSet, ListModelMixin, CreateModelMixin):
    queryset = Movimiento.objects.all().order_by("-created_at")
    serializer_class = MovimientoSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = {
        "tipo": ["exact"],
        "producto": ["exact"],
    }
    ordering = ["-created_at"]

    def get_permissions(self):
        if self.action == "list":
            return [EsVisualizador()]
        elif self.action == "create":
            return [PuedeMovimiento()]
        return [IsAuthenticated()]

    def create(self, request, *args, **kwargs):
        serializer = MovimientoCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        movimiento = registrar_movimiento(
            tipo=data["tipo"],
            producto_id=str(data["producto_id"]),
            cantidad=data["cantidad"],
            usuario=request.user,
            nota=data.get("nota", ""),
        )

        output = MovimientoSerializer(movimiento)
        return Response(
            {"success": True, "data": output.data, "message": "Movimiento registrado exitosamente."},
            status=status.HTTP_201_CREATED,
        )
