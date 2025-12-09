import 'package:flutter/material.dart';
import 'package:landmark_records/landmark.dart';
import 'package:landmark_records/landmark_repository.dart';

enum AppState { initial, loading, loaded, error }

class LandmarkProvider with ChangeNotifier {
  final LandmarkRepository _repository = LandmarkRepository();

  List<Landmark> _landmarks = [];
  AppState _state = AppState.initial;
  String _errorMessage = '';

  List<Landmark> get landmarks => _landmarks;
  AppState get state => _state;
  String get errorMessage => _errorMessage;

  Future<void> fetchLandmarks({bool isRefresh = false}) async {
    if (!isRefresh) {
      _state = AppState.loading;
      notifyListeners();
    }

    try {
      _landmarks = await _repository.fetchLandmarks();
      _state = AppState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AppState.error;
    }
    notifyListeners();
  }

  Future<void> addLandmark(String title, double lat, double lon, String imagePath) async {
    await _repository.addLandmark(title, lat, lon, imagePath);
    await fetchLandmarks(isRefresh: true);
  }

  Future<void> deleteLandmark(String id) async {
    await _repository.deleteLandmark(id);
    _landmarks.removeWhere((landmark) => landmark.id == id);
    notifyListeners();
  }

  Future<void> updateLandmark(String id, String title, double lat, double lon, [String? imagePath]) async {
    await _repository.updateLandmark(id, title, lat, lon, imagePath);
    await fetchLandmarks(isRefresh: true);
  }
}
