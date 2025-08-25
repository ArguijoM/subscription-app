import 'package:flutter/material.dart';
import '../main.dart'; // Importa tu MainPage

class ResumenCompraScreen extends StatelessWidget {
  final String productName;
  final String description;
  final String price;
  final String cardBrand;
  final String cardLast4;
  final double priceAmount;
  final String? interval;
  final int? intervalCount;

  const ResumenCompraScreen({
    Key? key,
    required this.productName,
    required this.description,
    required this.price,
    required this.cardBrand,
    required this.priceAmount,
    required this.cardLast4,
    this.interval,
    this.intervalCount,
  }) : super(key: key);

  String getReadableInterval() {
    if (interval == null || intervalCount == null) return 'Pago único';
    final map = {
      'day': 'día',
      'week': 'semana',
      'month': 'mes',
      'year': 'año',
    };
    final unidad = map[interval] ?? interval!;
    return intervalCount == 1
        ? 'Cada $unidad'
        : 'Cada $intervalCount ${unidad}s';
  }

  void _mostrarConfirmacionYVolver(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compra realizada'),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(Duration(seconds: 2), () {
      // Navega a MainPage y elimina todo el stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainPage()),
            (route) => false,
      );
    });
  }

  String getFormattedPrice() {
    return '\$${priceAmount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resumen de Compra')),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Producto:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(productName),
            SizedBox(height: 12),
            Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(description),
            SizedBox(height: 12),
            Text('Precio:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(getFormattedPrice()),
            SizedBox(height: 24),
            Text('Método de Pago:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('$cardBrand **** **** **** $cardLast4'),
            SizedBox(height: 24),
            Text('Periodo:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(getReadableInterval()),
            SizedBox(height: 36),
            Center(
              child: ElevatedButton(
                onPressed: () => _mostrarConfirmacionYVolver(context),
                child: Text('Aceptar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
