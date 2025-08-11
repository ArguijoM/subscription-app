
import 'dart:convert';       // para usar json.encode y json.decode
import 'dart:math';
import 'package:http/http.dart' as http;  // para usar http.post, etc.

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


Future<Map<String, dynamic>?> obtenerDetallesProductoStripe(String priceId) async {
  final url = Uri.parse("https://obtenerdetallesproductostripe-lxpplrf64a-uc.a.run.app");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'priceId': priceId}),
  );

  if (response.statusCode == 200) {

    final data = json.decode(response.body);
    print("Respuesta de Stripe:");
    print(json.encode(data));
    return {
      'productName': data['product']['name'],
      'description': data['product']['description'],
      'price': (data['price']['unit_amount'] / 100).toStringAsFixed(2),
      'interval': data['interval'],
      'intervalCount': data['interval_count'],
    };
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

