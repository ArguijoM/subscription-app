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
  final String price;       // ID del precio (price_xxx)
  final double priceAmount; // monto en unidades (no centavos)
  final String? interval;
  final int? intervalCount;
  final String? subscriptionId; // NUEVO: id de suscripción previa (opcional)

  AgregarMetodoPagoScreen({
    Key? key,
    required this.stripeCustomerId,
    required this.productName,
    required this.description,
    required this.price,
    required this.priceAmount,
    this.interval,
    this.intervalCount,
    this.subscriptionId,
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
        const SnackBar(content: Text('Por favor, completa los datos de la tarjeta')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Crear método de pago en Stripe
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(),
          ),
        ),
      );

      final last4 = paymentMethod.card?.last4 ?? '****';
      final brand = paymentMethod.card?.brand ?? 'Tarjeta';

      // 2. Asociar método de pago al cliente en backend
      final responseAsociar = await http.post(
        Uri.parse('https://asociarmetodopago-lxpplrf64a-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': widget.stripeCustomerId,
          'paymentMethodId': paymentMethod.id,
        }),
      );

      if (responseAsociar.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al asociar método de pago')),
        );
        setState(() => _loading = false);
        return;
      }

      // 3. Actualizar suscripción o crear nueva según subscriptionId
      Map<String, dynamic>? subscription;

      if (widget.subscriptionId != null) {
        // Actualizar metodo de pago en suscripción existente
        final responseActualizar = await http.post(
          Uri.parse('https://actualizarmetodopagosuscripcion-lxpplrf64a-uc.a.run.app'), // Cambia URL por la real
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'subscriptionId': widget.subscriptionId,
            'paymentMethodId': paymentMethod.id,
            'customerId': widget.stripeCustomerId,
          }),

        );

        print("Respuesta de la actualización de suscripcion");
        print(json.decode(responseActualizar.body));

        if (responseActualizar.statusCode == 200) {
          subscription = json.decode(responseActualizar.body);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar la suscripción')),
          );
          setState(() => _loading = false);
          return;
        }
      } else {
        // Crear suscripción nueva
        subscription = await crearSuscripcionStripe(
          widget.stripeCustomerId,
          widget.price,
        );

        if (subscription == null || subscription['subscriptionId'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear suscripción')),
          );
          setState(() => _loading = false);
          return;
        }
      }

      // 4. Guardar datos en Firestore
      await firestoreService.actualizarSuscripcionUsuario(
        widget.stripeCustomerId,
        subscription!['subscriptionId'],
        subscription['status'] ?? 'unknown',
        subscription['current_period_start'],
        subscription['current_period_end'],
      );

      // 5. Navegar a resumen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResumenCompraScreen(
            productName: widget.productName,
            description: widget.description,
            price: widget.price,
            priceAmount: widget.priceAmount.toDouble(),
            cardBrand: brand,
            cardLast4: last4,
            interval: widget.interval,
            intervalCount: widget.intervalCount,
          ),
        ),
      );
    } catch (e) {
      print("Stripe error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar tarjeta')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar método de pago')),
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
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _guardarMetodoPago,
              child: const Text('Asociar Tarjeta'),
            ),
          ],
        ),
      ),
    );
  }
}
