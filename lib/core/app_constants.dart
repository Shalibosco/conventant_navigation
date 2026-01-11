import 'package:latlong2/latlong.dart';

class AppConstants {
  // Campus coordinates
  static const double campusLatitude = 6.6700;
  static const double campusLongitude = 3.1575;
  static const double campusRadius = 2373.0;

  // Map tile URL
  static const String mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Campus boundary polygon
  static final List<List<double>> campusBoundary = [
    [6.6715, 3.1560],
    [6.6690, 3.1550],
    [6.6680, 3.1580],
    [6.6710, 3.1600],
    [6.6715, 3.1560], // Close the polygon
  ];

  // Campus locations - FIXED TYPE
  static const Map<String, Map<String, dynamic>> campusLocations = {
    'chapel': {
      'name': 'University Chapel',
      'lat': 6.6712,
      'lng': 3.1570,
    },
    'library': {
      'name': 'Covenant University Library',
      'lat': 6.6695,
      'lng': 3.1565,
    },
    'cafeteria': {
      'name': 'Student Cafeteria',
      'lat': 6.6685,
      'lng': 3.1585,
    },
    'admin': {
      'name': 'Administration Building',
      'lat': 6.6702,
      'lng': 3.1568,
    },
  };
}