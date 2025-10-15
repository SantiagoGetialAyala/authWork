import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String bucketName = 'student_docs';

  // ⚠️ Importante: Este getter asume que solo se llama cuando el usuario está logueado
  // (gestionado por la navegación en MyApp).
  static String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      // Esto solo debería ocurrir si hay un fallo de navegación,
      // pero es bueno manejarlo.
      throw Exception('Usuario no autenticado');
    }
    return user.id;
  }

  /// 📂 Subir archivo
  static Future<void> uploadFile({
    required String category,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final userId = _currentUserId; // Usamos el ID del usuario actual

    // Ruta de almacenamiento: {USER_ID}/{CATEGORY}/{FILENAME}
    final filePath = '$userId/$category/$fileName';

    await _client.storage.from(bucketName).uploadBinary(
          filePath,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );
  }

  /// 📜 Listar archivos de una categoría
  static Future<List<FileObject>> listFiles(String category) async {
    final userId = _currentUserId; // Usamos el ID del usuario actual
    final path = '$userId/$category/';
    
    // El método list en Supabase Storage lista el contenido de una carpeta.
    final result = await _client.storage.from(bucketName).list(path: path);
    return result;
  }

  /// 🔗 Obtener URL pública
  static Future<String> getFileUrl(String category, String fileName) async {
    final userId = _currentUserId; // Usamos el ID del usuario actual
    final filePath = '$userId/$category/$fileName';
    
    // Obtener la URL pública (asumiendo que el bucket es público o tiene políticas de lectura).
    final url = _client.storage.from(bucketName).getPublicUrl(filePath);
    return url;
  }
}