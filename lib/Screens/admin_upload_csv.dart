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
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _isUploading = true;
        });

        File file = File(result.files.single.path!);
        final csvData = await file.readAsString();
        List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

        if (rows.isEmpty || rows.length < 2) {
          throw Exception("CSV file is empty or doesn't have enough rows.");
        }

        List<String> headers =
            rows[0].map((header) => header.toString().trim()).toList();

        Map<String, String> columnMapping = {
          'Name': 'name',
          'Product Name': 'name',
          'Item Name': 'name',
          'Image URL': 'imageUrls',
          'Image URLs': 'imageUrls',
          'img_url': 'imageUrls',
          'Pictures': 'imageUrls',
          'Price': 'price',
          'Cost': 'price',
          'Selling Price': 'price',
          'Category': 'Category',
          'Category Name': 'Category'
        };

        Map<String, String> detectedColumns = {};
        columnMapping.forEach((csvKey, firestoreKey) {
          for (String header in headers) {
            if (header.toLowerCase().contains(csvKey.toLowerCase())) {
              detectedColumns[firestoreKey] = header;
            }
          }
        });

        print("Detected columns: $detectedColumns");

        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];
          Map<String, dynamic> documentData = {};

          for (int j = 0; j < headers.length; j++) {
            String originalHeader = headers[j];
            String? mappedHeader = detectedColumns.entries
                .firstWhere(
                  (entry) => entry.value == originalHeader,
                  orElse: () => MapEntry(originalHeader, originalHeader),
                )
                .key;

            documentData[mappedHeader] = row[j];
          }

          documentData['name'] = documentData['name'] ?? 'Unnamed Item';

          // ✅ Correctly split multiple image URLs using ", https" as the separator
          if (documentData.containsKey('imageUrls')) {
            documentData['imageUrls'] = documentData['imageUrls']
                .toString()
                .split(RegExp(r',\s+(?=https)')) // Split only on ", https"
                .map((e) => e.trim()) // Trim spaces
                .toList();
          } else {
            documentData['imageUrls'] = ['https://via.placeholder.com/150'];
          }

          documentData['stock'] = true;

          if (!documentData.containsKey('Category')) {
            throw Exception("Missing 'Category' field in the CSV.");
          }

          final String category = documentData['Category'];
          documentData.remove('Category');

          await _firestore
              .collection('inventory')
              .doc(category)
              .set({'name': category}, SetOptions(merge: true));

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
      print("Error during CSV upload: $e");
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
