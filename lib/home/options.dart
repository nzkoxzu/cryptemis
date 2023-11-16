import 'package:flutter/material.dart';

class OptionsSection extends StatelessWidget {
  const OptionsSection({super.key});

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
        mainAxisAlignment:
            MainAxisAlignment.start, // Alignement des enfants à gauche
        children: [
          IconButton(
            icon: const Icon(Icons.file_upload, size: 24),
            onPressed: () {
              // TODO: Implémenter la fonctionnalité d'upload de fichier
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
