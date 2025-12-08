import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:landmark_records/landmark.dart';

class LandmarkProvider with ChangeNotifier {
  List<Landmark> _landmarks = [];

  List<Landmark> get landmarks => _landmarks;

  final List<Landmark> _defaultLandmarks = [
    Landmark(id: '1', title: 'Lalbagh Fort', lat: 23.7190, lon: 90.3888, image: 'lalbagh_fort.jpg'),
    Landmark(id: '2', title: 'Ahsan Manzil', lat: 23.7088, lon: 90.4072, image: 'ahsan_manzil.jpg'),
    Landmark(id: '3', title: 'Sundarbans', lat: 21.9497, lon: 89.1833, image: 'sundarbans.jpg'),
    Landmark(id: '4', title: 'Cox\'s Bazar', lat: 21.4272, lon: 92.0058, image: 'coxs_bazar.jpg'),
    Landmark(id: '5', title: 'Sajek Valley', lat: 23.3826, lon: 92.2934, image: 'sajek_valley.jpg'),
  ];

  Future<void> fetchLandmarks() async {
    try {
      final response = await http.get(Uri.parse('https://labs.anontech.info/cse489/t3/api.php'));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        if (jsonResponse.isEmpty) {
          _landmarks = _defaultLandmarks;
        } else {
          _landmarks = jsonResponse.map((landmark) => Landmark.fromJson(landmark)).toList();
        }
      } else {
        _landmarks = _defaultLandmarks;
      }
    } catch (e) {
      _landmarks = _defaultLandmarks;
    }
    notifyListeners();
  }

  Future<void> addLandmark(String title, double lat, double lon, String imagePath) async {
    var request = http.MultipartRequest('POST', Uri.parse('https://labs.anontech.info/cse489/t3/api.php'));
    request.fields['title'] = title;
    request.fields['lat'] = lat.toString();
    request.fields['lon'] = lon.toString();
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      fetchLandmarks();
    } else {
      throw Exception('Failed to add landmark');
    }
  }

  Future<void> deleteLandmark(String id) async {
    final response = await http.delete(Uri.parse('https://labs.anontech.info/cse489/t3/api.php?id=$id'));

    if (response.statusCode == 200) {
      fetchLandmarks();
    } else {
      throw Exception('Failed to delete landmark');
    }
  }

  Future<void> updateLandmark(String id, String title, double lat, double lon) async {
    final response = await http.put(
      Uri.parse('https://labs.anontech.info/cse489/t3/api.php'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: <String, String>{
        'id': id,
        'title': title,
        'lat': lat.toString(),
        'lon': lon.toString(),
      },
    );

    if (response.statusCode == 200) {
      fetchLandmarks();
    } else {
      throw Exception('Failed to update landmark');
    }
  }
}
