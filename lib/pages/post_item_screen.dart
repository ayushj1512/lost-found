import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' show sha1;

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final trainController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String selectedType = 'Lost';
  String selectedCategory = 'Wallet';
  File? selectedImage;
  bool isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      final apiKey = dotenv.env['API_KEY'];
      final apiSecret = dotenv.env['API_SECRET'];

      if (cloudName == null || apiKey == null || apiSecret == null) {
        debugPrint("Missing Cloudinary credentials in .env");
        return null;
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

      final signatureRaw = 'timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(signatureRaw)).toString();

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final data = jsonDecode(resStr);
        return data['secure_url'];
      } else {
        debugPrint("Cloudinary upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary exception: $e");
      return null;
    }
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an image"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isUploading = true);

    final imageUrl = await _uploadToCloudinary(selectedImage!);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image upload failed"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isUploading = false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final itemRef = FirebaseFirestore.instance.collection('items').doc();

    await itemRef.set({
      'type': selectedType,
      'title': titleController.text.trim(),
      'description': descController.text.trim(),
      'photoUrl': imageUrl,
      'trainNumber': trainController.text.trim(),
      'station': trainController.text.trim(),
      'category': selectedCategory,
      'date': DateTime.now().toIso8601String().split('T').first,
      'postedBy': user.displayName ?? 'Anonymous',
      'status': 'open',
      'timest': Timestamp.now(),
      'uid': user.uid,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item Posted Successfully!'),
        backgroundColor: Color.fromARGB(255, 101, 101, 196),
      ),
    );
    titleController.clear();
    descController.clear();
    trainController.clear();
    setState(() {
      selectedImage = null;
      selectedType = 'Lost';
      selectedCategory = 'Wallet';
      isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Post an Item'),
        backgroundColor: const Color.fromARGB(255, 101, 101, 196),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Type Capsule Buttons
              const Text(
                "Type",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: ["Lost", "Found"].map((t) {
                  final isSelected = selectedType == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: isSelected,
                      onSelected: (_) => setState(() => selectedType = t),
                      selectedColor: const Color.fromARGB(255, 101, 101, 196),
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              /// Title
              TextFormField(
                controller: titleController,
                decoration: _inputDecoration('Title', Icons.title),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),

              /// Description
              TextFormField(
                controller: descController,
                decoration: _inputDecoration('Description', Icons.description),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),

              /// Category Dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['Wallet', 'Electronics', 'Documents', 'Clothing']
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                             
                              const SizedBox(width: 8),
                              Text(c),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
                decoration: _inputDecoration('Category', Icons.category),
              ),
              const SizedBox(height: 16),

              /// Train / Station
              TextFormField(
                controller: trainController,
                decoration: _inputDecoration('Train No. / Station', Icons.train),
              ),
              const SizedBox(height: 24),

              /// Image Upload
              Text(
                'Upload Photo',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey[100],
                  ),
                  child: selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cloud_upload,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload image',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),

              /// Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : _submitItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 101, 101, 196),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    isUploading ? 'Uploading...' : 'Submit Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color.fromARGB(255, 101, 101, 196), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
