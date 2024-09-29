import 'package:flutter/material.dart';

Future<List<String>?> newNav(BuildContext context) async {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  return showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text('New Route'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Start"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(hintText: "Destination"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.cancel)),
                  IconButton(
                      onPressed: () {
                        if (nameController.text != '') {
                          Navigator.pop(context, [
                            nameController.text,
                            descriptionController.text
                          ]);
                        }
                      },
                      icon: const Icon(Icons.done)),
                ],
              ),
            ],
          ),
        );
      });
}
