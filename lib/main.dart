import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path_provider/path_provider.dart';
import 'file_manager.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'encryption.dart';
import 'package:open_file/open_file.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
    
  } 
}

class HomePage extends StatelessWidget {
  List<String> encryptionAlgorithms = ['Xchacha20', 'AES'];
  String selectedAlgorithm = 'Xchacha20';
  final FileManagerController controller = FileManagerController();

// fancy custom icon
Widget getFileIcon(String filePath) {
  String extension = filePath.split('.').last.toLowerCase();

  switch (extension) {
    case 'pdf':
      return Icon(Icons.picture_as_pdf);
    case 'png':
    case 'jpg':
    case 'jpeg':
      return Icon(Icons.image);
    case 'txt':
      return Icon(Icons.text_snippet);
    default:
      return Icon(Icons.insert_drive_file);
  }
}

// Fonction d'upload de fichiers
void fabPressed(BuildContext context) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      // Fichier sélectionné, on peut handle le fichier comme on veut
      // - file contient le fichier sélectionné
      // - fileName contient le nom du fichier avec son extension

      // Upload le fichier dans le dossier reservé à Cryptemis
      Directory appDirectory = await getApplicationDocumentsDirectory();
      String filePath = '${controller.getCurrentPath}/$fileName';
      await file.copy(filePath);
    }
  } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating folder: $e'),
        ),
      );
  }
}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: path_provider.getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ControlBackButton(
            controller: controller,
            child: Scaffold(
              appBar: AppBar(
                actions: [
                  // IconButton Créer un dossier
                  IconButton(
                    onPressed: () => cypherr(context),
                    icon: Icon(Icons.enhanced_encryption_rounded),
                  ),
                  IconButton(
                    onPressed: () => createFolder(context),
                    icon: Icon(Icons.create_new_folder_outlined),
                  ),
                  // IconButton Filtrer par
                  IconButton(
                    onPressed: () => sort(context),
                    icon: Icon(Icons.sort_rounded),
                  ),
                  // IconButton Chiffrement/Déchiffrement (temporaire pour debug)
                  IconButton(
                    onPressed: () => selectStorage(context),
                    icon: Icon(Icons.sd_storage_rounded),
                  )
                ],
                title: ValueListenableBuilder<String>(
                  valueListenable: controller.titleNotifier,
                  builder: (context, title, _) => Text(title),
                ),
                // IconButton Retour (goToParentDirectory)
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () async {
                    await controller.goToParentDirectory();
                  },
                ),
              ),
              body: Container(
                margin: EdgeInsets.all(10),
                child: FileManager(
                  controller: controller,
                  builder: (context, snapshot) {
                    final List<FileSystemEntity> entities = snapshot;
                    return ListView.builder(
                      itemCount: entities.length,
                      itemBuilder: (context, index) {
                        FileSystemEntity entity = entities[index];
                        return Card(
                          child: ListTile(
                            leading: FileManager.isFile(entity)
                                ? getFileIcon(entity.path)
                                : Icon(Icons.folder),
                            title: Text(FileManager.basename(entity)),
                            subtitle: subtitle(entity),
                            onTap: () async {
                              if (FileManager.isDirectory(entity)) {
                                // ouvre le dossier
                                controller.openDirectory(entity);
    
                                // Utile pour la suite du projet
                                // supprimer un dossier
                                // await entity.delete(recursive: true);
    
                                // renommer un dossier 
                                // await entity.rename("newPath");
    
                                // Check si un dossier existe
                                // entity.exists();

                              } else {
                                // supprimer un fichier
                                // await entity.delete();
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              floatingActionButton: FloatingActionButton(
                // IconButton Upload de fichiers
                child: Icon(Icons.add_circle),
                onPressed: () {
                                fabPressed(context);
                              },
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }



  Widget subtitle(FileSystemEntity entity) {
    return FutureBuilder<FileStat>(
      future: entity.stat(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (entity is File) {
            int size = snapshot.data!.size;

            return Text(
              "${FileManager.formatBytes(size)}",
            );
          }
          return Text(
            "${snapshot.data!.modified}".substring(0, 10),
          );
        } else {
          return Text("");
        }
      },
    );
  }



// Fonction de selection de la source de stockage (A SUPPRIMER)
  selectStorage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: FutureBuilder<List<Directory>>(
          future: FileManager.getStorageList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final List<FileSystemEntity> storageList = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: storageList
                        .map((e) => ListTile(
                              title: Text(
                                "${FileManager.basename(e)}",
                              ),
                              onTap: () {
                                controller.openDirectory(e);
                                Navigator.pop(context);
                              },
                            ))
                        .toList()),
              );
            }
            return Dialog(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

// Fonction de tri (sort by)
  sort(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                  title: Text("Name"),
                  onTap: () {
                    controller.sortBy(SortBy.name);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text("Size"),
                  onTap: () {
                    controller.sortBy(SortBy.size);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text("Date"),
                  onTap: () {
                    controller.sortBy(SortBy.date);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text("type"),
                  onTap: () {
                    controller.sortBy(SortBy.type);
                    Navigator.pop(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }

// Fonction de création de fichiers
createFolder(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) {
      TextEditingController folderName = TextEditingController();
      return Dialog(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: TextField(
                  controller: folderName,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Créé le fichier
                    await FileManager.createFolder(controller.getCurrentPath, folderName.text);
                    // Ouvre le fichier
                    controller.setCurrentPath = controller.getCurrentPath + "/" + folderName.text;


                    // Crée un fichier encryption.cryptemis dans le dossier qui vient d'être créé
                    final file = File('${controller.getCurrentPath}/encryption.cryptemis');
                    //await file.writeAsString('jecris du contenu dans mon fichier encryption.cryptemis');
                    var dir = Directory.current;
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating folder: $e'),
                      ),
                    );
                  }
                  Navigator.pop(context);
                },
                child: Text('Create Folder'),
              )
            ],
          ),
        ),
      );
    },
  );
}

cypherr(BuildContext context) async {
  TextEditingController inputField1 = TextEditingController();
  TextEditingController inputField2 = TextEditingController();
  TextEditingController inputField3 = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: DropdownButton<String>(
                  value: selectedAlgorithm,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedAlgorithm = newValue;
                    }
                  },
                  items: encryptionAlgorithms.map((String algorithm) {
                    return DropdownMenuItem<String>(
                      value: algorithm,
                      child: Text(algorithm),
                    );
                  }).toList(),
                ),
              ),
              ListTile(
                title: TextField(
                  controller: inputField2,
                  decoration: InputDecoration(
                    hintText: 'Password',
                  ),
                ),
              ),
              ListTile(
                title: TextField(
                  controller: inputField3,
                  decoration: InputDecoration(
                    hintText: 'dossier',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    String algorithm = selectedAlgorithm;
                    String directory = "/data/user/0/org.app.cryptemis/app_flutter/test";
                    String password = inputField2.text;
                    createConfig("Xchacha20", "yolo", "/data/user/0/org.app.cryptemis/app_flutter/test");
                  } catch (e) {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                      ),
                    );
                  }
                  Navigator.pop(context);
                },
                child: Text('Confirmer'),
              )
            ],
          ),
        ),
      );
    },
  );
}


}
