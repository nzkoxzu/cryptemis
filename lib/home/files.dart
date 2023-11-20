import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class FilesSection extends StatefulWidget {
  final Function(Set<String>) onSelectedFilesChanged;

  const FilesSection({Key? key, required this.onSelectedFilesChanged})
      : super(key: key);

  @override
  _FilesSectionState createState() => _FilesSectionState();
}

class _FilesSectionState extends State<FilesSection> {
  Future<List<FileSystemEntity>> _files = Future.value([]);
  Directory? currentDirectory;
  final Set<String> _selectedFiles = {};

  @override
  void initState() {
    super.initState();
    _initDirectory();
  }

  void _initDirectory() async {
    currentDirectory = await getApplicationDocumentsDirectory();
    _updateFileList();
  }

  void _updateFileList() {
    setState(() {
      _files = _listFiles();
    });
  }

  Future<List<FileSystemEntity>> _listFiles() async {
    final List<FileSystemEntity> filesAndDirectories =
        currentDirectory?.listSync() ?? [];

    final List<FileSystemEntity> directories = [];
    final List<FileSystemEntity> files = [];

    for (var entity in filesAndDirectories) {
      if (entity is Directory) {
        directories.add(entity);
      } else {
        files.add(entity);
      }
    }

    directories
        .sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

    return directories + files;
  }

  void _handleFileSelection(String filePath, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedFiles.add(filePath);
      } else {
        _selectedFiles.remove(filePath);
      }
      widget.onSelectedFilesChanged(_selectedFiles);
    });
  }

  void _navigateToParentDirectory() {
    final parentDirectory = currentDirectory?.parent;
    if (parentDirectory != null &&
        parentDirectory.path != currentDirectory?.path) {
      setState(() {
        currentDirectory = parentDirectory;
        _updateFileList();
      });
    }
  }

  Widget _buildFileItem(FileSystemEntity file) {
    IconData iconData;
    Color iconColor;
    String fileName = file.path.split('/').last;

    if (file is Directory) {
      iconData = Icons.folder;
      iconColor = Colors.amber;
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

    bool isSelected = _selectedFiles.contains(file.path);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.2),
        child: Icon(iconData, color: iconColor),
      ),
      title: Text(
        fileName,
        style: const TextStyle(fontSize: 16.0),
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (bool? value) {
          _handleFileSelection(file.path, value ?? false);
        },
      ),
      onTap: () {
        if (file is Directory) {
          setState(() {
            currentDirectory = file;
            _updateFileList();
          });
        } else {
          OpenFile.open(file.path);
        }
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
          _updateFileList();
        },
        child: FutureBuilder<List<FileSystemEntity>>(
          future: _files,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              if (snapshot.hasData) {
                return GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      _navigateToParentDirectory();
                    }
                  },
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return _buildFileItem(snapshot.data![index]);
                    },
                  ),
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
