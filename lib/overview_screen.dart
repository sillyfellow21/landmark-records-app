// Final fix to ensure compatibility with older packages.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:landmark_records/edit_landmark_screen.dart';
import 'package:landmark_records/landmark.dart';
import 'package:landmark_records/landmark_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LandmarkProvider>(
      builder: (context, landmarkProvider, child) {
        if (landmarkProvider.state == AppState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return FlutterMap(
          options: const MapOptions(
            initialCenter: latLng.LatLng(23.6850, 90.3563),
            initialZoom: 7.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            _buildMarkerClusterLayer(context, landmarkProvider.landmarks),
          ],
        );
      },
    );
  }

  MarkerClusterLayerWidget _buildMarkerClusterLayer(BuildContext context, List<Landmark> landmarks) {
    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        maxClusterRadius: 80,
        size: const Size(40, 40),
        markers: landmarks.map((landmark) => _buildAnimatedMarker(context, landmark)).toList(),
        builder: (context, markers) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor,
            ),
            child: Center(
              child: Text(
                markers.length.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Marker _buildAnimatedMarker(BuildContext context, Landmark landmark) {
    return Marker(
      width: 40.0,
      height: 40.0,
      point: latLng.LatLng(landmark.lat, landmark.lon),
      child: GestureDetector(
        onTap: () => _showLandmarkBottomSheet(context, landmark),
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).primaryColor, width: 3),
            ),
            child: const Icon(Icons.location_pin, color: Colors.redAccent, size: 20),
          ),
        ),
      ),
    );
  }

  void _showLandmarkBottomSheet(BuildContext context, Landmark landmark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildBottomSheetImage(landmark),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(icon: const Icon(Icons.edit), label: const Text("Edit"), onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditLandmarkScreen(landmark: landmark)))
                            .then((_) => Provider.of<LandmarkProvider>(context, listen: false).fetchLandmarks(isRefresh: true));
                        }),
                        ElevatedButton.icon(icon: const Icon(Icons.delete), label: const Text("Delete"), onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(context, landmark);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetImage(Landmark landmark) {
    final baseImageName = landmark.image.split('.').first.split('/').last;
    final localImagePathJpg = 'assets/images/$baseImageName.jpg';
    final localImagePathJpeg = 'assets/images/$baseImageName.jpeg';

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Image.asset(
            localImagePathJpg, height: 250, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                localImagePathJpeg, height: 250, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return CachedNetworkImage(
                    imageUrl: landmark.image, height: 250, width: double.infinity, fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[400]!, highlightColor: Colors.grey[200]!,
                      child: Container(color: Colors.white, height: 250),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 250, color: Colors.grey[300],
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey[600], size: 50),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.center,
              ),
            ),
            child: Text(
              landmark.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Landmark landmark) {
    showDialog<bool>(
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
                Navigator.of(dialogContext).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${landmark.title} deleted')));
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
