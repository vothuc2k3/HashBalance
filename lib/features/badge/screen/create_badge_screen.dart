import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:image_picker/image_picker.dart';

class CreateBadgeScreen extends ConsumerStatefulWidget {
  const CreateBadgeScreen({super.key});

  @override
  ConsumerState<CreateBadgeScreen> createState() => _CreateBadgeScreenState();
}

class _CreateBadgeScreenState extends ConsumerState<CreateBadgeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _imageFile;

  Future<void> _selectImage() async {
    final pickedFiles =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFiles != null) {
      setState(() {
        _imageFile = File(pickedFiles.path);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final threshold = int.tryParse(_thresholdController.text) ?? 0;
      final description = _descriptionController.text.trim();
      final imageFile = _imageFile;

      if (name.isEmpty) {
        showToast(false, "Please enter a badge name.");
        return;
      }

      if (threshold <= 0) {
        showToast(false, "Please enter a valid threshold.");
        return;
      }

      if (description.isEmpty) {
        showToast(false, "Please enter a description.");
        return;
      }

      if (imageFile == null) {
        showToast(false, "Please select an image.");
        return;
      }

      showToast(true, "Badge created successfully!");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(preferredThemeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.second,
        title: const Text("Create Badge"),
        elevation: 0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.first.withOpacity(0.8), theme.second],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Badge Name",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: "Enter badge name",
                  theme: theme,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Threshold",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _thresholdController,
                  hint: "Enter activity threshold",
                  theme: theme,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Description",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _descriptionController,
                  hint: "Enter badge description",
                  theme: theme,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Badge Image",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _imageFile == null
                    ? TextButton.icon(
                        onPressed: _selectImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined,
                            size: 28),
                        label: const Text("Select Image"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      )
                    : Column(
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () => setState(() {
                                  _imageFile = null;
                                }),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _selectImage,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Change Image"),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.approveButtonColor,
                  ),
                  child: const Text(
                    "Create Badge",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required ThemeColors theme,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "This field cannot be empty.";
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thresholdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
