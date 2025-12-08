import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:landmark_records/edit_landmark_screen.dart';
import 'package:landmark_records/landmark.dart';
import 'package:landmark_records/landmark_provider.dart';
import 'package:provider/provider.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  void _showBottomSheet(BuildContext context, Landmark landmark) {
    final baseImageName = landmark.image.split('.').first.split('/').last;
    final localImagePathJpg = 'assets/images/$baseImageName.jpg';
    final localImagePathJpeg = 'assets/images/$baseImageName.jpeg';

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(landmark.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Image.asset(
                  localImagePathJpg,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    // If .jpg fails, try .jpeg
                    return Image.asset(
                      localImagePathJpeg,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        // If local assets fail, fall back to the network image.
                        return Image.network(
                          landmark.image,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            // If the network image also fails, show a placeholder.
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: Icon(Icons.broken_image, color: Colors.grey[600]),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditLandmarkScreen(landmark: landmark),
                          ),
                        );
                      },
                      child: Text("Edit"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet
                        showDialog<bool>(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text('Are you sure you want to delete ${landmark.title}?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(false);
                                  },
                                ),
                                TextButton(
                                  child: const Text('Delete'),
                                  onPressed: () {
                                    Provider.of<LandmarkProvider>(context, listen: false).deleteLandmark(landmark.id);
                                    Navigator.of(dialogContext).pop(true);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${landmark.title} deleted')));
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text("Delete"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LandmarkProvider>(
      builder: (context, landmarkProvider, child) {
        if (landmarkProvider.landmarks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return FlutterMap(
          options: MapOptions(
            initialCenter: latLng.LatLng(23.6850, 90.3563),
            initialZoom: 7.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.landmark_records',
            ),
            MarkerLayer(
              markers: landmarkProvider.landmarks.map((landmark) {
                return Marker(
                  width: 80.0,
                  height: 80.0,
                  point: latLng.LatLng(landmark.lat, landmark.lon),
                  child: GestureDetector(
                    onTap: () {
                      _showBottomSheet(context, landmark);
                    },
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40.0,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
