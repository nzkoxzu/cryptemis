import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path_provider/path_provider.dart';
import 'file_manager.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'encryption.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_slidable/flutter_slidable.dart';



final FileManagerController controller = FileManagerController();


// Create cryptemis folder if not exist
void createCryptemisFolder() async {
  String folderName = 'cryptemis_folder';

  // check if cryptemis folder exist
  bool isFolderExist(String folderName) {
    Directory directory = Directory(folderName);
    return directory.existsSync();
}

  switch (Platform.operatingSystem) {
    case 'android':
    case 'ios':
      if (isFolderExist(folderName)) {
        print('Folder exists: $folderName');
      } else {
        String cryptemisPath = '/data/user/0/org.app.cryptemis/';
        await FileManager.createFolder(cryptemisPath, folderName);
        controller.setCurrentPath = cryptemisPath+ "/" + folderName;
        print('Successfully created cryptemis directory');
      }
      break;
      
    case 'windows':
    case 'macos':
    case 'linux':
      String documentsDir = '';
      if (Platform.isWindows) {
        documentsDir = Platform.environment['USERPROFILE'] ?? '';
        String cryptemisPath = documentsDir;
        await FileManager.createFolder(cryptemisPath, folderName);


      } else {
        documentsDir = Platform.environment['HOME'] ?? '';
        String cryptemisPath = documentsDir;
        await FileManager.createFolder(cryptemisPath, folderName);
        controller.setCurrentPath = cryptemisPath+ "/" + folderName;
        print ('Successfully created cryptemis directory');
      }

      break;
    default:
      print('Unsupported operating system.');
  }


}

void main() {
  createCryptemisFolder();
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
  


// fancy custom icon
Widget getFileIcon(String filePath) {
  String extension = filePath.split('.').last.toLowerCase();

  switch (extension) {
    case 'pdf':
      Color ? iconColor;
      iconColor = Colors.red[900]; 
      return Icon(Icons.picture_as_pdf, color: iconColor);
    case 'png':
    case 'jpg':
    case 'jpeg':
      Color ? iconColor;
      iconColor = Colors.purple[900]; 
      return Icon(Icons.image, color : iconColor);
    case 'txt':
      Color ? iconColor;
      iconColor = Colors.green[900]; 
      return Icon(Icons.text_snippet, color : iconColor);
    case 'cryptemis':
      Color ? iconColor;
      iconColor = Colors.black; 
      return Icon(Icons.text_snippet, color : iconColor);
      
    default:
      Color ? iconColor;
      iconColor = Colors.yellow[400]; 
      return Icon(Icons.insert_drive_file, color : iconColor);
  }

  
}


// Fonction d'upload de fichiers
void fileUpload(BuildContext context) async {
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
      String currentPath = controller.getCurrentPath;
      String filePath = '$currentPath/$fileName';
      await file.copy(filePath);
      refresh(context);

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
                  onPressed: () => refresh(context),
                  icon: Icon(Icons.refresh),
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
                      return Slidable(
                        actionPane: SlidableDrawerActionPane(),
                        secondaryActions: [
                          IconSlideAction(
                            caption: 'Delete',
                            color: Colors.red,
                            icon: Icons.delete,
                            onTap: () async {
                              await entity.delete(recursive: true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Element deleted'),
                                ),
                              );
                              // Rafraîchir la liste après la suppression si nécessaire
                              refresh(context);
                            },
                          ),
                        ],
                        child: Card(
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
                                // Ouvre le fichier
                                OpenResult result = await OpenFile.open(entity.path);
                                if (result.type == ResultType.done || result.type == ResultType.noAppToOpen) {
                                  // print pour debug
                                  print('Fichier ouvert avec succès');
                                } else {
                                  print('Impossible d\'ouvrir le fichier');
                                }
                              }
                            },
                          ),
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
                fileUpload(context);
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



// Fonction refresh
refresh(BuildContext context) async {
  try {
      String currentPath = controller.getCurrentPath;
      // workaround pour refresh (navigue dans le dossier source et retourne dans le dossier ou le fichier a été upload)
      await controller.goToParentDirectory();
      controller.openDirectory(Directory(currentPath));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error refreshing: $e'),
      ),
    );
  }
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
                    refresh(context);
                    // Ouvre le fichier
                    // controller.setCurrentPath = controller.getCurrentPath + "/" + folderName.text;


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
                    String directory = "/data/user/0/org.app.cryptemis/cryptemis";
                    String password = inputField2.text;
                    final filePath = '$directory/.cryptemis';
                    final encryptionPath = '$directory/.encrypted';
                    final file = File(filePath);
                    final encryption = File(encryptionPath);

                    if (await file.exists()) {
                      print('.cryptemis exist');
                      isEncrypted(encryption, password, directory, encryption, context);
                    } else {
                      print('File does not exist, creating now ...');
                      createConfig(algorithm, password, directory);
                    }



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

void isEncrypted(File file, String password, String directory, final encryption, BuildContext context) async {
      int result = 2;
      if (await encryption.exists()){
        result = await decipherDirectory(password, directory);

        if (result == 0 ) {
            final snackBar = SnackBar(
              content: Text('Folder decrypted !'),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);

        await file.delete();
        } else  {
          final snackBar = SnackBar(
            content: Text('Wrong Password !'),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }else  {
        final snackBar = SnackBar(
          content: Text('Folder encrypted !'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        cipherDirectory(password, directory);
        await file.create();
        }

}

}
