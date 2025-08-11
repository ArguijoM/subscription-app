import 'package:flutter/material.dart';
import 'package:simple_app/pages/AgregarMetodoPagoScreen.dart';

class SubscriptionDetailsScreen extends StatelessWidget {
  final String productName;
  final String description;
  final String price;
  final String stripeCustomerId;
  final String? interval;
  final int? intervalCount;

  const SubscriptionDetailsScreen({
    Key? key,
    required this.productName,
    required this.description,
    required this.price,
    required this.stripeCustomerId,
    this.interval,
    this.intervalCount,
  }) : super(key: key);

  String getReadableInterval() {
    if (interval == null || intervalCount == null) {
      return 'Pago único';
    }

    final Map<String, String> intervalMap = {
      'day': 'día',
      'week': 'semana',
      'month': 'mes',
      'year': 'año',
    };

    final unidad = intervalMap[interval] ?? interval!;
    return intervalCount == 1
        ? 'Cada $unidad'
        : 'Cada $intervalCount ${unidad}s';
  }

  @override
  Widget build(BuildContext context) {
    String duracion = "$intervalCount ${interval == 'month' ? 'meses' : interval == 'year' ? 'años' : interval}s";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Suscripción'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Producto:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(productName),
            SizedBox(height: 16),
            Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(description),
            SizedBox(height: 16),
            Text('Precio:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('\$$price'),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgregarMetodoPagoScreen(
                        stripeCustomerId: stripeCustomerId,
                        productName: productName,
                        description: description,
                        price: price,
                      ),
                    ),
                  );
                },
                child: Text('Aceptar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

