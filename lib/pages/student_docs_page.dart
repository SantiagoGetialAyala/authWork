import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
// Eliminamos OpenFilex ya que usaremos url_launcher y visor de PDF
// import 'package:open_filex/open_filex.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Nuevo import
import '../services/supabase_service.dart';
import 'dart:io' show Platform; // Importación para detección de plataforma (solo móvil/desktop)
import 'package:flutter/foundation.dart'; // Importación para kIsWeb
import 'pdf_viewer_page.dart'; // Importamos la página del visor de PDF

class StudentDocsPage extends StatefulWidget {
  const StudentDocsPage({super.key});

  @override
  State<StudentDocsPage> createState() => _StudentDocsPageState();
}

class _StudentDocsPageState extends State<StudentDocsPage> {
  // Lista de categorías
  final categories = ['tareas', 'informes', 'examenes'];
  String selectedCategory = 'tareas';
  Map<String, List<FileObject>> filesByCategory = {};
  final supabase = Supabase.instance.client;
  bool _isLoadingFiles = true;

  @override
  void initState() {
    super.initState();
    if (supabase.auth.currentUser != null) {
      loadFiles();
    }
  }

  /// 🔁 Cargar los archivos de cada categoría
  Future<void> loadFiles() async {
    setState(() => _isLoadingFiles = true);
    try {
      Map<String, List<FileObject>> data = {};
      for (var cat in categories) {
        final files = await SupabaseService.listFiles(cat);
        // Filtra elementos no deseados (ej. .emptyFolderPlaceholder)
        data[cat] = files.where((f) => f.name != '.emptyFolderPlaceholder').toList();
      }
      setState(() => filesByCategory = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar archivos: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoadingFiles = false);
    }
  }

  /// ⬆️ Seleccionar y subir archivo
  Future<void> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );
    if (result == null) return;

    final file = result.files.single;

    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se pudieron leer los bytes del archivo.')),
        );
      }
      return;
    }

    final fileBytes = Uint8List.fromList(file.bytes!);
    final fileName = file.name;

    try {
      await SupabaseService.uploadFile(
        category: selectedCategory,
        fileName: fileName,
        fileBytes: fileBytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo "$fileName" subido correctamente a $selectedCategory')),
        );
      }
      loadFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir archivo: ${e.toString()}')),
        );
      }
    }
  }

  /// 📄 Navegar al visor de PDF interno (solo para móvil/desktop)
  void _viewPdf(String url, String fileName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          pdfUrl: url,
          fileName: fileName,
        ),
      ),
    );
  }

  /// 🔗 Función que determina si ver en visor interno o abrir en navegador/descargar
  Future<void> _handleOpenFile(String category, String fileName) async {
    try {
      final url = await SupabaseService.getFileUrl(category, fileName);

      // Si es un PDF, lo visualizamos internamente, excepto en Web (donde el navegador es mejor).
      if (fileName.toLowerCase().endsWith('.pdf') && !kIsWeb) {
        _viewPdf(url, fileName);
      } 
      // Si es web o cualquier otro tipo de archivo, abrimos la URL.
      else {
        // Usamos LaunchMode.externalApplication para intentar la descarga/apertura nativa
        if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('No se pudo abrir el enlace o iniciar la descarga.')),
             );
           }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar archivo: ${e.toString()}')),
        );
      }
    }
  }


  /// 🚪 Cerrar sesión
  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      // La navegación al login la maneja el StreamBuilder en MyApp
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
      return; // Añadido para evitar el flujo normal después de un error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (supabase.auth.currentUser == null) {
      return const Center(child: Text('Por favor, inicia sesión.'));
    }

    final userEmail = supabase.auth.currentUser!.email ?? 'Usuario';
    final userInitial = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de Documentos'),
        backgroundColor: colorScheme.primaryContainer,
        elevation: 4,
        actions: [
          // Dropdown para seleccionar la categoría de subida
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.toUpperCase())))
                    .toList(),
                onChanged: (value) => setState(() => selectedCategory = value!),
              ),
            ),
          ),
          
          // Mostrar Avatar o Iniciales del Usuario
          Tooltip(
            message: 'Sesión iniciada como $userEmail',
            child: CircleAvatar(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              radius: 18,
              child: Text(userInitial),
            ),
          ),
          
          // Botón de cierre de sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Cerrar Sesión',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoadingFiles
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: categories.map((category) {
                return CategoryExpansionTile(
                  category: category,
                  files: filesByCategory[category] ?? [],
                  // Usamos la nueva función _handleOpenFile
                  onOpenFile: _handleOpenFile, 
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: pickAndUploadFile,
        icon: const Icon(Icons.cloud_upload_outlined),
        label: Text('Subir a ${selectedCategory.toUpperCase()}'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }
}

// Widget Separado para la Tarjeta de Categoría
class CategoryExpansionTile extends StatelessWidget {
  final String category;
  final List<FileObject> files;
  final Function(String, String) onOpenFile;

  const CategoryExpansionTile({
    super.key,
    required this.category,
    required this.files,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          '${category.toUpperCase()} (${files.length} archivos)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        iconColor: colorScheme.secondary,
        collapsedIconColor: colorScheme.secondary,
        children: files.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No hay documentos en esta categoría.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              ]
            : files.map((file) => FileListItem(file: file, category: category, onOpenFile: onOpenFile)).toList(),
      ),
    );
  }
}

// Widget Separado para el Item de Archivo
class FileListItem extends StatelessWidget {
  final FileObject file;
  final String category;
  final Function(String, String) onOpenFile;

  const FileListItem({
    super.key,
    required this.file,
    required this.category,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    // Lógica para formatear la fecha de subida de forma segura
    String formattedDate = 'N/A';
    // El error indica que file.createdAt es un String?, por lo que lo leemos como String
    final String? createdAtString = file.createdAt; 

    if (createdAtString != null) {
      try {
        // Parseamos el string de fecha a un objeto DateTime
        final DateTime createdAt = DateTime.parse(createdAtString);
        // 1. Convertir a hora local
        final localDate = createdAt.toLocal();
        // 2. Extraer solo la parte de la fecha (antes del espacio)
        formattedDate = localDate.toString().split(' ')[0]; 
      } catch (e) {
        // En caso de que el string no se pueda parsear
        formattedDate = 'Fecha Inválida';
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: const Icon(Icons.article_outlined, color: Colors.blueGrey),
      title: Text(
        file.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      // Usamos la variable formateada
      subtitle: Text('Subido: $formattedDate'),
      trailing: IconButton(
        icon: const Icon(Icons.file_download_outlined, color: Colors.green),
        // Llama a la función de manejo de apertura de archivo
        onPressed: () => onOpenFile(category, file.name), 
        tooltip: 'Abrir / Descargar Archivo',
      ),
      // Llama a la función de manejo de apertura de archivo
      onTap: () => onOpenFile(category, file.name), 
    );
  }
}