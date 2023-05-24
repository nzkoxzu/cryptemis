import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path_provider/path_provider.dart';
import 'file_manager.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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
  final FileManagerController controller = FileManagerController();

void fabPressed(BuildContext context) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      // Fichier sélectionné, vous pouvez maintenant l'uploader où vous le souhaitez
      // file contient le fichier sélectionné
      // fileName contient le nom du fichier avec son extension

      // Exemple : Sauvegarder le fichier dans le répertoire d'application
      Directory appDirectory = await getApplicationDocumentsDirectory();
      String filePath = '${appDirectory.path}/$fileName';
      await file.copy(filePath);

      // Vous pouvez également utiliser le chemin du fichier pour effectuer d'autres opérations d'upload ou de traitement selon vos besoins

      // Ici, nous imprimons simplement le chemin dans la console
      print('Chemin du fichier : $filePath');
    }
  } catch (e) {
    print('Erreur lors de la sélection du fichier : $e');
    // Gérez les erreurs ici
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
                  IconButton(
                    onPressed: () => createFolder(context),
                    icon: Icon(Icons.create_new_folder_outlined),
                  ),
                  IconButton(
                    onPressed: () => sort(context),
                    icon: Icon(Icons.sort_rounded),
                  ),
                  IconButton(
                    onPressed: () => selectStorage(context),
                    icon: Icon(Icons.sd_storage_rounded),
                  )
                ],
                title: ValueListenableBuilder<String>(
                  valueListenable: controller.titleNotifier,
                  builder: (context, title, _) => Text(title),
                ),
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
                                ? Icon(Icons.feed_outlined)
                                : Icon(Icons.folder),
                            title: Text(FileManager.basename(entity)),
                            subtitle: subtitle(entity),
                            onTap: () async {
                              if (FileManager.isDirectory(entity)) {
                                // open the folder
                                controller.openDirectory(entity);
    
                                // delete a folder
                                // await entity.delete(recursive: true);
    
                                // rename a folder
                                // await entity.rename("newPath");
    
                                // Check weather folder exists
                                // entity.exists();
    
                                // get date of file
                                // DateTime date = (await entity.stat()).modified;
                              } else {
                                // delete a file
                                // await entity.delete();
    
                                // rename a file
                                // await entity.rename("newPath");
    
                                // Check weather file exists
                                // entity.exists();
    
                                // get date of file
                                // DateTime date = (await entity.stat()).modified;
    
                                // get the size of the file
                                // int size = (await entity.stat()).size;
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
                child: Icon(Icons.add_circle_outline),
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
                    // Create Folder
                    await FileManager.createFolder(controller.getCurrentPath, folderName.text);
                    // Open Created Folder
                    controller.setCurrentPath = controller.getCurrentPath + "/" + folderName.text;

                    // Get the application-specific directory
                    final appDir = await path_provider.getApplicationDocumentsDirectory();
                    // Create a file in the application-specific directory
                    final file = File('${appDir.path}/test.lol');
                    await file.writeAsString('Contenu du fichier');

                  } catch (e) {
                    // Show error message
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

}