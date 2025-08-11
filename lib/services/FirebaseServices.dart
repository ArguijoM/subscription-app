import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference _usuarios =
  FirebaseFirestore.instance.collection('usuarios');

  Future<void> agregarUsuario(String email, String user, String stripeCustomerId) async {
    try {
      await _usuarios.add({
        'user': user,
        'email': email,
        'subscription': {
          'status': "",
          'source': "stripe",
          'expiryDate': DateTime.now().add(Duration(days: 30)),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        'stripeCustomerId': stripeCustomerId,
      });

      print("Usuario agregado a Firebase con cliente Stripe: $stripeCustomerId");
    } catch (e) {
      print('Error al agregar usuario: $e');
    }
  }

  Future<void> actualizarSuscripcionUsuario(String stripeCustomerId, String subscriptionId, String status) async {
    try {
      final querySnapshot = await _usuarios
          .where('stripeCustomerId', isEqualTo: stripeCustomerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;

        await _usuarios.doc(docId).update({
          'subscription': {
            'id': subscriptionId,
            'status': status,
            'source': 'stripe',
            'lastUpdated': FieldValue.serverTimestamp(),
          }
        });

        print("Suscripción guardada en Firebase correctamente.");
      } else {
        print("Usuario no encontrado con ese stripeCustomerId.");
      }
    } catch (e) {
      print('Error al guardar suscripción en Firestore: $e');
    }
  }




}
