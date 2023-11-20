import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class OptionsSection extends StatelessWidget {
  final VoidCallback? refreshFiles;
  const OptionsSection({Key? key, this.refreshFiles}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10), // Arrondi en haut à gauche
          topRight: Radius.circular(10), // Arrondi en haut à droite
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.file_upload, size: 24),
            onPressed: () async {
              // Using file picker to pick files to upload
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                allowMultiple: true,
                type: FileType.any,
              );

              if (result != null) {
                List<File> files =
                    result.paths.map((path) => File(path!)).toList();

                for (File file in files) {
                  Directory appDocDir =
                      await getApplicationDocumentsDirectory();
                  String appDocPath = appDocDir.path;
                  String fileName = file.path.split('/').last;
                  File newFile = File('$appDocPath/$fileName');
                  await file.copy(newFile.path);
                }
              } else {
                // user cancelled
              }
              refreshFiles;
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
              // TODO: Implémenter la fonctionnalité de suppression de dossiers
            },
          ),
        ],
      ),
    );
  }
}
