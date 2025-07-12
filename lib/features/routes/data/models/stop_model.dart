// lib/features/routes/data/models/stop_model.dart
import '../../domain/entities/stop.dart';

class StopModel extends Stop {
  const StopModel({
    required int id,
    required String stopName,
    required double latitude,
    required double longitude,
    String? address,
    required bool isMajor,
    required String status,
  }) : super(
         id: id,
         stopName: stopName,
         latitude: latitude,
         longitude: longitude,
         address: address,
         isMajor: isMajor,
         status: status,
       );

  factory StopModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🏪 Parsing stop JSON: $json');

      // Handle different possible field names from the API
      final stopId = _parseIntField(json, ['stop_id', 'id']);
      final stopName =
          _parseStringField(json, ['stop_name', 'name']) ?? 'Unknown Stop';
      final latitude = _parseDoubleField(json, ['latitude', 'lat']) ?? 0.0;
      final longitude =
          _parseDoubleField(json, ['longitude', 'lng', 'lon']) ?? 0.0;
      final address = _parseStringField(json, ['address', 'location']);
      final isMajor = _parseBoolField(json, ['is_major', 'major']) ?? false;
      final status = _parseStringField(json, ['status']) ?? 'active';

      if (stopId == null) {
        throw FormatException('Stop ID is required but not found in: $json');
      }

      print(
        '✅ Parsed stop: ID=$stopId, Name=$stopName, Lat=$latitude, Lng=$longitude, Major=$isMajor',
      );

      return StopModel(
        id: stopId,
        stopName: stopName,
        latitude: latitude,
        longitude: longitude,
        address: address,
        isMajor: isMajor,
        status: status,
      );
    } catch (e) {
      print('❌ Error parsing stop from JSON: $e');
      print('❌ JSON was: $json');
      rethrow;
    }
  }

  // Helper methods for safe parsing
  static int? _parseIntField(
    Map<String, dynamic> json,
    List<String> possibleKeys,
  ) {
    for (final key in possibleKeys) {
      final value = json[key];
      if (value != null) {
        if (value is int) return value;
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
        if (value is double) return value.toInt();
      }
    }
    return null;
  }

  static double? _parseDoubleField(
    Map<String, dynamic> json,
    List<String> possibleKeys,
  ) {
    for (final key in possibleKeys) {
      final value = json[key];
      if (value != null) {
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  static String? _parseStringField(
    Map<String, dynamic> json,
    List<String> possibleKeys,
  ) {
    for (final key in possibleKeys) {
      final value = json[key];
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  static bool? _parseBoolField(
    Map<String, dynamic> json,
    List<String> possibleKeys,
  ) {
    for (final key in possibleKeys) {
      final value = json[key];
      if (value != null) {
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) {
          return value.toLowerCase() == 'true' || value == '1';
        }
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'stop_id': id,
      'stop_name': stopName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'is_major': isMajor,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'StopModel(id: $id, stopName: $stopName, latitude: $latitude, longitude: $longitude, isMajor: $isMajor)';
  }
}
