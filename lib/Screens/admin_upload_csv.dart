import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

class AdminUploadCSVPage extends StatefulWidget {
  const AdminUploadCSVPage({super.key});

  @override
  State<AdminUploadCSVPage> createState() => _AdminUploadCSVPageState();
}

class _AdminUploadCSVPageState extends State<AdminUploadCSVPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;

  Future<void> _uploadCSVFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _isUploading = true;
        });

        File file = File(result.files.single.path!);
        final csvData = await file.readAsString();
        List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

        // Ensure there are rows and a header
        if (rows.isEmpty || rows.length < 2) {
          throw Exception("CSV file is empty or doesn't have enough rows.");
        }

        // The first row contains the column headers
        List<String> headers =
            rows[0].map((header) => header.toString()).toList();

        // Process each subsequent row as a Firestore document
        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];

          // Create a Map to hold the document fields
          Map<String, dynamic> documentData = {};

          for (int j = 0; j < headers.length; j++) {
            // Dynamically map each column to its respective header
            documentData[headers[j]] = row[j];
          }

          // Extract the category (assuming it's always present in the CSV)
          if (!documentData.containsKey('Category')) {
            throw Exception("Missing 'category' field in the CSV.");
          }

          final String category = documentData['Category'];

          // Remove category from documentData to avoid redundancy
          documentData.remove('Category');

          // Add item under the respective category in Firestore
          await _firestore
              .collection('inventory')
              .doc(category)
              .collection('items')
              .add(documentData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV uploaded successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload CSV: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload CSV'),
      ),
      body: Center(
        child: _isUploading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _uploadCSVFile,
                child: const Text('Upload CSV'),
              ),
      ),
    );
  }
}
