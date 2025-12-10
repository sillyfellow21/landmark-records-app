import 'package:flutter/material.dart';
import 'package:landmark_records/models/landmark.dart';
import 'package:landmark_records/providers/landmark_provider.dart';
import 'package:landmark_records/screens/edit_landmark_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LandmarkProvider>(
      builder: (context, landmarkProvider, child) {
        if (landmarkProvider.state == AppState.loading || landmarkProvider.state == AppState.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (landmarkProvider.state == AppState.error) {
          return Center(child: Text('Error: ${landmarkProvider.errorMessage}'));
        }

        if (landmarkProvider.landmarks.isEmpty) {
          return const Center(
            child: Text('No landmarks found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          );
        }

        return RefreshIndicator(
          onRefresh: () => landmarkProvider.fetchLandmarks(isRefresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: landmarkProvider.landmarks.length,
            itemBuilder: (context, index) {
              final landmark = landmarkProvider.landmarks[index];
              return _buildLandmarkCard(context, landmark);
            },
          ),
        );
      },
    );
  }

  Widget _buildLandmarkCard(BuildContext context, Landmark landmark) {
    return Dismissible(
      key: Key(landmark.id),
      background: _buildDismissibleBackground(Colors.red, Icons.delete, Alignment.centerLeft),
      secondaryBackground: _buildDismissibleBackground(Colors.blue, Icons.edit, Alignment.centerRight),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditLandmarkScreen(landmark: landmark)),
          );
          return false; // Do not dismiss the card, just navigate
        } else {
          return await _confirmDelete(context, landmark);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CachedNetworkImage(
                  imageUrl: landmark.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      landmark.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${landmark.lat.toStringAsFixed(4)}, ${landmark.lon.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Icon(icon, color: Colors.white),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Landmark landmark) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${landmark.title}"?'),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop(false)),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () async { // Make onPressed async
                try {
                  await Provider.of<LandmarkProvider>(context, listen: false).deleteLandmark(landmark.id);
                  Navigator.of(dialogContext).pop(true); // Close the dialog and dismiss the card
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${landmark.title}" deleted successfully')),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop(false); // Close the dialog but do not dismiss
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error'),
                      content: Text('Failed to delete landmark: ${e.toString()}'),
                      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
