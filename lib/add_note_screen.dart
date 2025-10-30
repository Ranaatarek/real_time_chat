import 'package:flutter/material.dart';
import 'package:realtime/notes_list_screen.dart';
import 'firebase_service.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("add note")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "address"),
            ),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: "description"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await addNote(titleController.text, descController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("added successful")),
                );
                titleController.clear();
                descController.clear();
              },
              child: Text("add"),
            ),
            SizedBox(height: 46,),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotesListScreen()),
                );
              },
              child: Text("Show Notes"),
            )

          ],
        ),
      ),
    );
  }
}
