import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:landmark_records/landmark.dart';
import 'package:landmark_records/landmark_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditLandmarkScreen extends StatefulWidget {
  final Landmark landmark;

  const EditLandmarkScreen({super.key, required this.landmark});

  @override
  State<EditLandmarkScreen> createState() => _EditLandmarkScreenState();
}

class _EditLandmarkScreenState extends State<EditLandmarkScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.landmark.title);
    _latController = TextEditingController(text: widget.landmark.lat.toString());
    _lonController = TextEditingController(text: widget.landmark.lon.toString());
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800, maxHeight: 600);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<LandmarkProvider>(context, listen: false).updateLandmark(
          widget.landmark.id,
          _titleController.text,
          double.parse(_latController.text),
          double.parse(_lonController.text),
          _image?.path, // Pass the new image path, or null if not changed
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.landmark.title} updated')));
      } catch (e) {
        showDialog(context: context, builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to update landmark: ${e.toString()}'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Landmark'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildTextFormField(_titleController, 'Title', Icons.title),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextFormField(_latController, 'Latitude', Icons.gps_fixed, TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextFormField(_lonController, 'Longitude', Icons.gps_fixed, TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_as_rounded),
                label: const Text('Update Landmark'),
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _getImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: Colors.grey[400]!, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13.0),
          child: _image != null
              ? Image.file(_image!, fit: BoxFit.cover)
              : CachedNetworkImage(
                  imageUrl: widget.landmark.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.camera_alt, size: 50, color: Colors.grey), Text('Tap to change image')],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  TextFormField _buildTextFormField(TextEditingController controller, String label, IconData icon, [TextInputType? keyboardType]) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      validator: (value) => (value == null || value.isEmpty) ? 'Please enter a $label' : null,
    );
  }
}
