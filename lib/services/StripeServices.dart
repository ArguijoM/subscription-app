import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'FirebaseServices.dart';

final FirestoreService _firestoreService = FirestoreService();

Future<String?> crearClienteStripe(String email,String user) async {
  final url = Uri.parse('https://crearclientestripe-lxpplrf64a-uc.a.run.app');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'email': email,
      'name':user,}),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['customerId'];
  } else {
    print('Error al crear cliente Stripe: ${response.body}');
    return null;
  }
}


Future<Map<String, dynamic>?> obtenerDetallesProductoStripe(String productId) async {
  final url = Uri.parse("https://obtenerdetallesproductostripe-lxpplrf64a-uc.a.run.app");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'productId': productId}),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print("Respuesta de Stripe: $data");
    return data;
  } else {
    print("Error al obtener detalles del producto: ${response.body}");
    return null;
  }
}

Future<Map<String, dynamic>?> crearSuscripcionStripe(String customerId, String priceId) async {
  final url = Uri.parse('https://crearsuscripcion-lxpplrf64a-uc.a.run.app');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'customerId': customerId,
      'priceId': priceId,
    }),
  );

  if (response.statusCode == 200) {
    print(response.body);
    return json.decode(response.body);
  } else {
    print('Error al crear suscripción: ${response.body}');
    return null;
  }
}

Future<Map<String, dynamic>?> actualizarMetodoPagoSuscripcion(
    String customerId, String subscriptionId, String paymentMethodId) async {

  // URL oficial de la función en Firebase
  final url = Uri.parse(
      'https://us-central1-subscription-backend-84738.cloudfunctions.net/actualizarMetodoPagoSuscripcion'
  );

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'customerId': customerId,
      'subscriptionId': subscriptionId,
      'paymentMethodId': paymentMethodId,
    }),
  );

  if (response.statusCode == 200) {
    print("Respuesta de Firebase: ${response.body}");
    return json.decode(response.body);
  } else {
    print("Error en actualizarMetodoPagoSuscripcion: ${response.body}");
    return null;
  }
}

Future<Map<String, dynamic>?> actualizarSuscripcion(String userId,String subscriptionId) async {
  try {
    final url = Uri.parse('https://obtenerdetallessuscripcion-lxpplrf64a-uc.a.run.app');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'subscriptionId': subscriptionId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final currentPeriodStart = data['current_period_start'].toString();
      final currentPeriodEnd = data['current_period_end'].toString();
      final status = data['status'];

      // Usar FirebaseServices para actualizar Firestore
      await _firestoreService.actualizarFechasSuscripcionUsuario(
        userId: userId,
        currentPeriodStart: currentPeriodStart,
        currentPeriodEnd: currentPeriodEnd,
        status:status
      );
    } else {
      print('Error al obtener detalles de la suscripción: ${response.body}');
    }
  } catch (e) {
    print('Error en actualizarSuscripcion: $e');
  }
}

