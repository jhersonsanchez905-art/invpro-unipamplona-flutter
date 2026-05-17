"""Generación de reportes PDF con ReportLab para el módulo de inventario."""
from io import BytesIO
from datetime import datetime

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak

from apps.inventory.models import Producto, Categoria
from apps.movements.models import Movimiento


INVPRO_RED = colors.HexColor("#AD3333")


def _build_header(title, subtitle):
    """Construye la cabecera común de los reportes."""
    return [
        Paragraph(f'<font color="#AD3333" size=18><b>InvPro</b></font> <font color="#666666" size=12>— Universidad de Pamplona</font>', getSampleStyleSheet()["Normal"]),
        Spacer(1, 0.2 * inch),
        Paragraph(f'<font size=16><b>{title}</b></font>', getSampleStyleSheet()["Heading2"]),
        Paragraph(f'<font size=10 color="#666666">{subtitle}</font>', getSampleStyleSheet()["Normal"]),
        Spacer(1, 0.3 * inch),
    ]


def _generate_pdf(elements):
    """Genera y retorna un archivo PDF en memoria a partir de los elementos."""
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=letter, rightMargin=50, leftMargin=50, topMargin=50, bottomMargin=30)
    doc.build(elements)
    buffer.seek(0)
    return buffer


def reporte_inventario_actual(usuario) -> BytesIO:
    """Genera un PDF con el inventario actual de productos activos."""
    now = datetime.now().strftime("%d/%m/%Y %H:%M")
    subtitle = f"Fecha: {now}  —  Generado por: {usuario.username}"
    elements = _build_header("Reporte de Inventario Actual", subtitle)

    headers = ["SKU", "Nombre", "Categoría", "Stock Actual", "Stock Mínimo", "Precio", "Alerta"]
    data = [headers]

    productos = Producto.objects.filter(is_active=True).select_related("categoria").order_by("categoria__nombre", "nombre")

    for producto in productos:
        alerta = "⚠ Sí" if producto.tiene_alerta else "No"
        data.append([
            producto.sku,
            producto.nombre,
            producto.categoria.nombre,
            str(producto.stock_actual),
            str(producto.stock_minimo),
            f"${producto.precio_unitario}",
            alerta,
        ])

    table = Table(data, colWidths=[1.2 * inch, 2.0 * inch, 1.3 * inch, 1.1 * inch, 1.1 * inch, 1.0 * inch, 0.7 * inch])
    style = TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), INVPRO_RED),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("ALIGN", (1, 1), (1, -1), "LEFT"),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ])

    for i, producto in enumerate(productos, start=1):
        if producto.tiene_alerta:
            style.add("BACKGROUND", (0, i), (-1, i), colors.HexColor("#FFE4E4"))

    table.setStyle(style)
    elements.append(table)
    elements.append(Spacer(1, 0.2 * inch))

    return _generate_pdf(elements)


def reporte_movimientos(fecha_inicio, fecha_fin, usuario) -> BytesIO:
    """Genera un PDF con movimientos en un rango de fechas."""
    now = datetime.now().strftime("%d/%m/%Y %H:%M")
    subtitle = f"Periodo: {fecha_inicio} a {fecha_fin}  —  Generado por: {usuario.username}  —  {now}"
    elements = _build_header("Reporte de Movimientos", subtitle)

    headers = ["Fecha", "Tipo", "SKU", "Producto", "Cantidad", "Nota", "Usuario"]
    data = [headers]

    movimientos = Movimiento.objects.filter(
        created_at__date__gte=fecha_inicio,
        created_at__date__lte=fecha_fin,
    ).select_related("producto", "usuario").order_by("-created_at")

    for mv in movimientos:
        data.append([
            mv.created_at.strftime("%d/%m/%Y %H:%M"),
            mv.get_tipo_display(),
            mv.producto.sku,
            mv.producto.nombre,
            str(mv.cantidad),
            (mv.nota[:30] + "...") if len(mv.nota) > 30 else mv.nota,
            mv.usuario.username,
        ])

    table = Table(data, colWidths=[1.2 * inch, 0.9 * inch, 1.1 * inch, 1.8 * inch, 1.0 * inch, 1.7 * inch, 1.0 * inch])
    style = TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), INVPRO_RED),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("ALIGN", (3, 1), (3, -1), "LEFT"),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ])
    table.setStyle(style)
    elements.append(table)
    elements.append(Spacer(1, 0.3 * inch))

    # Resumen
    entradas = sum(mv.cantidad for mv in movimientos if mv.tipo == "entrada")
    salidas = sum(mv.cantidad for mv in movimientos if mv.tipo == "salida")
    ajustes = sum(mv.cantidad for mv in movimientos if mv.tipo == "ajuste")

    elements.append(Paragraph("<b>Resumen</b>", getSampleStyleSheet()["Heading3"]))
    elements.append(Paragraph(f"Total entradas: {entradas}", getSampleStyleSheet()["Normal"]))
    elements.append(Paragraph(f"Total salidas: {salidas}", getSampleStyleSheet()["Normal"]))
    elements.append(Paragraph(f"Total ajustes: {ajustes}", getSampleStyleSheet()["Normal"]))

    return _generate_pdf(elements)


def reporte_por_categoria(usuario) -> BytesIO:
    """Genera un PDF con productos agrupados por categoría activa."""
    now = datetime.now().strftime("%d/%m/%Y %H:%M")
    subtitle = f"Fecha: {now}  —  Generado por: {usuario.username}"
    elements = _build_header("Reporte por Categoría", subtitle)

    categorias = Categoria.objects.filter(is_active=True).order_by("nombre")

    for idx, categoria in enumerate(categorias):
        productos = Producto.objects.filter(categoria=categoria, is_active=True).order_by("nombre")
        elements.append(Paragraph(f"<b>{categoria.nombre}</b>", getSampleStyleSheet()["Heading3"]))

        headers = ["SKU", "Nombre", "Stock", "Mínimo", "Precio", "Alerta"]
        data = [headers]

        for producto in productos:
            alerta = "⚠ Sí" if producto.tiene_alerta else "No"
            data.append([
                producto.sku,
                producto.nombre,
                str(producto.stock_actual),
                str(producto.stock_minimo),
                f"${producto.precio_unitario}",
                alerta,
            ])

        if len(data) == 1:
            elements.append(Paragraph("Sin productos en esta categoría.", getSampleStyleSheet()["Normal"]))
            elements.append(Spacer(1, 0.2 * inch))
            continue

        table = Table(data, colWidths=[1.3 * inch, 2.4 * inch, 1.0 * inch, 1.0 * inch, 1.0 * inch, 0.7 * inch])
        style = TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), INVPRO_RED),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ("ALIGN", (1, 1), (1, -1), "LEFT"),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ])

        for i, producto in enumerate(productos, start=1):
            if producto.tiene_alerta:
                style.add("BACKGROUND", (0, i), (-1, i), colors.HexColor("#FFE4E4"))

        table.setStyle(style)
        elements.append(table)
        elements.append(Spacer(1, 0.3 * inch))

    return _generate_pdf(elements)
