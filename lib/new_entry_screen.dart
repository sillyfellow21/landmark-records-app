import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _latController.text = position.latitude.toString();
      _lonController.text = position.longitude.toString();
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _image != null) {
      var request = http.MultipartRequest('POST', Uri.parse('https://labs.anontech.info/cse489/t3/api.php'));
      request.fields['title'] = _titleController.text;
      request.fields['lat'] = _latController.text;
      request.fields['lon'] = _lonController.text;
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Landmark added successfully!')));
        _formKey.currentState!.reset();
        setState(() {
          _image = null;
        });
      } else {
        showDialog(context: context, builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to add landmark. Please try again.'),
            actions: [
              TextButton(onPressed: () {Navigator.of(context).pop();}, child: Text('OK'))
            ],
          );
        });
      }
    } else {
        showDialog(context: context, builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please fill all fields and select an image.'),
            actions: [
              TextButton(onPressed: () {Navigator.of(context).pop();}, child: Text('OK'))
            ],
          );
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _latController,
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a latitude';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lonController,
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a longitude';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _image == null ? Text('No image selected.') : Image.file(_image!, height: 200),
              ElevatedButton(
                onPressed: _getImage,
                child: Text('Select Image'),
              ),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: Text('Get Current Location'),
              ),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Add Landmark'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
