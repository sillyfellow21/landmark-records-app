class Landmark {
  final String id;
  final String title;
  final double lat;
  final double lon;
  final String image;

  Landmark({required this.id, required this.title, required this.lat, required this.lon, required this.image});

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: json['id'],
      title: json['title'],
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
      image: json['image'],
    );
  }
}
