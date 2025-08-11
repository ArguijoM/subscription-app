import 'package:flutter/material.dart';

class ResumenCompraScreen extends StatelessWidget {
  final String productName;
  final String description;
  final String price;
  final String cardBrand;
  final String cardLast4;

  const ResumenCompraScreen({
    Key? key,
    required this.productName,
    required this.description,
    required this.price,
    required this.cardBrand,
    required this.cardLast4,
  }) : super(key: key);

  void _mostrarConfirmacionYVolver(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compra realizada'),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).popUntil((route) => route.isFirst); // Regresa a la pantalla principal
    });
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
            Text(price),
            SizedBox(height: 24),
            Text('Método de Pago:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('$cardBrand **** **** **** $cardLast4'),
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