import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:landmark_records/providers/landmark_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  File? _image;
  final picker = ImagePicker();

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800, maxHeight: 600);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final formatter = NumberFormat('#.######', 'en_US');
        setState(() {
          _latController.text = formatter.format(position.latitude);
          _lonController.text = formatter.format(position.longitude);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not fetch location: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission is required to get current location.')));
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image.')));
        return;
      }
      try {
        final latString = _latController.text.replaceAll(',', '.');
        final lonString = _lonController.text.replaceAll(',', '.');

        await Provider.of<LandmarkProvider>(context, listen: false).addLandmark(
          _titleController.text,
          double.parse(latString),
          double.parse(lonString),
          _image!.path,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Landmark added successfully!')));
        _formKey.currentState!.reset();
        setState(() => _image = null);
      } catch (e) {
        showDialog(context: context, builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to add landmark: ${e.toString()}'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.my_location, size: 20),
                label: const Text('Get Current Location'),
                onPressed: _getCurrentLocation,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('Add Landmark'),
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
        child: _image != null
            ? ClipRRect(borderRadius: BorderRadius.circular(13.0), child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity))
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text('Tap to select an image', style: TextStyle(color: Colors.grey[800])),
                  ],
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
