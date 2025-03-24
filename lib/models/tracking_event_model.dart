import 'package:flutter/material.dart';
import '../widgets/shipment_tracking_timeline.dart';

class TrackingEvent {
  final String id;
  final ShipmentStatus status;
  final DateTime timestamp;
  final String location;
  final String description;
  final IconData icon;

  TrackingEvent({
    required this.id,
    required this.status,
    required this.timestamp,
    required this.location,
    required this.description,
    required this.icon,
  });
}

