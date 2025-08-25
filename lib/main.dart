import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_app/services/FirebaseServices.dart';
import 'services/StripeServices.dart';
import 'pages/DetalleSuscripcionScreen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  Stripe.publishableKey = "pk_test_51RsoLR3t0iGPKDQjReUetf7le0ly4SKS6jnmVbR0gRS0Rp0okqu3plDodZj0WrNxZZU0KIgE6x7qmoUukck8uj6k00bUZ6FhcI"; // Reemplaza con la tuya
  await Stripe.instance.applySettings();
  runApp(MyApp());
}

// Servicio local de autenticación
class LocalAuthService {
  static const String _tokenKey = 'auth_token';

  static Future<void> login(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }
}

// Pantalla principal
class MainPage extends StatelessWidget {
  void _logout(BuildContext context) async {
    await LocalAuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pantalla Principal'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: Center(child: Text('Bienvenido a la app')),
    );
  }
}

// App principal
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Demo Login',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
    );
  }
}

// Pantalla de carga que verifica sesión
class SplashScreen extends StatefulWidget {
  final String productId = "prod_SoUK9qImoTyFlA";
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String productId = "prod_SoUK9qImoTyFlA"; // ID del producto

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    // Obtenemos el usuario desde Firestore usando el token
    final usuarioDoc = await FirestoreService.obtenerUsuarioPorToken(token);

    if (usuarioDoc == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    final subscription = usuarioDoc['subscription'] ?? {};
    final status = subscription['status'] ?? "";

    // Guardamos el status en SharedPreferences
    await prefs.setString('subscription_status', status);

    if (status != "active") {
      // Obtenemos detalles del producto desde Stripe
      final detalles = await obtenerDetallesProductoStripe("prod_SoUK9qImoTyFlA");


      if (detalles != null) {
        final producto = detalles['product'] ?? {};
        final precios = (detalles['prices'] as List<dynamic>? ?? []).map<Map<String, dynamic>>((p) {
          return {
            'priceId': p['id'],
            'unit_amount': p['unit_amount'],
            'currency': p['currency'],
            'interval': p['recurring']?['interval'],
            'interval_count': p['recurring']?['interval_count'],
          };
        }).toList();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleSuscripcionScreen(
              stripeCustomerId: usuarioDoc['stripeCustomerId'] ?? "",
              productName: producto['name'] ?? "",
              description: producto['description'] ?? "",
              precios: precios,
            ),
          ),
        );
        return;
      } else {
        // Manejo de error si no se obtienen detalles del producto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo obtener los detalles del producto")),
        );
      }
    }

    // Si la suscripción es active, vamos a la pantalla principal
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}


// Página de login
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        throw Exception("Email y contraseña requeridos");
      }

      // 1. Buscar usuario en Firestore
      final querySnapshot = await FirestoreService.usuarios
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception("Usuario no encontrado");
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;

      // 2. Validar contraseña (si la guardas en Firestore, no recomendado en producción)
      if (userData['password'] != password) {
        throw Exception("Contraseña incorrecta");
      }

      // 3. Leer subscription.status
      final subscription = userData['subscription'] as Map<String, dynamic>? ?? {};
      final status = subscription['status'] ?? "";

      if (subscription != null && subscription['id'] != null) {
        await actualizarSuscripcion(userDoc.id, subscription['id']);

      }

      // 4. Guardar status en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription_status', status);

      // 5. Redirigir según status
      if (status == 'active') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainPage()),
        );
      } else {
        // Obtener datos necesarios para DetalleSuscripcionScreen
        final stripeCustomerId = userData['stripeCustomerId'] ?? "";

        // ID fijo del producto en Stripe
        const productId = "prod_SoUK9qImoTyFlA";

        // Llamada a tu backend / Stripe para obtener detalles del producto
        final productDetails = await obtenerDetallesProductoStripe(productId);
        print("Enviando body: ${json.encode({'productId': productId})}");

        if (productDetails == null) throw Exception("Error al obtener detalles del producto");

        final producto = productDetails['product'] ?? {};
        final precios = (productDetails['prices'] as List<dynamic>? ?? []).map<Map<String, dynamic>>((p) {
          return {
            'priceId': p['id'],
            'unit_amount': p['unit_amount'],
            'currency': p['currency'],
            'interval': p['recurring']?['interval'],
            'interval_count': p['recurring']?['interval_count'],
          };
        }).toList();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleSuscripcionScreen(
              stripeCustomerId: stripeCustomerId,
              productName: producto['name'] ?? "",
              description: producto['description'] ?? "",
              precios: precios,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              enabled: !_isLoading,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
              enabled: !_isLoading,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Iniciar Sesión'),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: !_isLoading
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterPage()),
                );
              }
                  : null,
              child: Text(
                "¿No tienes cuenta? Registrate",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Página de registro
class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  bool _isLoading = false;

  void _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      if (_passwordController.text != _confirmPasswordController.text) {
        throw Exception("Las contraseñas no coinciden");
      }

      final nombre = _nombreController.text.trim();
      final apellido = _apellidoController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (nombre.isEmpty || apellido.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception("Todos los campos son requeridos");
      }

      // Crear cliente en Stripe
      final stripeCustomerId = await crearClienteStripe(email, "$nombre $apellido");
      if (stripeCustomerId == null) {
        throw Exception("No se pudo crear el cliente en Stripe");
      }

      // Guardar usuario en Firestore con el stripeCustomerId
      final docRef = await FirestoreService.agregarUsuario(
        nombre: nombre,
        apellido: apellido,
        email: email,
        password: password,
        stripeCustomerId: stripeCustomerId, // <-- Nuevo parámetro
      );

      print("Usuario creado en Firestore con Stripe ID: $stripeCustomerId");

      // Guardar datos en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', docRef.id);
      await prefs.setString('subscription_status', "");

      //Redirigir a DetalleSuscripcionScreen
      final detallesProducto = await obtenerDetallesProductoStripe("prod_SoUK9qImoTyFlA");
      if (detallesProducto == null) throw Exception("Error al obtener detalles del producto");

      final producto = detallesProducto['product'] ?? {};
      final precios = (detallesProducto['prices'] as List<dynamic>? ?? []).map<Map<String, dynamic>>((p) {
        return {
          'priceId': p['id'],
          'unit_amount': p['unit_amount'],
          'currency': p['currency'],
          'interval': p['recurring']?['interval'],
          'interval_count': p['recurring']?['interval_count'],
        };
      }).toList();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleSuscripcionScreen(
            stripeCustomerId: stripeCustomerId,
            productName: producto['name'] ?? "",
            description: producto['description'] ?? "",
            precios: precios,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre'),
                enabled: !_isLoading,
              ),
              TextField(
                controller: _apellidoController,
                decoration: InputDecoration(labelText: 'Apellido'),
                enabled: !_isLoading,
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                enabled: !_isLoading,
              ),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Repetir Contraseña'),
                obscureText: true,
                enabled: !_isLoading,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _handleRegister,
                child: Text('Aceptar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
