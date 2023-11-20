import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class OptionsSection extends StatelessWidget {
  final Set<String> selectedFiles;
  final VoidCallback refreshFiles;
  final Function(Set<String>) onFileSelectionChanged;

  const OptionsSection({
    Key? key,
    required this.selectedFiles,
    required this.refreshFiles,
    required this.onFileSelectionChanged,
  }) : super(key: key);

  void _deleteSelectedFiles(BuildContext context) async {
    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No file selected'),
        ),
      );
      return;
    }

    final List<String> failedDeletes = [];
    for (var filePath in selectedFiles) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        failedDeletes.add(filePath);
      }
    }

    // Clear the selected files after delete action
    onFileSelectionChanged(Set<String>());

    // Refresh file list
    refreshFiles();
  }

  Future<void> _pickAndUploadFiles(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();

      for (File file in files) {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String appDocPath = appDocDir.path;
        String fileName = file.path.split('/').last;
        File newFile = File('$appDocPath/$fileName');
        await file.copy(newFile.path);
      }
      refreshFiles();
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.file_upload, size: 24),
            onPressed: () async {
              await _pickAndUploadFiles(context);
            },
          ),
          const Text(
            'Files',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          Spacer(),
          IconButton(
            icon: const Icon(Icons.select_all, size: 24),
            onPressed: () {
              // TODO: Implémenter la fonctionnalité de sélection de fichiers
            },
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder, size: 24),
            onPressed: () {
              // TODO: Implémenter la fonctionnalité de création de dossiers
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 24),
            onPressed: () {
              _deleteSelectedFiles(context);
              refreshFiles();
            },
          ),
        ],
      ),
    );
  }
}
