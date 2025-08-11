import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ResumenCompraScreen.dart';
import '../services/FirebaseServices.dart';
import '../services/StripeServices.dart';

class AgregarMetodoPagoScreen extends StatefulWidget {
  final String stripeCustomerId;
  final String productName;
  final String description;
  final String price;

  AgregarMetodoPagoScreen({
    Key? key,
    required this.stripeCustomerId,
    required this.productName,
    required this.description,
    required this.price,
  }) : super(key: key);

  @override
  State<AgregarMetodoPagoScreen> createState() => _AgregarMetodoPagoScreenState();
}

class _AgregarMetodoPagoScreenState extends State<AgregarMetodoPagoScreen> {
  CardFieldInputDetails? _card;
  bool _loading = false;

  final firestoreService = FirestoreService();

  Future<void> _guardarMetodoPago() async {
    if (_card == null || !_card!.complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa los datos de la tarjeta')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(),
          ),
        ),
      );

      final last4 = paymentMethod.card?.last4 ?? '****';
      final brand = paymentMethod.card?.brand ?? 'Tarjeta';

      final response = await http.post(
        Uri.parse('https://asociarmetodopago-lxpplrf64a-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': widget.stripeCustomerId,
          'paymentMethodId': paymentMethod.id,
        }),
      );

      if (response.statusCode == 200) {
        // Crear suscripción en Stripe
        final subscription = await crearSuscripcionStripe(
          widget.stripeCustomerId,
          'price_1RsrLn3t0iGPKDQj1fw4pW6P',
        );

        if (subscription != null && subscription['subscriptionId'] != null) {
          // Guardar en Firestore
          await firestoreService.actualizarSuscripcionUsuario(
            widget.stripeCustomerId,
            subscription['subscriptionId'],
            subscription['status'] ?? 'unknown',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResumenCompraScreen(
                productName: widget.productName,
                description: widget.description,
                price: widget.price,
                cardBrand: brand,
                cardLast4: last4,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear suscripción')),
          );
        }
      } else {
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asociar método de pago')),
        );
      }
    } catch (e) {
      print("Stripe error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar tarjeta')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agregar método de pago')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CardField(
              onCardChanged: (card) {
                setState(() {
                  _card = card;
                });
              },
            ),
            SizedBox(height: 24),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _guardarMetodoPago,
              child: Text('Asociar Tarjeta'),
            ),
          ],
        ),
      ),
    );
  }
}
