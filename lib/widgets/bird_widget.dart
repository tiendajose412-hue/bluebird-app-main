import 'package:flutter/material.dart';

class BirdWidget extends StatelessWidget {
  final double? width; // Ancho personalizable
  final double? height; // Alto personalizable
  final BoxFit fit; // Cómo se ajusta la imagen
  final bool showShadow; // Si mostrar sombra o no
  final double shadowBlur; // Intensidad de la sombra
  final Color shadowColor; // Color de la sombra

  const BirdWidget({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.showShadow = true,
    this.shadowBlur = 10.0,
    this.shadowColor = const Color.fromARGB(66, 0, 0, 0),
  });

  @override
  Widget build(BuildContext context) {
    // Si no se especifica tamaño, usar valores por defecto responsivos
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultSize = screenWidth * 0.4; // 40% del ancho de pantalla

    final finalWidth = width ?? defaultSize;
    final finalHeight = height ?? defaultSize;

    // VERSIÓN SIMPLE - Solo Image.asset con errorBuilder
    Widget imageWidget = Image.asset(
      'assets/images/bird.png',
      width: finalWidth,
      height: finalHeight,
      fit: fit,
      // SOLO errorBuilder - loadingBuilder NO es necesario para assets locales
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: finalWidth,
          height: finalHeight,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                color: Colors.blue,
                size: finalWidth * 0.3,
              ),
              SizedBox(height: 8),
              Text(
                'Imagen no encontrada',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'bird.png',
                style: TextStyle(
                  color: Colors.blue.withOpacity(0.7),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // Si se requiere sombra, envolver en Container con decoración
    if (showShadow) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: shadowBlur,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageWidget,
        ),
      );
    }

    return imageWidget;
  }
}
