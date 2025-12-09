import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  Future<String> addLandmark(String title, double lat, double lon, String imagePath) async {
    var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.fields['title'] = title;
    request.fields['lat'] = lat.toStringAsFixed(6);
    request.fields['lon'] = lon.toStringAsFixed(6);
    
    // Diagnostic print to see the exact data being sent.
    debugPrint('---- Sending ADD Landmark Request ----');
    debugPrint('URL: ${request.url}');
    debugPrint('Method: ${request.method}');
    debugPrint('Fields: ${request.fields}');
    debugPrint('File path: ${imagePath}');

    final fileBytes = await File(imagePath).readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'image', 
      fileBytes,
      filename: 'landmark_image.jpg',
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(multipartFile);

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    debugPrint('---- Received Response ----');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('---------------------------');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return responseData['id'].toString();
    } else {
      throw Exception('Failed to add landmark. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> deleteLandmark(String id) async {
    final response = await http.delete(Uri.parse('$_apiUrl?id=$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete landmark');
    }
  }

  Future<void> updateLandmark(String id, String title, double lat, double lon, [String? imagePath]) async {
    // ... (update logic remains the same for now)
    final latString = lat.toStringAsFixed(6);
    final lonString = lon.toStringAsFixed(6);

    if (imagePath == null) {
      final response = await http.put(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id': id, 'title': title, 'lat': latString, 'lon': lonString},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update landmark text data. Status: ${response.statusCode}');
      }
    } else {
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.fields['id'] = id;
      request.fields['title'] = title;
      request.fields['lat'] = latString;
      request.fields['lon'] = lonString;
      
      final fileBytes = await File(imagePath).readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image', 
        fileBytes, 
        filename: 'landmark_image.jpg', 
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update landmark with image. Status: ${response.statusCode}');
      }
    }
  }
}
