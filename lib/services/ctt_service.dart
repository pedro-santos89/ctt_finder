/// CTT location search service.
///
/// Provides methods to query the Portuguese postal-service (CTT) search
/// endpoint for stations/mailboxes and the geographic-hierarchy JSON API
/// for districts, municipalities and parishes.
///
/// All HTTP communication goes through an injectable [http.Client] so
/// the service is testable without live network calls.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:latlong2/latlong.dart';
import '../models/ctt_location.dart';

/// Represents an item in the district/municipality/parish hierarchy.
class GeoEntry {
  final String code;
  final String name;

  GeoEntry({required this.code, required this.name});

  factory GeoEntry.fromJson(Map<String, dynamic> json) {
    return GeoEntry(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  @override
  String toString() => '$name ($code)';
}

/// Singleton-style service that talks to *appserver2.ctt.pt*.
///
/// * **Geographic hierarchy**: [fetchDistricts], [fetchMunicipalities],
///   [fetchParishes] — return lists of [GeoEntry].
/// * **Location search**: [searchStations], [searchMailboxes],
///   [searchAll] — scrape the CTT HTML results page and return
///   [CttLocation] lists.
class CttService {
  /// Root URL for all CTT API endpoints.
  static const String _baseUrl = 'https://appserver2.ctt.pt';

  /// Base path for the geographic-hierarchy (SCREF) JSON API.
  static const String _screfBase = '$_baseUrl/scref/countries/pt';

  /// URL for the station / mailbox search POST endpoint.
  static const String _searchUrl =
      '$_baseUrl/feapl_2/app/open/stationSearch/search.jspx';

  /// HTTP client (injectable for testing).
  final http.Client _client;

  /// Creates a [CttService] with an optional [client] for testing.
  CttService({http.Client? client}) : _client = client ?? http.Client();

  // -------------------------------------------------------------------
  // Geographical hierarchy (JSON APIs)
  // -------------------------------------------------------------------

  /// Fetch all districts of Portugal.
  Future<List<GeoEntry>> fetchDistricts() async {
    final uri = Uri.parse('$_screfBase/districts');
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return [];
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data
        .map((e) => GeoEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch municipalities for a given district code.
  Future<List<GeoEntry>> fetchMunicipalities(String districtCode) async {
    final uri =
        Uri.parse('$_screfBase/districts/$districtCode/municipalities');
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return [];
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data
        .map((e) => GeoEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch parishes for a given district + municipality code.
  Future<List<GeoEntry>> fetchParishes(
      String districtCode, String municipalityCode) async {
    final uri = Uri.parse(
        '$_screfBase/districts/$districtCode/municipalities/$municipalityCode/parishes');
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return [];
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data
        .map((e) => GeoEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------
  // Station & Mailbox search (HTML scraping of POST results)
  // -------------------------------------------------------------------

  /// Search for CTT stations (Lojas CTT, Pontos CTT, etc.).
  Future<List<CttLocation>> searchStations({
    String? districtCode,
    String? municipalityCode,
    String? parishCode,
    String? location,
    int page = 1,
  }) async {
    return _searchAllParishesIfNeeded(
      stationType: 'EC,PC,PARC',
      districtCode: districtCode,
      municipalityCode: municipalityCode,
      parishCode: parishCode,
      location: location,
      page: page,
    );
  }

  /// Search for mailboxes (marcos e caixas de correio).
  Future<List<CttLocation>> searchMailboxes({
    String? districtCode,
    String? municipalityCode,
    String? parishCode,
    String? location,
    int page = 1,
  }) async {
    return _searchAllParishesIfNeeded(
      stationType: 'RECET',
      districtCode: districtCode,
      municipalityCode: municipalityCode,
      parishCode: parishCode,
      location: location,
      page: page,
    );
  }

  /// When geography is partially selected, recursively expand the
  /// search to cover all sub-divisions.
  ///
  /// * District only → fetch all its municipalities → recurse.
  /// * Municipality only → fetch all its parishes → search each.
  ///
  /// Returns a de-duplicated list of [CttLocation].
  Future<List<CttLocation>> _searchAllParishesIfNeeded({
    required String stationType,
    String? districtCode,
    String? municipalityCode,
    String? parishCode,
    String? location,
    int page = 1,
  }) async {
    // District set, but no municipality and no parish → search every municipality
    if (districtCode != null &&
        districtCode.isNotEmpty &&
        (municipalityCode == null || municipalityCode.isEmpty) &&
        (parishCode == null || parishCode.isEmpty)) {
      final municipalities = await fetchMunicipalities(districtCode);
      if (municipalities.isNotEmpty) {
        // For each municipality, delegate to the same method which will
        // in turn expand into all parishes.
        final results = await Future.wait(
          municipalities.map((m) => _searchAllParishesIfNeeded(
                stationType: stationType,
                districtCode: districtCode,
                municipalityCode: m.code,
                parishCode: null,
                location: location,
                page: page,
              )),
        );
        return _flattenAndDeduplicate(results);
      }
    }

    // Municipality set but no parish → search every parish
    if (districtCode != null &&
        districtCode.isNotEmpty &&
        municipalityCode != null &&
        municipalityCode.isNotEmpty &&
        (parishCode == null || parishCode.isEmpty)) {
      final parishes = await fetchParishes(districtCode, municipalityCode);
      if (parishes.isNotEmpty) {
        final results = await Future.wait(
          parishes.map((p) => _search(
                stationType: stationType,
                districtCode: districtCode,
                municipalityCode: municipalityCode,
                parishCode: p.code,
                location: location,
                page: page,
              )),
        );
        return _flattenAndDeduplicate(results);
      }
    }

    return _search(
      stationType: stationType,
      districtCode: districtCode,
      municipalityCode: municipalityCode,
      parishCode: parishCode,
      location: location,
      page: page,
    );
  }

  /// Flattens a list of result lists and removes duplicates by [CttLocation.id].
  List<CttLocation> _flattenAndDeduplicate(List<List<CttLocation>> results) {
    final seen = <String>{};
    final combined = <CttLocation>[];
    for (final list in results) {
      for (final loc in list) {
        if (seen.add(loc.id)) {
          combined.add(loc);
        }
      }
    }
    return combined;
  }

  /// Searches for both stations and mailboxes in parallel.
  ///
  /// Returns the concatenated results of [searchStations] and
  /// [searchMailboxes].
  Future<List<CttLocation>> searchAll({
    String? districtCode,
    String? municipalityCode,
    String? parishCode,
    String? location,
  }) async {
    final results = await Future.wait([
      searchStations(
        districtCode: districtCode,
        municipalityCode: municipalityCode,
        parishCode: parishCode,
        location: location,
      ),
      searchMailboxes(
        districtCode: districtCode,
        municipalityCode: municipalityCode,
        parishCode: parishCode,
        location: location,
      ),
    ]);
    return [...results[0], ...results[1]];
  }

  /// Low-level search that POSTs to the CTT search endpoint.
  ///
  /// [stationType] selects the category:
  /// * `"EC,PC,PARC"` — stations (Lojas, Pontos, Parceiros).
  /// * `"RECET"` — mailboxes.
  ///
  /// Returns a list of [CttLocation] parsed from the HTML response.
  Future<List<CttLocation>> _search({
    required String stationType,
    String? districtCode,
    String? municipalityCode,
    String? parishCode,
    String? location,
    int page = 1,
  }) async {
    final body = <String, String>{
      'stationType': stationType,
    };
    if (districtCode != null && districtCode.isNotEmpty) {
      body['district'] = districtCode;
    }
    if (municipalityCode != null && municipalityCode.isNotEmpty) {
      body['municipality'] = municipalityCode;
    }
    if (parishCode != null && parishCode.isNotEmpty) {
      body['parish'] = parishCode;
    }
    if (location != null && location.isNotEmpty) {
      body['location'] = location;
    }
    if (page > 1) {
      body['resultsOnly'] = 'true';
      body['currentPage'] = page.toString();
    }

    final response = await _client
        .post(
          Uri.parse(_searchUrl),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Referer':
                '$_baseUrl/feapl_2/app/open/stationSearch/stationSearch.jspx',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) return [];

    final htmlContent = utf8.decode(response.bodyBytes);
    if (stationType == 'RECET') {
      return _parseMailboxResults(htmlContent);
    }
    return _parseStationResults(htmlContent);
  }

  // -------------------------------------------------------------------
  // HTML parsers
  // -------------------------------------------------------------------

  /// Parses station results from the CTT HTML response.
  ///
  /// Iterates over `<li class="entry-wrapper">` elements, extracts
  /// coordinates from the map link, address details from `div.posRelative`,
  /// schedule from `ul.list-check` items, and services from `div.list-check`.
  ///
  /// Returns a list of [CttLocation] with [CttLocationType.station].
  List<CttLocation> _parseStationResults(String html) {
    final document = html_parser.parse(html);
    final entries = document.querySelectorAll('li.entry-wrapper');
    final locations = <CttLocation>[];

    for (final entry in entries) {
      try {
        final mapLink =
            entry.querySelector('a[href*="pointSearchResultsMap"]');
        if (mapLink == null) continue;

        final href = mapLink.attributes['href'] ?? '';
        final qMatch = RegExp(r'q=([-\d.]+),([-\d.]+)').firstMatch(href);
        if (qMatch == null) continue;

        final lat = double.parse(qMatch.group(1)!);
        final lng = double.parse(qMatch.group(2)!);

        final typeText = entry.querySelector('p')?.text.trim() ?? '';
        final name = entry.querySelector('h3')?.text.trim() ?? 'Estação CTT';

        final divPosRelative = entry.querySelector('div.posRelative');
        String address = '';
        String? postalCode;
        String? locality;
        String? phone;

        if (divPosRelative != null) {
          final fullText = divPosRelative.innerHtml;
          final addressMatch =
              RegExp(r'^([^<]+?)(?:\s*<a)', dotAll: true).firstMatch(fullText);
          if (addressMatch != null) {
            address = _decodeHtmlEntities(addressMatch.group(1)!.trim());
          }

          final postalMatch = RegExp(r'(\d{4}-\d{3})\s+([A-ZÀ-Ú ]+)')
              .firstMatch(divPosRelative.text);
          if (postalMatch != null) {
            postalCode = postalMatch.group(1);
            locality = _titleCase(postalMatch.group(2)!.trim());
          }

          final phoneLink = divPosRelative.querySelector('a[href^="tel:"]');
          if (phoneLink != null) phone = phoneLink.text.trim();
        }

        final scheduleItems = entry.querySelectorAll('ul.list-check li');
        final scheduleParts = <String>[];
        for (final item in scheduleItems) {
          scheduleParts.add(item.text.replaceAll(RegExp(r'\s+'), ' ').trim());
        }
        final schedule =
            scheduleParts.isNotEmpty ? scheduleParts.join(' | ') : null;

        // Extra info from list-check div (Banco CTT hours, etc.)
        final extraInfo = <String>[];
        final extraList = entry.querySelectorAll('div.list-check ul li');
        for (final li in extraList) {
          extraInfo.add(li.text.replaceAll(RegExp(r'\s+'), ' ').trim());
        }

        StationType stType = StationType.outro;
        final lowerType = typeText.toLowerCase();
        if (lowerType.contains('loja ctt')) {
          stType = StationType.lojaCtt;
        } else if (lowerType.contains('ponto ctt')) {
          stType = StationType.pontoCtt;
        } else if (lowerType.contains('ponto correios')) {
          stType = StationType.pontoCorreios;
        }

        locations.add(CttLocation(
          id: 'st_${locations.length}_${lat.toStringAsFixed(4)}',
          name: _decodeHtmlEntities(name),
          type: CttLocationType.station,
          stationType: stType,
          coordinates: LatLng(lat, lng),
          address: address,
          postalCode: postalCode,
          locality: locality,
          district: '',
          phone: phone,
          schedule: schedule,
          services: extraInfo,
        ));
      } catch (_) {
        continue;
      }
    }
    return locations;
  }

  /// Parses mailbox results from the CTT HTML response.
  ///
  /// Similar to [_parseStationResults] but extracts district /
  /// municipality / parish labels and the last-collection time
  /// from a schedule table.
  ///
  /// Returns a list of [CttLocation] with [CttLocationType.mailbox].
  List<CttLocation> _parseMailboxResults(String html) {
    final document = html_parser.parse(html);
    final entries = document.querySelectorAll('li.entry-wrapper');
    final locations = <CttLocation>[];

    for (final entry in entries) {
      try {
        final mapLink =
            entry.querySelector('a[href*="pointSearchResultsMap"]');
        if (mapLink == null) continue;

        final href = mapLink.attributes['href'] ?? '';
        final qMatch = RegExp(r'q=([-\d.]+),([-\d.]+)').firstMatch(href);
        if (qMatch == null) continue;

        final lat = double.parse(qMatch.group(1)!);
        final lng = double.parse(qMatch.group(2)!);

        final divPosRelative = entry.querySelector('div.posRelative');
        String? district;
        String? municipality;
        String? parish;
        String address = '';
        String? postalCode;
        String? locality;

        if (divPosRelative != null) {
          final innerHtml = divPosRelative.innerHtml;

          var match =
              RegExp(r'Distrito</b>:\s*([^<]+)').firstMatch(innerHtml);
          if (match != null) district = match.group(1)!.trim();

          match =
              RegExp(r'Concelho</b>:\s*([^<]+)').firstMatch(innerHtml);
          if (match != null) municipality = match.group(1)!.trim();

          match =
              RegExp(r'Freguesia</b>:\s*([^<]+)').firstMatch(innerHtml);
          if (match != null) parish = match.group(1)!.trim();

          match = RegExp(r'Localização</b>:\s*([^<]+)')
              .firstMatch(innerHtml);
          if (match != null) {
            address = _decodeHtmlEntities(match.group(1)!.trim());
          }

          final postalMatch = RegExp(r'(\d{4}-\d{3})\s+([A-ZÀ-Ú ]+)')
              .firstMatch(divPosRelative.text);
          if (postalMatch != null) {
            postalCode = postalMatch.group(1);
            locality = _titleCase(postalMatch.group(2)!.trim());
          }
        }

        String? lastCollection;
        final tableCells =
            entry.querySelectorAll('td.mailboxScheduleLine');
        if (tableCells.isNotEmpty) {
          final times = tableCells
              .map((td) => td.text.trim())
              .where((t) => t != '-' && t.isNotEmpty)
              .toList();
          if (times.isNotEmpty) lastCollection = times.first;
        }

        final name =
            'Marco de Correio - ${address.isNotEmpty ? _titleCase(address.split(',').first) : (parish ?? municipality ?? district ?? 'Portugal')}';

        locations.add(CttLocation(
          id: 'mb_${locations.length}_${lat.toStringAsFixed(4)}',
          name: name,
          type: CttLocationType.mailbox,
          mailboxType: MailboxType.marco,
          coordinates: LatLng(lat, lng),
          address: address,
          postalCode: postalCode,
          locality: locality,
          municipality: municipality,
          parish: parish,
          district: district ?? '',
          lastCollection: lastCollection,
          services: ['Recolha de correspondência'],
        ));
      } catch (_) {
        continue;
      }
    }
    return locations;
  }

  // -------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------

  /// Replaces common HTML character entities with their Unicode equivalents.
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&ordm;', 'º')
        .replaceAll('&ccedil;', 'ç')
        .replaceAll('&Ccedil;', 'Ç')
        .replaceAll('&atilde;', 'ã')
        .replaceAll('&Atilde;', 'Ã')
        .replaceAll('&otilde;', 'õ')
        .replaceAll('&Otilde;', 'Õ')
        .replaceAll('&aacute;', 'á')
        .replaceAll('&Aacute;', 'Á')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&Eacute;', 'É')
        .replaceAll('&iacute;', 'í')
        .replaceAll('&Iacute;', 'Í')
        .replaceAll('&oacute;', 'ó')
        .replaceAll('&Oacute;', 'Ó')
        .replaceAll('&uacute;', 'ú')
        .replaceAll('&Uacute;', 'Ú')
        .replaceAll('&agrave;', 'à')
        .replaceAll('&Agrave;', 'À')
        .replaceAll('&acirc;', 'â')
        .replaceAll('&Acirc;', 'Â')
        .replaceAll('&ecirc;', 'ê')
        .replaceAll('&Ecirc;', 'Ê')
        .replaceAll('&ocirc;', 'ô')
        .replaceAll('&Ocirc;', 'Ô')
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&Uuml;', 'Ü')
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (Match m) {
      final code = int.tryParse(m.group(1)!);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });
  }

  /// Converts an ALL-CAPS string to Title Case, keeping short
  /// Portuguese prepositions ("de", "da", "do", …) lowercase.
  String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (['de', 'da', 'do', 'das', 'dos', 'e', 'a', 'o']
              .contains(word.toLowerCase()) &&
          word.length <= 3) {
        return word.toLowerCase();
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Closes the underlying [http.Client].
  void dispose() {
    _client.close();
  }
}
