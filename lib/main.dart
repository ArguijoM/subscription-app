import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:simple_app/firebase_options.dart';
import 'package:simple_app/pages/FirestoreServices.dart';
import 'package:simple_app/pages/StripeUsuario.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

  void _handleSubmit() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    print('Usuario: $username');
    print('Email: $email');

    // Paso 1: Crear cliente en Stripe
    final stripeCustomerId = await crearClienteStripe(email);

    if (stripeCustomerId != null) {
      // Paso 2: Guardar usuario en Firestore con customerId
      await firestoreService.agregarUsuario(email, username, stripeCustomerId);
      print("Usuario agregado correctamente");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario creado y vinculado con Stripe')),
      );
    } else {
      print("Error al crear cliente en Stripe");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear usuario Stripe')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Usuario',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleSubmit,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );

  }

}
