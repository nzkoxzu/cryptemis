library file_manager;

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_manager/helper/helper.dart';
export 'package:file_manager/helper/helper.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'main.dart';
import 'encryption.dart';
import 'dart:async';

typedef _Builder = Widget Function(
  BuildContext context,
  List<FileSystemEntity> snapshot,
);

//Fontion de déchiffrement
class EncryptionHelper {
  void Decrypt(String password, String directory, BuildContext context) async {
    int result = 2;
    result = await decipherDirectory(password, directory);
    //si le resultat de decipherDirectory est 0 alors le déchiffrement c'est bien passé
    if (result == 0) {
      controller.setCurrentPath = directory;

      final snackBar = SnackBar(
        content: Text('Folder decrypted !'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      final snackBar = SnackBar(
        content: Text('Wrong Password !'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}

class _PathStat {
  final String path;
  final DateTime dateTime;
  _PathStat(this.path, this.dateTime);
}

Future<List<FileSystemEntity>> _sortEntitysList(
    String path, SortBy sortType) async {
  final List<FileSystemEntity> list = await Directory(path).list().toList();
  if (sortType == SortBy.name) {
    // making list of only folders.
    final dirs = list.where((element) => element is Directory).toList();
    // sorting folder list by name.
    dirs.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

    // making list of only flies.
    final files = list.where((element) => element is File).toList();
    // sorting files list by name.
    files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

    // first folders will go to list (if available) then files will go to list.
    return [...dirs, ...files];
  } else if (sortType == SortBy.date) {
    // making the list of Path & DateTime
    List<_PathStat> _pathStat = [];
    for (FileSystemEntity e in list) {
      _pathStat.add(_PathStat(e.path, (await e.stat()).modified));
    }

    // sort _pathStat according to date
    _pathStat.sort((b, a) => a.dateTime.compareTo(b.dateTime));

    // sorting [list] accroding to [_pathStat]
    list.sort((a, b) => _pathStat
        .indexWhere((element) => element.path == a.path)
        .compareTo(_pathStat.indexWhere((element) => element.path == b.path)));
    return list;
  } else if (sortType == SortBy.type) {
    // making list of only folders.
    final dirs = list.where((element) => element is Directory).toList();

    // sorting folders by name.
    dirs.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

    // making the list of files
    final files = list.where((element) => element is File).toList();

    // sorting files list by extension.
    files.sort((a, b) => a.path
        .toLowerCase()
        .split('.')
        .last
        .compareTo(b.path.toLowerCase().split('.').last));
    return [...dirs, ...files];
  } else if (sortType == SortBy.size) {
    // create list of path and size
    Map<String, int> _sizeMap = {};
    for (FileSystemEntity e in list) {
      _sizeMap[e.path] = (await e.stat()).size;
    }

    // making list of only folders.
    final dirs = list.where((element) => element is Directory).toList();
    // sorting folder list by name.
    dirs.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

    // making list of only flies.
    final files = list.where((element) => element is File).toList();

    // creating sorted list of [_sizeMapList] by size.
    final List<MapEntry<String, int>> _sizeMapList = _sizeMap.entries.toList();
    _sizeMapList.sort((b, a) => a.value.compareTo(b.value));

    // sort [list] according to [_sizeMapList]
    files.sort((a, b) => _sizeMapList
        .indexWhere((element) => element.key == a.path)
        .compareTo(
            _sizeMapList.indexWhere((element) => element.key == b.path)));
    return [...dirs, ...files];
  }
  return [];
}

/// FileManager is a wonderful widget that allows you to manage files and folders, pick files and folders, and do a lot more.
/// Designed to feel like part of the Flutter framework.
///
/// Sample code
///```dart
///FileManager(
///    controller: controller,
///    builder: (context, snapshot) {
///    final List<FileSystemEntity> entitis = snapshot;
///      return ListView.builder(
///        itemCount: entitis.length,
///        itemBuilder: (context, index) {
///          return Card(
///            child: ListTile(
///              leading: FileManager.isFile(entitis[index])
///                  ? Icon(Icons.feed_outlined)
///                  : Icon(Icons.folder),
///              title: Text(FileManager.basename(entitis[index])),
///              onTap: () {
///                if (FileManager.isDirectory(entitis[index])) {
///                    controller
///                     .openDirectory(entitis[index]);
///                  } else {
///                      // Perform file-related tasks.
///                  }
///              },
///            ),
///          );
///        },
///      );
///  },
///),
///```
class FileManager extends StatefulWidget {
  /// For the loading screen, create a custom widget.
  /// Simple Centered CircularProgressIndicator is provided by default.
  final Widget? loadingScreen;

  /// For an empty screen, create a custom widget.
  final Widget? emptyFolder;

  ///Controls the state of the FileManager.
  final FileManagerController controller;

  ///This function allows you to create custom widgets and retrieve a list of entities `List<FileSystemEntity>.`
  ///
  ///
  ///```
  /// builder: (context, snapshot) {
  ///               return ListView.builder(
  ///                 itemCount: snapshot.length,
  ///                 itemBuilder: (context, index) {
  ///                   return Card(
  ///                     child: ListTile(
  ///                       leading: FileManager.isFile(snapshot[index])
  ///                           ? Icon(Icons.feed_outlined)
  ///                           : Icon(Icons.folder),
  ///                       title: Text(FileManager.basename(snapshot[index])),
  ///                       onTap: () {
  ///                         if (FileManager.isDirectory(snapshot[index]))
  ///                           controller.openDirectory(snapshot[index]);
  ///                       },
  ///                     ),
  ///                   );
  ///                 },
  ///               );
  ///             },
  /// ```
  final _Builder builder;

  /// Hide the files and folders that are hidden.
  final bool hideHiddenEntity;

  FileManager({
    this.emptyFolder,
    this.loadingScreen,
    required this.controller,
    required this.builder,
    this.hideHiddenEntity = true,
  });

  @override
  _FileManagerState createState() => _FileManagerState();

  /// check weather FileSystemEntity is File
  /// return true if FileSystemEntity is File else returns false
  static bool isFile(FileSystemEntity entity) {
    return (entity is File);
  }

// check weather FileSystemEntity is Directory
  /// return true if FileSystemEntity is a Directory else returns Directory
  static bool isDirectory(FileSystemEntity entity) {
    return (entity is Directory);
  }

  /// Get the basename of Directory or File.
  ///
  /// Provide [File], [Directory] or [FileSystemEntity] and returns the name as a [String].
  ///
  /// ie:
  /// ```dart
  /// controller.basename(dir);
  /// ```
  /// to hide the extension of file, showFileExtension = flase
  static String basename(dynamic entity, [bool showFileExtension = true]) {
    if (entity is Directory) {
      return entity.path.split('/').last;
    } else if (entity is File) {
      return (showFileExtension)
          ? entity.path.split('/').last.split('.').first
          : entity.path.split('/').last;
    } else {
      print(
          "Please provide a Object of type File, Directory or FileSystemEntity");
      return "";
    }
  }

  /// Convert bytes to human readable size
  static String formatBytes(int bytes, [int precision = 2]) {
    if (bytes != 0) {
      final double base = math.log(bytes) / math.log(1024);
      final suffix = const ['B', 'KB', 'MB', 'GB', 'TB'][base.floor()];
      final size = math.pow(1024, base - base.floor());
      return '${size.toStringAsFixed(precision)} $suffix';
    } else {
      return "0B";
    }
  }

  /// Creates the directory if it doesn't exist.
  static Future<void> createFolder(String currentPath, String name) async {
    await Directory(currentPath + "/" + name).create();
  }

  /// Return file extension as String.
  ///
  /// ie:- `File("/../image.png")` to `"png"`
  static String getFileExtension(FileSystemEntity file) {
    if (file is File) {
      return file.path.split("/").last.split('.').last;
    } else {
      throw "FileSystemEntity is Directory, not a File";
    }
  }

  /// Get list of available storage in the device
  /// returns an empty list if there is no storage
  static Future<List<Directory>> getStorageList() async {
    if (Platform.isAndroid) {
      Directory storage = await getApplicationDocumentsDirectory();
      List<Directory> storages = [storage];
      storages = storages.map((Directory e) {
        final List<String> splitedPath = e.path.split("/");
        return Directory(splitedPath
            .sublist(
                0, splitedPath.indexWhere((element) => element == "Android"))
            .join("/"));
      }).toList();
      return storages;
    } else if (Platform.isLinux) {
      final Directory dir = await getApplicationDocumentsDirectory();

      // Gives the home directory.
      final Directory home = dir.parent;

      // you may provide root directory.
      // final Directory root = dir.parent.parent.parent;
      return [home];
    }
    return [];
  }
}

class _FileManagerState extends State<FileManager> {
  Future<List<Directory>?>? currentDir;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
////////////////////////////////////////////////////////////////
  ///
  ///

  @override
  void initState() {
    super.initState();
    if (widget.controller.getCurrentPath.isNotEmpty) {
      currentDir = Future.value([widget.controller.getCurrentDirectory]);
    } else {
      currentDir = getApplicationDocumentsDirectory().then((directory) {
        return _createDirectory(directory);
      }).catchError((error) {
        throw ("Erreur lors de la création du dossier : $error");
      });
    }
  }

  Future<List<Directory>> _createDirectory(Directory directory) async {
    try {
      final exists = await directory.exists();
      if (!exists) {
        await directory.create(recursive: true);
      }
      return [directory]; // Wrap the directory in a list and return
    } catch (error) {
      throw Exception("Erreur lors de la création du dossier : $error");
    }
  }

//////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Directory>?>(
      future: currentDir,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          widget.controller.setCurrentPath = snapshot.data!.first.path;
          return _body(context);
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return _errorPage(snapshot.error.toString());
        } else {
          return _loadingScreenWidget();
        }
      },
    );
  }

  Widget _body(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.controller.getPathNotifier,
      builder: (context, pathSnapshot, _) {
        return ValueListenableBuilder<SortBy>(
          valueListenable: widget.controller.getSortedByNotifier,
          builder: (context, snapshot, _) {
            return FutureBuilder<List<FileSystemEntity>>(
              future: _sortEntitysList(
                pathSnapshot,
                widget.controller.getSortedByNotifier.value,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<FileSystemEntity> entities = snapshot.data!;
                  if (entities.length == 0) {
                    return _emptyFolderWidger();
                  }
                  if (widget.hideHiddenEntity) {
                    entities = entities.where((element) {
                      if (FileManager.basename(element) == "" ||
                          FileManager.basename(element).startsWith('.')) {
                        return false;
                      } else {
                        return true;
                      }
                    }).toList();
                  }

                  return ListView.builder(
                    itemCount: entities.length,
                    itemBuilder: (context, index) {
                      FileSystemEntity entity = entities[index];
                      if (FileManager.isDirectory(entity)) {
                        Directory parentDirectory =
                            Directory(entity.path).parent;
                        if (FileManager.basename(parentDirectory) ==
                            "cryptemis_folder") {
                          return GestureDetector(
                            onTap: () async {
                              TextEditingController passwordController =
                                  TextEditingController(); // Ajoutez cette ligne
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Entrez le mot de passe'),
                                  content: TextField(
                                    obscureText: true,
                                    controller: passwordController,
                                    onChanged: (value) {
                                      // Faire qqchose avec le mot de passe saisi
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        //Aprés le clik sur un dossier on envoit les info a la fonction de déchiffrement Decrypt()
                                        String password =
                                            passwordController.text;

                                        EncryptionHelper encryptionHelper =
                                            EncryptionHelper();

                                        String directory = entity.path;

                                        encryptionHelper.Decrypt(
                                            password, directory, context);

                                        Navigator.pop(context);
                                      },
                                      child: Text('Valider'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Slidable(
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
                                    //refresh(context);
                                  },
                                ),
                              ],
                              child: Card(
                                child: ListTile(
                                  leading: FileManager.isDirectory(entity)
                                      ? Icon(Icons.folder)
                                      : getFileIcon(entity),
                                  title: Text(FileManager.basename(entity)),
                                  subtitle: subtitle(entity),
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      return GestureDetector(
                        onTap: () async {
                          if (FileManager.isDirectory(entity)) {
                            widget.controller.openDirectory(entity);
                          } else {
                            // Handle le fichier
                            OpenResult result =
                                await OpenFile.open(entity.path);
                            if (result.type == ResultType.done ||
                                result.type == ResultType.noAppToOpen) {
                              print('Fichier ouvert avec succès');
                            } else {
                              print('Impossible d\'ouvrir le fichier');
                            }
                          }
                        },
                        child: Slidable(
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
                                //widget.controller.refresh(context);
                              },
                            ),
                          ],
                          child: Card(
                            child: ListTile(
                              leading: FileManager.isDirectory(entity)
                                  ? Icon(Icons.folder)
                                  : getFileIcon(entity),
                              title: Text(FileManager.basename(entity)),
                              subtitle: subtitle(entity),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                  return _errorPage(snapshot.error.toString());
                } else {
                  return _loadingScreenWidget();
                }
              },
            );
          },
        );
      },
    );
  }

  Icon getFileIcon(FileSystemEntity entity) {
    // Code pour obtenir l'icône du fichier/dossier en fonction de son type
    if (FileManager.isFile(entity)) {
      // C'est un fichier
      return Icon(Icons.insert_drive_file);
    } else if (FileManager.isDirectory(entity)) {
      // C'est un dossier
      return Icon(Icons.folder);
    } else {
      // Type inconnu, retourne une icône générique
      return Icon(Icons.file_copy);
    }
  }

  Widget subtitle(FileSystemEntity entity) {
    // Code pour obtenir le sous-titre du fichier/dossier
    // Vous pouvez personnaliser cette méthode en fonction de vos besoins
    if (FileManager.isFile(entity)) {
      // C'est un fichier, retourne les détails du fichier
      return Text(
          'Taille : ${FileManager.formatBytes((entity as File).lengthSync())}');
    } else if (FileManager.isDirectory(entity)) {
      // C'est un dossier, retourne le nombre d'éléments dans le dossier
      Directory directory = entity as Directory;
      int itemCount = directory.listSync().length;
      return Text('$itemCount éléments');
    } else {
      // Type inconnu, retourne un sous-titre générique
      return Text('Type inconnu');
    }
  }

  Widget _emptyFolderWidger() {
    if (widget.emptyFolder == null) {
      return Container(
        child: Center(child: Text("Empty Directory")),
      );
    } else
      return widget.emptyFolder!;
  }

  Container _errorPage(String error) {
    return Container(
      color: Colors.red,
      child: Center(
        child: Text("Error: $error"),
      ),
    );
  }

  Widget _loadingScreenWidget() {
    if ((widget.loadingScreen == null)) {
      return Container(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Container(
        child: Center(
          child: widget.loadingScreen,
        ),
      );
    }
  }
}

/// When the current directory is not root, this widget registers a callback to prevent the user from dismissing the window
/// , or controllers the system's back button
///
/// #### Wrap Scaffold containing FileManage with `ControlBackButton`
/// ```dart
/// ControlBackButton(
///   controller: controller
///   child: Scaffold(
///     appBar: AppBar(...)
///     body: FileManager(
///       ...
///     )
///   )
/// )
/// ```
class ControlBackButton extends StatelessWidget {
  const ControlBackButton({
    required this.child,
    required this.controller,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final FileManagerController controller;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: child,
      onWillPop: () async {
        if (await controller.isRootDirectory()) {
          return true;
        } else {
          controller.goToParentDirectory();
          return false;
        }
      },
    );
  }
}

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
