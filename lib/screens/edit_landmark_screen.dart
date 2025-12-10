import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:landmark_records/models/landmark.dart';
import 'package:landmark_records/providers/landmark_provider.dart';
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
    final formatter = NumberFormat('#.######', 'en_US');
    _titleController = TextEditingController(text: widget.landmark.title);
    _latController = TextEditingController(text: formatter.format(widget.landmark.lat));
    _lonController = TextEditingController(text: formatter.format(widget.landmark.lon));
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
        final latString = _latController.text.replaceAll(',', '.');
        final lonString = _lonController.text.replaceAll(',', '.');

        await Provider.of<LandmarkProvider>(context, listen: false).updateLandmark(
          widget.landmark.id,
          _titleController.text,
          double.parse(latString),
          double.parse(lonString),
          _image?.path,
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
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
                    Expanded(child: _buildTextFormField(_latController, 'Latitude', Icons.gps_fixed, const TextInputType.numberWithOptions(decimal: true))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextFormField(_lonController, 'Longitude', Icons.gps_fixed, const TextInputType.numberWithOptions(decimal: true))),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_as_rounded),
                  label: const Text('Update Landmark'),
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
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
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13.0),
          child: _image != null
              ? Image.file(_image!, fit: BoxFit.cover, width: double.infinity)
              : CachedNetworkImage(
                  imageUrl: widget.landmark.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text('Tap to change image', style: TextStyle(color: Colors.grey[800])),
                      ],
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
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      validator: (value) => (value == null || value.isEmpty) ? 'Please enter a $label' : null,
    );
  }
}
