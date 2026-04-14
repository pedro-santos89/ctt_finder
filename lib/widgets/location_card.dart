/// Floating card overlay that summarises the selected CTT location.
///
/// Shown at the bottom of the [MapScreen] when the user taps a marker.
/// Displays name, type, address, schedule / last-collection time and
/// up to three service chips.  Tapping the card opens the detail screen.
library;

import 'package:flutter/material.dart';
import '../models/ctt_location.dart';
import '../services/app_localizations.dart';

/// Compact preview card for a [CttLocation].
///
/// [onTap] is triggered when the card body is tapped (opens detail).
/// [onClose] is triggered by the “×” icon button (deselects the marker).
class LocationCard extends StatelessWidget {
  /// The location to preview.
  final CttLocation location;

  /// Called when the user taps the card body.
  final VoidCallback onTap;

  /// Called when the user taps the close button.
  final VoidCallback onClose;

  const LocationCard({
    super.key,
    required this.location,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isStation = location.isStation;

    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isStation
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFFFF8F00),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isStation ? Icons.store : Icons.mail,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location.typeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: isStation
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFFFF8F00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Address
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${location.address}${location.locality != null ? ', ${location.locality}' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Schedule or last collection
              if (location.schedule != null || location.lastCollection != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location.schedule ??
                              '${AppLocalizations.of(context).lastCollectionLabel}: ${location.lastCollection}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              // Services chips (for stations)
              if (location.services.isNotEmpty && location.isStation)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: location.services.take(3).map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              // Tap hint
              Center(
                child: Text(
                  'Toque para ver detalhes →',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
