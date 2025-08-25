import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {

  static final CollectionReference _usuarios =
  FirebaseFirestore.instance.collection('usuarios');
  static CollectionReference get usuarios => _usuarios;


  static Future<DocumentReference> agregarUsuario({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String stripeCustomerId,
  }) async {
    final docRef = await _usuarios.add({
      'name': nombre,
      'lastName': apellido,
      'email': email,
      'password': password,
      'subscription': {
        'status': "",
        'source': "stripe",
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      'stripeCustomerId': stripeCustomerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef;
  }


  Future<void> actualizarSuscripcionUsuario(String stripeCustomerId, String subscriptionId, String status,String current_period_start,String current_period_end) async {
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
            'current_period_start':current_period_start,
            'current_period_end':current_period_end,
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

  static Future<Map<String, dynamic>?> obtenerUsuarioPorToken(String token) async {
    try {
      final querySnapshot = await _usuarios
          .where('auth_token', isEqualTo: token)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        print("No se encontró usuario con ese token.");
        return null;
      }
    } catch (e) {
      print("Error al obtener usuario por token: $e");
      return null;
    }
  }

  Future<void> actualizarFechasSuscripcionUsuario({
    required String userId,
    required String currentPeriodStart,
    required String currentPeriodEnd,
    required String status,
  }) async {
    try {
      await usuarios.doc(userId).update({
        'subscription.current_period_start': currentPeriodStart,
        'subscription.current_period_end': currentPeriodEnd,
        'subscription.status':status,
        'subscription.lastUpdated': FieldValue.serverTimestamp(),
      });
      print("Suscripción actualizada en Firestore para usuario $userId");
    } catch (e) {
      print("Error actualizando suscripción en Firestore: $e");
    }
  }
}
