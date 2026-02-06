import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

/// Servicio de geolocalización para validar que el usuario esté dentro del campus
class GeolocationService {
  /// Verifica si los servicios de ubicación están habilitados
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Solicita permisos de ubicación
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Obtiene la ubicación actual del dispositivo
  static Future<Position?> getCurrentLocation() async {
    try {
      // Verificar permisos primero
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        return null;
      }

      // Verificar si el servicio está habilitado
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calcula la distancia entre dos puntos usando la fórmula de Haversine
  static double _calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    const earthRadius = 6371000; // Radio de la Tierra en metros

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
         sin(dLon / 2) * sin(dLon / 2));
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Verifica si el usuario está dentro del geofence de la universidad
  static Future<bool> isWithinUniversityCampus() async {
    try {
      final position = await getCurrentLocation();
      
      if (position == null) {
        return false;
      }

      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        AppConstants.ucLatitude,
        AppConstants.ucLongitude,
      );

      return distance <= AppConstants.geofenceRadiusMeters;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la distancia actual a la universidad en metros
  static Future<double?> getDistanceToUniversity() async {
    try {
      final position = await getCurrentLocation();
      
      if (position == null) {
        return null;
      }

      return _calculateDistance(
        position.latitude,
        position.longitude,
        AppConstants.ucLatitude,
        AppConstants.ucLongitude,
      );
    } catch (e) {
      return null;
    }
  }

  /// Mensaje de estado de ubicación para mostrar al usuario
  static Future<String> getLocationStatusMessage() async {
    final isEnabled = await isLocationServiceEnabled();
    
    if (!isEnabled) {
      return 'Por favor, active los servicios de ubicación para votar.';
    }

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      return 'Por favor, permita el acceso a la ubicación.';
    }

    final isWithinCampus = await isWithinUniversityCampus();
    final distance = await getDistanceToUniversity();

    if (isWithinCampus) {
      return 'Ubicación verificada: Está dentro del campus.';
    } else if (distance != null) {
      final distanceKm = (distance / 1000).toStringAsFixed(2);
      return 'Error: Está a ${distanceKm}km de la universidad. Debe estar dentro del campus para votar.';
    } else {
      return 'No se pudo verificar su ubicación. Asegúrese de estar en el campus.';
    }
  }
}
