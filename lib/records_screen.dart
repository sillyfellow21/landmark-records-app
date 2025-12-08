import 'package:flutter/material.dart';
import 'package:landmark_records/edit_landmark_screen.dart';
import 'package:landmark_records/landmark.dart';
import 'package:landmark_records/landmark_provider.dart';
import 'package:provider/provider.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LandmarkProvider>(
      builder: (context, landmarkProvider, child) {
        if (landmarkProvider.landmarks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: landmarkProvider.landmarks.length,
          itemBuilder: (context, index) {
            final landmark = landmarkProvider.landmarks[index];
            final baseImageName = landmark.image.split('.').first.split('/').last;
            final localImagePathJpg = 'assets/images/$baseImageName.jpg';
            final localImagePathJpeg = 'assets/images/$baseImageName.jpeg';

            return Dismissible(
              key: Key(landmark.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.blue,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Icon(Icons.edit, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) { // Edit on swipe left
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditLandmarkScreen(landmark: landmark),
                    ),
                  );
                  return false; // Do not dismiss the item, just navigate
                } else { // Delete on swipe right
                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete ${landmark.title}?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                          TextButton(
                            child: const Text('Delete'),
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                          ),
                        ],
                      );
                    },
                  );
                  
                  if (confirmed == true) {
                    await Provider.of<LandmarkProvider>(context, listen: false).deleteLandmark(landmark.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${landmark.title} deleted')));
                    return true;
                  }
                  return false;
                }
              },
              child: Card(
                child: ListTile(
                  leading: Image.asset(
                    localImagePathJpg,
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // If .jpg fails, try .jpeg
                      return Image.asset(
                        localImagePathJpeg,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // If local assets fail, fall back to the network image.
                          return Image.network(
                            landmark.image,
                            width: 100,
                            fit: BoxFit.cover,
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
                  title: Text(landmark.title),
                  subtitle: Text('Lat: ${landmark.lat}, Lon: ${landmark.lon}'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
