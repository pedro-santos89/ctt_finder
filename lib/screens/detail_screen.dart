/// Detail screen — shows full information for a single CTT location.
///
/// Includes a map header (SliverAppBar), address / schedule / phone /
/// services info cards, action buttons (directions, share, CTT website)
/// and a coordinate readout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ctt_location.dart';
import '../services/app_localizations.dart';

/// Full-page detail view for a [CttLocation].
///
/// The [location] parameter must be provided; it determines every piece
/// of UI content rendered on this screen.
class DetailScreen extends StatelessWidget {
  /// The location whose details are displayed.
  final CttLocation location;

  const DetailScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final isStation = location.isStation;
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Map header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: isStation
                ? const Color(0xFFD32F2F)
                : const Color(0xFFFF8F00),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.directions, color: Colors.white),
                onPressed: () => _openDirections(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: FlutterMap(
                options: MapOptions(
                  initialCenter: location.coordinates,
                  initialZoom: 16.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'pt.ctt.finder',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location.coordinates,
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isStation
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFFFF8F00),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            isStation ? Icons.store : Icons.mail,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isStation
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFFFF8F00))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          location.typeLabel,
                          style: TextStyle(
                            color: isStation
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFFFF8F00),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        location.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.district,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Info cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Address
                      _InfoCard(
                        icon: Icons.location_on,
                        title: l.address,
                        content: _buildAddressText(),
                      ),

                      // Schedule (stations only)
                      if (location.schedule != null)
                        _InfoCard(
                          icon: Icons.schedule,
                          title: l.schedule,
                          content: location.schedule!,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (location.openAfter18 == true)
                                _Badge(l.after18h, Colors.green),
                              if (location.openWeekends == true)
                                _Badge(l.weekends, Colors.blue),
                            ],
                          ),
                        ),

                      // Last collection (mailboxes)
                      if (location.lastCollection != null)
                        _InfoCard(
                          icon: Icons.access_time,
                          title: l.lastCollection,
                          content: location.lastCollection!,
                        ),

                      // Phone
                      if (location.phone != null)
                        _InfoCard(
                          icon: Icons.phone,
                          title: l.phone,
                          content: location.phone!,
                          onTap: () => _callPhone(),
                        ),

                      // Services
                      if (location.services.isNotEmpty)
                        _ServicesCard(services: location.services),

                      // Coordinates
                      _InfoCard(
                        icon: Icons.my_location,
                        title: l.coordinates,
                        content:
                            '${location.coordinates.latitude.toStringAsFixed(6)}, ${location.coordinates.longitude.toStringAsFixed(6)}',
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.directions),
                              label: Text(l.directions),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _openDirections,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.share),
                              label: Text(l.share),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD32F2F),
                                side: const BorderSide(
                                    color: Color(0xFFD32F2F)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _share(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // CTT website link
                      OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_browser),
                        label: Text(l.viewOnCttWebsite),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _openCttWebsite(),
                      ),

                      const SizedBox(height: 24),

                      // Creator signature
                      Center(
                        child: Text(
                          'Anima Rasa Prod. 2026',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a multi-line address string from the location’s fields,
  /// skipping any that are `null` or empty.
  String _buildAddressText() {
    final parts = <String>[location.address];
    if (location.postalCode != null) {
      parts.add(location.postalCode!);
    }
    if (location.locality != null) {
      parts.add(location.locality!);
    }
    if (location.municipality != null &&
        location.municipality != location.locality) {
      parts.add(location.municipality!);
    }
    if (location.district.isNotEmpty) {
      parts.add(location.district);
    }
    return parts.join('\n');
  }

  /// Opens Google Maps directions to this location.
  ///
  /// If geolocation permission is available, the user’s current
  /// position is set as the origin; otherwise Google Maps will
  /// prompt for it.
  Future<void> _openDirections() async {
    String origin = '';
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        origin = '&origin=${position.latitude},${position.longitude}';
      }
    } catch (_) {
      // Fall back to no origin — Google Maps will prompt for it
    }
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1$origin&destination=${location.coordinates.latitude},${location.coordinates.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Launches the phone dialler with the location’s phone number.
  Future<void> _callPhone() async {
    if (location.phone == null) return;
    final url = Uri.parse('tel:${location.phone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// Opens the CTT station-search website in the external browser.
  Future<void> _openCttWebsite() async {
    const url =
        'https://appserver2.ctt.pt/feapl_2/app/open/stationSearch/stationSearch.jspx?request_locale=pt';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Copies a shareable text (name + address + Google Maps link)
  /// to the snackbar.
  void _share(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text =
        '${location.name}\n${location.address}\n${location.district}\nhttps://www.google.com/maps/search/?api=1&query=${location.coordinates.latitude},${location.coordinates.longitude}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l.copied}: $text')),
    );
  }
}

/// Reusable info card with an icon, title, content and optional
/// trailing widget and tap callback.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFD32F2F), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      content,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 6),
                      trailing!,
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card that displays a list of service chips for a station.
class _ServicesCard extends StatelessWidget {
  final List<String> services;

  const _ServicesCard({required this.services});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.miscellaneous_services,
                    color: Color(0xFFD32F2F), size: 22),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context).services,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: services.map((service) {
                IconData icon;
                Color color;
                switch (service) {
                  case 'Banco CTT':
                    icon = Icons.account_balance;
                    color = const Color(0xFF1565C0);
                    break;
                  case 'Correio e Encomendas':
                    icon = Icons.local_shipping;
                    color = const Color(0xFFD32F2F);
                    break;
                  case 'Finanças e Pagamentos':
                    icon = Icons.payments;
                    color = const Color(0xFF2E7D32);
                    break;
                  case 'Certificados':
                    icon = Icons.verified;
                    color = const Color(0xFF6A1B9A);
                    break;
                  default:
                    icon = Icons.check_circle;
                    color = Colors.grey.shade700;
                }
                return Chip(
                  avatar: Icon(icon, size: 16, color: color),
                  label: Text(service, style: const TextStyle(fontSize: 12)),
                  backgroundColor: color.withValues(alpha: 0.08),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small coloured label used to indicate attributes like
/// "After 6 PM" or "Weekends".
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
