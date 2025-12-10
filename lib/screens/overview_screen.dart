import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:landmark_records/screens/edit_landmark_screen.dart';
import 'package:landmark_records/models/landmark.dart';
import 'package:landmark_records/providers/landmark_provider.dart';
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
        if (landmarkProvider.state == AppState.loading || landmarkProvider.state == AppState.initial) {
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, spreadRadius: 1)],
            ),
            child: Icon(Icons.location_pin, color: Theme.of(context).colorScheme.secondary, size: 24),
          ),
        ),
      ),
    );
  }

  void _showLandmarkBottomSheet(BuildContext context, Landmark landmark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: CachedNetworkImage(
                  imageUrl: landmark.image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white, height: 180),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(landmark.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${landmark.lat.toStringAsFixed(4)}, ${landmark.lon.toStringAsFixed(4)}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(icon: const Icon(Icons.edit_outlined), label: const Text("Edit"), onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, MaterialPageRoute(builder: (context) => EditLandmarkScreen(landmark: landmark)),
                    );
                  }),
                  TextButton.icon(icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error), label: Text("Delete", style: TextStyle(color: Theme.of(context).colorScheme.error)), onPressed: () {
                    Navigator.pop(context);
                    _confirmDelete(context, landmark);
                  }),
                ],
              )
            ],
          ),
        );
      },
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
