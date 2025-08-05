import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference _usuarios =
  FirebaseFirestore.instance.collection('usuarios');

  /// CREATE - Agregar un usuario con ID automátic
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

/*
  Future<void> agregarUsuarioAuto() async {
    try {
      await _usuarios.add({
        'name':'juan',
        'lastname':'landeros',
        'email': 'jose@mail.com',
        'subscription': {
          'status': "active",
          'source': "stripe", // o "apple" o "stripe"
          'expiryDate': DateTime.now().add(Duration(days: 30)), // ejemplo: 30 días
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        'stripeCustomerId': "cus_ABC123"
      });

      print("Usuario agregado con ID automático");
    } catch (e) {
      print('Error al agregar usuario: $e');
    }
  }


  /// READ - Obtener todos los usuarios una vez
  Future<void> obtenerUsuarios() async {
    try {
      QuerySnapshot snapshot = await _usuarios.get();
      for (var doc in snapshot.docs) {
        print('ID: ${doc.id}');
        print('Data: ${doc.data()}');
      }
    } catch (e) {
      print('Error al leer usuarios: $e');
    }
  }

  /// READ - Escuchar usuarios en tiempo real
  Stream<QuerySnapshot> obtenerUsuariosEnTiempoReal() {
    return _usuarios.snapshots();
  }

  /// UPDATE - Actualizar usuario
  Future<void> actualizarUsuario(String id, Map<String, dynamic> data) async {
    try {
      await _usuarios.doc(id).update(data);
      print("Usuario $id actualizado");
    } catch (e) {
      print('Error al actualizar usuario: $e');
    }
  }

  /// DELETE - Eliminar usuario
  Future<void> eliminarUsuario(String id) async {
    try {
      await _usuarios.doc(id).delete();
      print("Usuario $id eliminado");
    } catch (e) {
      print('Error al eliminar usuario: $e');
    }
  }*/
}
