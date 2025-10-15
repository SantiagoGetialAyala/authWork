import 'package:flutter/material.dart';

class FileCard extends StatelessWidget {
  final String fileName;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  const FileCard({
    super.key,
    required this.fileName,
    required this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Abrir archivo',
              icon: const Icon(Icons.open_in_new, color: Colors.blueAccent),
              onPressed: onOpen,
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Eliminar archivo',
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
