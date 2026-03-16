import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalRecord {
  final String title;
  final String filePath;
  final DateTime date;
  final String notes;

  MedicalRecord({
    required this.title,
    required this.filePath,
    required this.date,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'filePath': filePath,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      title: json['title'],
      filePath: json['filePath'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
    );
  }
}

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {

  List<MedicalRecord> records = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordList =
        records.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('records', recordList);
  }

  Future<void> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? recordList = prefs.getStringList('records');

    if (recordList != null) {
      setState(() {
        records = recordList
            .map((r) => MedicalRecord.fromJson(jsonDecode(r)))
            .toList();
      });
    }
  }

  Future<void> pickImage() async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      openRecordForm(photo.path);
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles();

    if (result != null) {
      String path = result.files.single.path!;
      openRecordForm(path);
    }
  }

  void openRecordForm(String filePath) {
    TextEditingController titleController = TextEditingController();
    TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Medical Record"),
          content: SingleChildScrollView(
            child: Column(
              children: [

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Report Name",
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: "Notes",
                  ),
                ),

              ],
            ),
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {

                setState(() {
                  records.add(
                    MedicalRecord(
                      title: titleController.text,
                      filePath: filePath,
                      date: DateTime.now(),
                      notes: notesController.text,
                    ),
                  );
                });

                saveRecords();

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),

          ],
        );
      },
    );
  }

  Widget buildRecordItem(MedicalRecord record, int index) {

    bool isImage =
        record.filePath.endsWith(".jpg") ||
        record.filePath.endsWith(".png");

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(

        leading: isImage
            ? Image.file(
                File(record.filePath),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.picture_as_pdf, size: 40),

        title: Text(record.title),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd MMM yyyy').format(record.date)),
            Text(record.notes),
          ],
        ),

        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              records.removeAt(index);
            });
            saveRecords();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),

      appBar: AppBar(
        title: const Text("Medical Records"),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {

          showModalBottomSheet(
            context: context,
            builder: (context) {

              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text("Scan Report"),
                      onTap: () {
                        Navigator.pop(context);
                        pickImage();
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: const Text("Upload File"),
                      onTap: () {
                        Navigator.pop(context);
                        pickFile();
                      },
                    ),

                  ],
                ),
              );
            },
          );
        },
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: records.isEmpty
            ? const Center(
                child: Text(
                  "No medical records uploaded",
                  style: TextStyle(fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return buildRecordItem(records[index], index);
                },
              ),
      ),
    );
  }
}