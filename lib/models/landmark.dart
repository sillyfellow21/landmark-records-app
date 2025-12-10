class Landmark {
  final String id;
  final String title;
  final double lat;
  final double lon;
  final String image;

  Landmark({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    required this.image,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lon: double.tryParse(json['lon'].toString()) ?? 0.0,
      image: json['image'] ?? '',
    );
  }
}
