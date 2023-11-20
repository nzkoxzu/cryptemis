import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FilesSection extends StatefulWidget {
  final Function()? onRefreshRequested;

  const FilesSection({super.key, this.onRefreshRequested});

  @override
  _FilesSectionState createState() => _FilesSectionState();
}

class _FilesSectionState extends State<FilesSection> {
  late Future<List<FileSystemEntity>> _files;

  @override
  void initState() {
    super.initState();
    _files = _listFiles();
  }

  Future<List<FileSystemEntity>> _listFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    return files;
  }

  void refreshFiles() {
    setState(() {
      _files = _listFiles();
    });
  }

  Widget _buildFileItem(FileSystemEntity file) {
    IconData iconData;
    Color iconColor;
    String fileName = file.path.split('/').last;

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
        backgroundColor: iconColor.withOpacity(0.2),
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
      child: RefreshIndicator(
        onRefresh: () async {
          refreshFiles();
          if (widget.onRefreshRequested != null) {
            widget.onRefreshRequested!();
          }
        },
        child: FutureBuilder<List<FileSystemEntity>>(
          future: _files,
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
      ),
    );
  }
}
