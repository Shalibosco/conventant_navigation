// lib/core/utils/helpers.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';

class Helpers {
  Helpers._();

  // ── Distance Calculation (Haversine Formula) ──────────────
  static double calculateDistance(
      double lat1, double lng1,
      double lat2, double lng2,
      ) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  // ── Format distance for display ───────────────────────────
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // ── Estimate walking time ─────────────────────────────────
  static String estimateWalkTime(double meters) {
    const walkingSpeedMps = 1.4; // average walking speed m/s
    final seconds = meters / walkingSpeedMps;
    final minutes = (seconds / 60).ceil();
    if (minutes < 1) return '< 1 min';
    return '$minutes min walk';
  }

  // ── Check if coordinates are within campus bounds ─────────
  static bool isWithinCampus(double lat, double lng) {
    return lat >= AppConstants.campusBoundSouth &&
        lat <= AppConstants.campusBoundNorth &&
        lng >= AppConstants.campusBoundWest &&
        lng <= AppConstants.campusBoundEast;
  }

  // ── Get category icon ─────────────────────────────────────
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case AppConstants.catAcademic:
        return Icons.school_rounded;
      case AppConstants.catHostel:
        return Icons.bed_rounded;
      case AppConstants.catWorship:
        return Icons.church_rounded;
      case AppConstants.catFood:
        return Icons.restaurant_rounded;
      case AppConstants.catSports:
        return Icons.sports_soccer_rounded;
      case AppConstants.catAdmin:
        return Icons.business_rounded;
      case AppConstants.catMedical:
        return Icons.local_hospital_rounded;
      case AppConstants.catRecreation:
        return Icons.park_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  // ── Get category color ────────────────────────────────────
  static Color getCategoryColor(String category) {
    switch (category) {
      case AppConstants.catAcademic:
        return const Color(0xFF1A3C6E);
      case AppConstants.catHostel:
        return const Color(0xFF8E44AD);
      case AppConstants.catWorship:
        return const Color(0xFFD4AF37);
      case AppConstants.catFood:
        return const Color(0xFFE67E22);
      case AppConstants.catSports:
        return const Color(0xFF27AE60);
      case AppConstants.catAdmin:
        return const Color(0xFF2C3E50);
      case AppConstants.catMedical:
        return const Color(0xFFE74C3C);
      case AppConstants.catRecreation:
        return const Color(0xFF16A085);
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  // ── LatLng helpers ────────────────────────────────────────
  static LatLng get campusCenter =>
      LatLng(AppConstants.campusLat, AppConstants.campusLng);

  // ── Snackbar helper ───────────────────────────────────────
  static void showSnackBar(
      BuildContext context,
      String message, {
        bool isError = false,
        Duration duration = const Duration(seconds: 3),
      }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  // ── Capitalize string ─────────────────────────────────────
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // ── Safe JSON parse ───────────────────────────────────────
  static T? safeParse<T>(dynamic value, T? fallback) {
    try {
      return value as T;
    } catch (_) {
      return fallback;
    }
  }
}