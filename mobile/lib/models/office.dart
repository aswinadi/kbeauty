class Office {
  final int id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int radius;

  Office({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory Office.fromJson(Map<String, dynamic> json) {
    return Office(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radius: int.parse(json['radius'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }
}
