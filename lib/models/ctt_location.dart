/// Data model for CTT locations (stores, access points and mailboxes).
///
/// Every result returned by the CTT search API is mapped into a
/// [CttLocation] instance that holds the geographic coordinates,
/// address information, schedule, available services and type metadata.
library;

import 'package:latlong2/latlong.dart';

/// High-level classification of a CTT location.
enum CttLocationType {
  /// Physical CTT store or access point (Loja CTT / Ponto CTT).
  station,

  /// Mail collection box (Marco de Correio / Caixa de Correio).
  mailbox,
}

/// Fine-grained station sub-types as reported by the CTT website.
enum StationType {
  /// Full-service CTT store.
  lojaCtt,

  /// Smaller partner-operated CTT access point.
  pontoCtt,

  /// Postal partner point.
  pontoCorreios,

  /// CTT store co-located with a tax-office ("Finanças").
  lojaFinancas,

  /// Any other station type not explicitly categorised.
  outro,
}

/// Fine-grained mailbox sub-types.
enum MailboxType {
  /// Standalone red mailbox pillar ("marco de correio").
  marco,

  /// Wall-mounted or smaller collection box ("caixa de correio").
  caixa,
}

/// Represents a single CTT location (station or mailbox).
///
/// Instances are created by [CttService] when it parses the HTML
/// response from the CTT search endpoint.
class CttLocation {
  /// Unique identifier generated during parsing (e.g. "st_0_38.7270").
  final String id;

  /// Human-readable name of the location.
  final String name;

  /// Whether this is a [CttLocationType.station] or [CttLocationType.mailbox].
  final CttLocationType type;

  /// Station sub-type — only meaningful when [type] is [CttLocationType.station].
  final StationType? stationType;

  /// Mailbox sub-type — only meaningful when [type] is [CttLocationType.mailbox].
  final MailboxType? mailboxType;

  /// GPS coordinates (latitude / longitude).
  final LatLng coordinates;

  /// Street address.
  final String address;

  /// Portuguese postal code (e.g. "1070-999").
  final String? postalCode;

  /// Locality / city name extracted from the postal-code line.
  final String? locality;

  /// Freguesia (civil parish).
  final String? parish;

  /// Concelho (municipality).
  final String? municipality;

  /// Distrito (district).
  final String district;

  /// Contact phone number.
  final String? phone;

  /// Opening-hours description (stations only).
  final String? schedule;

  /// Whether the station is open after 18:00.
  final bool? openAfter18;

  /// Whether the station opens on weekends.
  final bool? openWeekends;

  /// List of service descriptions offered at this location.
  final List<String> services;

  /// Last mail-collection time (mailboxes only).
  final String? lastCollection;

  CttLocation({
    required this.id,
    required this.name,
    required this.type,
    this.stationType,
    this.mailboxType,
    required this.coordinates,
    required this.address,
    this.postalCode,
    this.locality,
    this.parish,
    this.municipality,
    required this.district,
    this.phone,
    this.schedule,
    this.openAfter18,
    this.openWeekends,
    this.services = const [],
    this.lastCollection,
  });

  /// Returns a human-readable Portuguese label for the location type
  /// (e.g. "Loja CTT", "Ponto CTT", "Marco de Correio").
  String get typeLabel {
    if (type == CttLocationType.station) {
      switch (stationType) {
        case StationType.lojaCtt:
          return 'Loja CTT';
        case StationType.pontoCtt:
          return 'Ponto CTT';
        case StationType.pontoCorreios:
          return 'Ponto Correios';
        case StationType.lojaFinancas:
          return 'Loja CTT Finanças';
        default:
          return 'Estação CTT';
      }
    } else {
      switch (mailboxType) {
        case MailboxType.marco:
          return 'Marco de Correio';
        case MailboxType.caixa:
          return 'Caixa de Correio';
        default:
          return 'Marco/Caixa';
      }
    }
  }

  /// Convenience getter — `true` when this is a station.
  bool get isStation => type == CttLocationType.station;

  /// Convenience getter — `true` when this is a mailbox.
  bool get isMailbox => type == CttLocationType.mailbox;

  /// Deserialises a [CttLocation] from a JSON map.
  ///
  /// Expected keys: `id`, `name`, `type` (`"station"` / `"mailbox"`),
  /// `lat`, `lng`, `address`, `district` and optional geographic /
  /// contact / schedule fields.
  factory CttLocation.fromJson(Map<String, dynamic> json) {
    return CttLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == 'station'
          ? CttLocationType.station
          : CttLocationType.mailbox,
      stationType: json['stationType'] != null
          ? StationType.values.firstWhere(
              (e) => e.name == json['stationType'],
              orElse: () => StationType.outro,
            )
          : null,
      mailboxType: json['mailboxType'] != null
          ? MailboxType.values.firstWhere(
              (e) => e.name == json['mailboxType'],
              orElse: () => MailboxType.marco,
            )
          : null,
      coordinates: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      address: json['address'] as String,
      postalCode: json['postalCode'] as String?,
      locality: json['locality'] as String?,
      parish: json['parish'] as String?,
      municipality: json['municipality'] as String?,
      district: json['district'] as String,
      phone: json['phone'] as String?,
      schedule: json['schedule'] as String?,
      openAfter18: json['openAfter18'] as bool?,
      openWeekends: json['openWeekends'] as bool?,
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastCollection: json['lastCollection'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type == CttLocationType.station ? 'station' : 'mailbox',
      'stationType': stationType?.name,
      'mailboxType': mailboxType?.name,
      'lat': coordinates.latitude,
      'lng': coordinates.longitude,
      'address': address,
      'postalCode': postalCode,
      'locality': locality,
      'parish': parish,
      'municipality': municipality,
      'district': district,
      'phone': phone,
      'schedule': schedule,
      'openAfter18': openAfter18,
      'openWeekends': openWeekends,
      'services': services,
      'lastCollection': lastCollection,
    };
  }
}
