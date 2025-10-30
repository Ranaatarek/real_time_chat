import 'package:flutter/material.dart';
import 'firebase_service.dart';

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("notes")),
      body: StreamBuilder(
        stream: getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!.snapshot.value as Map?;
            if (data == null) return Center(child: Text("empty"));

            final notes = data.entries.toList();

            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final item = notes[index].value;
                return ListTile(
                  title: Text(item['title']),
                  subtitle: Text(item['description']),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("error"));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
