import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:landmark_records/models/landmark.dart';
import 'package:landmark_records/utils/app_constants.dart';
import 'package:landmark_records/database/database_helper.dart';

class LandmarkRepository {
  final dbHelper = DatabaseHelper.instance;
  final String _apiUrl = AppConstants.apiBaseUrl;
  final Dio _dio = Dio();

  Future<List<Landmark>> fetchLandmarks() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        final landmarks = jsonResponse.map((data) => Landmark.fromJson(data)).toList();
        await _cacheLandmarks(landmarks); // Cache the new data
        return landmarks;
      } else {
        // On API failure, try to load from cache
        return _getCachedLandmarks();
      }
    } catch (e) {
      // On network error, try to load from cache
      debugPrint('Fetch Landmarks Error: $e');
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
    return cached; // Return whatever is in the cache, even if it's empty.
  }

  Future<String> addLandmark(String title, double lat, double lon, String imagePath) async {
    var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.fields['title'] = title;
    request.fields['lat'] = lat.toStringAsFixed(6);
    request.fields['lon'] = lon.toStringAsFixed(6);

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
