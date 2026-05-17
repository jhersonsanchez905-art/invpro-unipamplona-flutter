from datetime import datetime

from django.http import HttpResponse
from rest_framework import status
from rest_framework.views import APIView

from apps.accounts.permissions import PuedeVerReportes
from apps.inventory.reports import reporte_inventario_actual, reporte_movimientos, reporte_por_categoria


class ReporteView(APIView):
    """Genera y descarga reportes PDF según el tipo solicitado."""

    permission_classes = [PuedeVerReportes]

    def get(self, request, tipo):
        fecha_inicio = request.query_params.get("fecha_inicio")
        fecha_fin = request.query_params.get("fecha_fin")

        if tipo == "inventario":
            pdf_buffer = reporte_inventario_actual(request.user)
        elif tipo == "movimientos":
            if not fecha_inicio or not fecha_fin:
                return HttpResponse(
                    "fecha_inicio y fecha_fin son requeridos para movimientos.",
                    status=status.HTTP_400_BAD_REQUEST,
                )
            pdf_buffer = reporte_movimientos(fecha_inicio, fecha_fin, request.user)
        elif tipo == "categorias":
            pdf_buffer = reporte_por_categoria(request.user)
        else:
            return HttpResponse("Tipo de reporte no válido.", status=status.HTTP_400_BAD_REQUEST)

        filename = f"{tipo}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        response = HttpResponse(pdf_buffer.getvalue(), content_type="application/pdf")
        response["Content-Disposition"] = f'attachment; filename="{filename}"'
        return response
