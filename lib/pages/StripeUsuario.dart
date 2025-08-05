
import 'dart:convert';       // para usar json.encode y json.decode
import 'package:http/http.dart' as http;  // para usar http.post, etc.

Future<String?> crearClienteStripe(String email) async {
  final url = Uri.parse('https://us-central1-subscription-backend-84738.cloudfunctions.net/crearClienteStripe');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'email': email}),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['customerId'];
  } else {
    print('Error al crear cliente Stripe: ${response.body}');
    return null;
  }
}
