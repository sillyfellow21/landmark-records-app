import 'package:flutter/material.dart';
import 'package:landmark_records/landmark.dart';
import 'package:landmark_records/landmark_provider.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.landmark.title);
    _latController = TextEditingController(text: widget.landmark.lat.toString());
    _lonController = TextEditingController(text: widget.landmark.lon.toString());
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await Provider.of<LandmarkProvider>(context, listen: false).updateLandmark(
        widget.landmark.id,
        _titleController.text,
        double.parse(_latController.text),
        double.parse(_lonController.text),
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.landmark.title} updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Landmark'),
      ),
      body: SingleChildScrollView(
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
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Update Landmark'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
