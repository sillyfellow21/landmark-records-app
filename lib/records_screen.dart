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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
            return _confirmDelete(context, landmark);
          }
        },
        child: Card(
          elevation: 5.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              _buildCardImage(localImagePathJpg, localImagePathJpeg, landmark.image),
              _buildGradientOverlay(),
              _buildCardText(context, landmark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(String pathJpg, String pathJpeg, String networkUrl) {
    return Image.asset(
      pathJpg, height: 200, width: double.infinity, fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          pathJpeg, height: 200, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CachedNetworkImage(
              imageUrl: networkUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[400]!, highlightColor: Colors.grey[200]!,
                child: Container(color: Colors.white, height: 200),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200, color: Colors.grey[300],
                child: Icon(Icons.broken_image_outlined, color: Colors.grey[600], size: 50),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: const [0.0, 0.5],
        ),
      ),
    );
  }

  Widget _buildCardText(BuildContext context, Landmark landmark) {
    return Positioned(
      bottom: 16.0,
      left: 16.0,
      right: 16.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            landmark.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 4),
              Text(
                '${landmark.lat.toStringAsFixed(4)}, ${landmark.lon.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15.0),
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
            TextButton(child: const Text('Delete'), onPressed: () async {
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
