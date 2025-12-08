import 'package:flutter/material.dart';
import 'package:landmark_records/edit_landmark_screen.dart';
import 'package:landmark_records/landmark.dart';
import 'package:landmark_records/landmark_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LandmarkProvider>(
      builder: (context, landmarkProvider, child) {
        if (landmarkProvider.state == AppState.loading) {
          return _buildShimmerLoading();
        }

        if (landmarkProvider.state == AppState.error) {
          return Center(child: Text('Error: ${landmarkProvider.errorMessage}'));
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15.0),
                      bottomLeft: Radius.circular(15.0),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: double.infinity, height: 20, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 150, height: 16, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLandmarkCard(BuildContext context, Landmark landmark) {
    final baseImageName = landmark.image.split('.').first.split('/').last;
    final localImagePathJpg = 'assets/images/$baseImageName.jpg';
    final localImagePathJpeg = 'assets/images/$baseImageName.jpeg';

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Dismissible(
        key: Key(landmark.id),
        background: _buildDismissibleBackground(Colors.red, Icons.delete, Alignment.centerLeft),
        secondaryBackground: _buildDismissibleBackground(Colors.blue, Icons.edit, Alignment.centerRight),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) { // Edit
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditLandmarkScreen(landmark: landmark)),
            ).then((_) => Provider.of<LandmarkProvider>(context, listen: false).fetchLandmarks(isRefresh: true));
            return false;
          } else { // Delete
            final bool? confirmed = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: Text('Are you sure you want to delete ${landmark.title}?'),
                  actions: <Widget>[
                    TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
                    TextButton(child: const Text('Delete'), onPressed: () => Navigator.of(context).pop(true)),
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15.0), bottomLeft: Radius.circular(15.0)),
              child: Image.asset(
                localImagePathJpg,
                width: 120, height: 120, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    localImagePathJpeg, width: 120, height: 120, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return CachedNetworkImage(
                        imageUrl: landmark.image,
                        width: 120, height: 120, fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120, height: 120, color: Colors.grey[300],
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey[600], size: 40),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(landmark.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${landmark.lat.toStringAsFixed(4)}, ${landmark.lon.toStringAsFixed(4)}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15.0)),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Icon(icon, color: Colors.white),
    );
  }
}
