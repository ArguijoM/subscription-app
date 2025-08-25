import 'package:flutter/material.dart';
import 'AgregarMetodoPagoScreen.dart';

class DetalleSuscripcionScreen extends StatefulWidget {
  final String stripeCustomerId;
  final String productName;
  final String description;
  final List<Map<String, dynamic>> precios; // amount, interval, interval_count, priceId

  const DetalleSuscripcionScreen({
    Key? key,
    required this.stripeCustomerId,
    required this.productName,
    required this.description,
    required this.precios,
  }) : super(key: key);

  @override
  State<DetalleSuscripcionScreen> createState() => _DetalleSuscripcionScreenState();
}

class _DetalleSuscripcionScreenState extends State<DetalleSuscripcionScreen> {
  int? seleccionadoIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona un plan")),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // dos columnas
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9, // aumenta el alto para evitar overflow
              ),
              itemCount: widget.precios.length,
              itemBuilder: (context, index) {
                final precio = widget.precios[index];
                final bool seleccionado = seleccionadoIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      seleccionadoIndex = index;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: seleccionado ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: seleccionado ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.productName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "\$${(precio['unit_amount'] / 100).toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${precio['interval_count']} ${precio['interval']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: seleccionadoIndex != null
                  ? () {
                final precioSeleccionado = widget.precios[seleccionadoIndex!];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgregarMetodoPagoScreen(
                      stripeCustomerId: widget.stripeCustomerId,
                      productName: widget.productName,
                      description: widget.description,
                      price: precioSeleccionado['priceId'],
                      priceAmount: precioSeleccionado['unit_amount'] / 100,
                      interval: precioSeleccionado['interval'],
                      intervalCount: precioSeleccionado['interval_count'],
                    ),
                  ),
                );
              }
                  : null,
              child: const Text("Continuar"),
            ),
          )
        ],
      ),
    );
  }
}