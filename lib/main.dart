import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:simple_app/firebase_options.dart';
import 'package:simple_app/services/FirebaseServices.dart';
import 'package:simple_app/services/StripeServices.dart';
import 'package:simple_app/pages/DetalleSuscripcionScreen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );
  Stripe.publishableKey = 'pk_test_51RsoLR3t0iGPKDQjReUetf7le0ly4SKS6jnmVbR0gRS0Rp0okqu3plDodZj0WrNxZZU0KIgE6x7qmoUukck8uj6k00bUZ6FhcI';
  await Stripe.instance.applySettings();
  runApp(MyApp());

}
final firestoreService = FirestoreService();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false; // Estado para la ruleta

  void _handleSubmit() async {
    setState(() {
      _isLoading = true; // Mostrar ruleta
    });

    final username = _usernameController.text;
    final email = _emailController.text;

    try {
      // Crear cliente en Stripe
      final stripeCustomerId = await crearClienteStripe(email, username);

      // Crear usuario en Firebase
      if (stripeCustomerId != null) {
        await firestoreService.agregarUsuario(email, username, stripeCustomerId);

        // Obtener detalles de producto
        final detalles = await obtenerDetallesProductoStripe('price_1RsrLn3t0iGPKDQj1fw4pW6P');

        if (detalles != null && mounted) {
          setState(() {
            _isLoading = false; // Ocultar ruleta antes de navegar
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubscriptionDetailsScreen(
                productName: detalles['productName'] ?? 'Sin nombre',
                description: detalles['description'] ?? 'Sin descripción',
                price: detalles['price'] ?? '0.00',
                stripeCustomerId: stripeCustomerId,
                interval: detalles['interval'],
                intervalCount: detalles['intervalCount'],
              ),
            ),
          );
        }
      } else {
        print('Error al crear cliente en Stripe');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear usuario'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),

            _isLoading
                ? CircularProgressIndicator() // Muestra ruleta
                : ElevatedButton(
              onPressed: _handleSubmit,
              child: Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

