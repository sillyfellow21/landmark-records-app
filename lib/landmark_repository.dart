import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:landmark_records/app_constants.dart';
import 'package:landmark_records/database_helper.dart';
import 'package:landmark_records/landmark.dart';

class LandmarkRepository {
  final dbHelper = DatabaseHelper.instance;
  final String _apiUrl = AppConstants.apiBaseUrl;

  final List<Landmark> _defaultLandmarks = [
    Landmark(id: '1', title: 'Lalbagh Fort', lat: 23.7190, lon: 90.3888, image: 'lalbagh_fort.jpg'),
    Landmark(id: '2', title: 'Ahsan Manzil', lat: 23.7088, lon: 90.4072, image: 'ahsan_manzil.jpg'),
    Landmark(id: '3', title: 'Sundarbans', lat: 21.9497, lon: 89.1833, image: 'sundarbans.jpg'),
    Landmark(id: '4', title: 'Cox\'s Bazar', lat: 21.4272, lon: 92.0058, image: 'coxs_bazar.jpg'),
    Landmark(id: '5', title: 'Sajek Valley', lat: 23.3826, lon: 92.2934, image: 'sajek_valley.jpg'),
  ];

  Future<List<Landmark>> fetchLandmarks() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        if (jsonResponse.isEmpty) {
          return _defaultLandmarks;
        } else {
          final landmarks = jsonResponse.map((landmark) => Landmark.fromJson(landmark)).toList();
          await _cacheLandmarks(landmarks);
          return landmarks;
        }
      } else {
        return _getCachedLandmarks();
      }
    } catch (e) {
      return _getCachedLandmarks();
    }
  }

  Future<void> _cacheLandmarks(List<Landmark> landmarks) async {
    await dbHelper.clearLandmarks();
    for (var landmark in landmarks) {
      await dbHelper.insertLandmark(landmark);
    }
  }

  Future<List<Landmark>> _getCachedLandmarks() async {
    final cached = await dbHelper.getLandmarks();
    return cached.isNotEmpty ? cached : _defaultLandmarks;
  }

  Future<void> addLandmark(String title, double lat, double lon, String imagePath) async {
    var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.fields['title'] = title;
    request.fields['lat'] = lat.toString();
    request.fields['lon'] = lon.toString();
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to add landmark');
    }
  }

  Future<void> deleteLandmark(String id) async {
    final response = await http.delete(Uri.parse('$_apiUrl?id=$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete landmark');
    }
  }

  Future<void> updateLandmark(String id, String title, double lat, double lon, [String? imagePath]) async {
    if (imagePath == null) {
      final response = await http.put(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': id, 'title': title, 'lat': lat.toString(), 'lon': lon.toString()},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update landmark text data');
      }
    } else {
      var request = http.MultipartRequest('PUT', Uri.parse(_apiUrl));
      request.fields['id'] = id;
      request.fields['title'] = title;
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lon.toString();
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      var response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('Failed to update landmark with image. The server may not support multipart PUT requests.');
      }
    }
  }
}
