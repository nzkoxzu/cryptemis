import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FilesSection extends StatefulWidget {
  const FilesSection({super.key});

  @override
  _FilesSectionState createState() => _FilesSectionState();
}

class _FilesSectionState extends State<FilesSection> {
  Future<List<FileSystemEntity>> _listFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    return files;
  }

  Widget _buildFileItem(FileSystemEntity file) {
    IconData iconData;
    Color iconColor;
    String fileName = file.path.split('/').last;

    // Déterminer l'icône et la couleur en fonction de l'extension du fichier
    if (file is Directory) {
      iconData = Icons.folder;
      iconColor = Colors.black;
    } else if (fileName.endsWith('.pdf')) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (fileName.endsWith('.png')) {
      iconData = Icons.image;
      iconColor = Colors.blue;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.2), // Légère transparence
        child: Icon(iconData, color: iconColor),
      ),
      title: Text(
        fileName,
        style: TextStyle(fontSize: 16.0),
      ),
      trailing: Checkbox(
        value:
            false, // Ceci doit être lié à une valeur de contrôle pour chaque fichier
        onChanged: (bool? value) {
          // Gérer le changement de valeur
        },
      ),
      onTap: () {
        // Gérer l'appui sur un élément
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 700,
      color: Colors.grey.shade100,
      child: FutureBuilder<List<FileSystemEntity>>(
        future: _listFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data?.length ?? 0,
                itemBuilder: (context, index) {
                  return _buildFileItem(snapshot.data![index]);
                },
              );
            } else {
              return Center(child: Text('Aucun fichier trouvé'));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
