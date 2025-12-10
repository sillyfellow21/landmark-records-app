import 'package:flutter/material.dart';
import 'package:landmark_records/screens/edit_landmark_screen.dart';
import 'package:landmark_records/models/landmark.dart';
import 'package:landmark_records/providers/landmark_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LandmarkProvider>(
      builder: (context, landmarkProvider, child) {
        if (landmarkProvider.state == AppState.initial || landmarkProvider.state == AppState.loading) {
          return _buildShimmerLoading(context);
        }

        if (landmarkProvider.state == AppState.error) {
          return Center(child: Text('Error: ${landmarkProvider.errorMessage}'));
        }

        if (landmarkProvider.landmarks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No landmarks found.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => landmarkProvider.fetchLandmarks(isRefresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(12.0),
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

  Widget _buildShimmerLoading(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      bottomLeft: Radius.circular(12.0),
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
          ),
        );
      },
    );
  }

  Widget _buildLandmarkCard(BuildContext context, Landmark landmark) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Dismissible(
        key: Key(landmark.id),
        background: _buildDismissibleBackground(Colors.red, Icons.delete, Alignment.centerLeft),
        secondaryBackground: _buildDismissibleBackground(Theme.of(context).colorScheme.secondary, Icons.edit, Alignment.centerRight),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) { // Edit
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditLandmarkScreen(landmark: landmark)),
            );
            return false;
          } else { // Delete
            return _confirmDelete(context, landmark);
          }
        },
        child: Row(
          children: [
            _buildCardImage(landmark.image),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(landmark.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${landmark.lat.toStringAsFixed(4)}, ${landmark.lon.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(String networkUrl) {
    return CachedNetworkImage(
      imageUrl: networkUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white, width: 100, height: 100),
      ),
      errorWidget: (context, url, error) => Container(
        width: 100,
        height: 100,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40),
      ),
    );
  }

  Widget _buildDismissibleBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Landmark landmark) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${landmark.title}?'),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop(false)),
            TextButton(child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)), onPressed: () async {
              try {
                await Provider.of<LandmarkProvider>(context, listen: false).deleteLandmark(landmark.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${landmark.title} deleted')));
                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                Navigator.of(dialogContext).pop(false);
                showDialog(context: context, builder: (context) => AlertDialog(
                  title: const Text('Error'),
                  content: Text('Failed to delete landmark: ${e.toString()}'),
                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                ));
              }
            }),
          ],
        );
      },
    );
  }
}
