class LoginEvent {
  final int? id;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;
  final bool isTrusted;

  const LoginEvent({
    this.id,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.city,
    this.country,
    this.isTrusted = false,
  });

  String get locationDisplay {
    final parts = [city, country].whereType<String>().toList();
    if (parts.isNotEmpty) return parts.join(', ');
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(3)}°, ${longitude!.toStringAsFixed(3)}°';
    }
    return 'Unknown location';
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  LoginEvent copyWith({bool? isTrusted}) {
    return LoginEvent(
      id:        id,
      timestamp: timestamp,
      latitude:  latitude,
      longitude: longitude,
      city:      city,
      country:   country,
      isTrusted: isTrusted ?? this.isTrusted,
    );
  }

  Map<String, Object?> toMap() => {
        'timestamp':  timestamp.toIso8601String(),
        'latitude':   latitude,
        'longitude':  longitude,
        'city':       city,
        'country':    country,
        'is_trusted': isTrusted ? 1 : 0,
      };

  factory LoginEvent.fromMap(Map<String, Object?> map) {
    return LoginEvent(
      id:        map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude:  map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      city:      map['city'] as String?,
      country:   map['country'] as String?,
      isTrusted: (map['is_trusted'] as int? ?? 0) == 1,
    );
  }
}
