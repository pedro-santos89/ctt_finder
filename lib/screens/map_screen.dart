/// Main map screen — displays CTT locations on an interactive map.
///
/// Provides a search bar, filter sheet, list-view bottom sheet, location
/// card overlay, user-location tracking (blue dot) and several FABs for
/// quick actions (language toggle, my-location, zoom-to-Portugal, list).
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/ctt_location.dart';
import '../services/app_localizations.dart';
import '../services/ctt_service.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/location_card.dart';
import 'detail_screen.dart';

/// Interactive map view that is the core of the CTT Finder experience.
///
/// When [openFilters] is `true` the filter bottom-sheet opens
/// automatically after the district list has finished loading.
class MapScreen extends StatefulWidget {
  /// If `true`, the filter sheet opens as soon as the screen is ready.
  final bool openFilters;

  const MapScreen({super.key, this.openFilters = false});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Service instance used for all API calls.
  final CttService _cttService = CttService();

  /// Controller for the [FlutterMap] widget.
  final MapController _mapController = MapController();

  /// Controller for the search text field.
  final TextEditingController _searchController = TextEditingController();

  /// Complete list of locations returned by the last search.
  List<CttLocation> _allLocations = [];

  /// Subset of [_allLocations] currently visible (after local filtering).
  List<CttLocation> _filteredLocations = [];

  /// Locations matching the current search-bar query.
  List<CttLocation> _searchResults = [];

  /// Whether an API search is currently in progress.
  bool _isLoading = false;

  /// Whether station markers should be shown.
  bool _showStations = true;

  /// Whether mailbox markers should be shown.
  bool _showMailboxes = true;

  /// Currently selected district filter.
  GeoEntry? _selectedDistrict;

  /// Currently selected municipality filter.
  GeoEntry? _selectedMunicipality;

  /// Currently selected parish filter.
  GeoEntry? _selectedParish;

  /// The location whose [LocationCard] is currently shown.
  CttLocation? _selectedLocation;

  /// Whether the search-results dropdown is visible.
  bool _isSearching = false;

  /// Full list of Portuguese districts.
  List<GeoEntry> _districts = [];

  /// GPS position of the user (null until acquired).
  LatLng? _userLocation;

  /// Default camera centre (mainland Portugal).
  static const LatLng _portugalCenter = LatLng(39.5, -8.0);

  @override
  void initState() {
    super.initState();
    _initScreen();
    _determineUserLocation();
  }

  /// Loads districts and optionally opens the filter sheet.
  Future<void> _initScreen() async {
    await _loadDistricts();
    if (widget.openFilters && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openFilterSheet());
    }
  }

  /// Requests location permission and moves the camera to the user’s
  /// position.  Falls back silently to the Portugal centre on failure.
  Future<void> _determineUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_userLocation!, 10.0);
      }
    } catch (_) {
      // Location unavailable — keep Portugal center as fallback
    }
  }

  /// Fetches the district list from the CTT geo API.
  Future<void> _loadDistricts() async {
    final districts = await _cttService.fetchDistricts();
    setState(() {
      _districts = districts;
    });
  }

  /// Executes a search based on the currently selected filters and
  /// updates [_allLocations] / [_filteredLocations].
  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    try {
      final List<CttLocation> results = [];

      if (_showStations) {
        results.addAll(await _cttService.searchStations(
          districtCode: _selectedDistrict?.code,
          municipalityCode: _selectedMunicipality?.code,
          parishCode: _selectedParish?.code,
        ));
      }
      if (_showMailboxes) {
        results.addAll(await _cttService.searchMailboxes(
          districtCode: _selectedDistrict?.code,
          municipalityCode: _selectedMunicipality?.code,
          parishCode: _selectedParish?.code,
        ));
      }

      setState(() {
        _allLocations = results;
        _filteredLocations = results;
        _isLoading = false;
        _selectedLocation = null;
      });

      // Zoom to fit results
      if (results.isNotEmpty) {
        _zoomToFitResults(results);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).errorLoadingLocations}: $e')),
        );
      }
    }
  }

  /// Adjusts the camera so that all [results] are visible.
  void _zoomToFitResults(List<CttLocation> results) {
    if (results.length == 1) {
      _mapController.move(results.first.coordinates, 15.0);
      return;
    }
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final loc in results) {
      if (loc.coordinates.latitude < minLat) minLat = loc.coordinates.latitude;
      if (loc.coordinates.latitude > maxLat) maxLat = loc.coordinates.latitude;
      if (loc.coordinates.longitude < minLng) {
        minLng = loc.coordinates.longitude;
      }
      if (loc.coordinates.longitude > maxLng) {
        maxLng = loc.coordinates.longitude;
      }
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  /// Filters [_allLocations] by the text the user typed in the search bar.
  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _isSearching = true;
      _searchResults = _allLocations.where((loc) {
        return loc.name.toLowerCase().contains(lowerQuery) ||
            loc.address.toLowerCase().contains(lowerQuery) ||
            (loc.locality?.toLowerCase().contains(lowerQuery) ?? false) ||
            (loc.municipality?.toLowerCase().contains(lowerQuery) ?? false) ||
            loc.district.toLowerCase().contains(lowerQuery) ||
            (loc.postalCode?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    });
  }

  /// Highlights a [location] on the map and shows its [LocationCard].
  void _selectLocation(CttLocation location) {
    setState(() {
      _selectedLocation = location;
      _isSearching = false;
      _searchController.clear();
    });
    _mapController.move(location.coordinates, 16.0);
  }

  /// Navigates to [DetailScreen] for the given [location].
  void _openDetail(CttLocation location) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(location: location)),
    );
  }

  /// Opens the filter bottom-sheet, passing all current state.
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FilterSheet(
        showStations: _showStations,
        showMailboxes: _showMailboxes,
        selectedDistrict: _selectedDistrict,
        selectedMunicipality: _selectedMunicipality,
        selectedParish: _selectedParish,
        districts: _districts,
        cttService: _cttService,
        onApply: (showStations, showMailboxes, district, municipality, parish) {
          setState(() {
            _showStations = showStations;
            _showMailboxes = showMailboxes;
            _selectedDistrict = district;
            _selectedMunicipality = municipality;
            _selectedParish = parish;
          });
          Navigator.pop(ctx);
          _loadLocations();
        },
      ),
    );
  }

  /// Builds map [Marker]s for every location in [_filteredLocations].
  ///
  /// The currently selected marker is rendered larger with an inverted
  /// colour scheme for emphasis.
  List<Marker> _buildMarkers() {
    return _filteredLocations.map((location) {
      final isSelected = _selectedLocation?.id == location.id;
      return Marker(
        point: location.coordinates,
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        child: GestureDetector(
          onTap: () => setState(() => _selectedLocation = location),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : location.isStation
                      ? const Color(0xFFDF0024)
                      : const Color(0xFFFF8F00),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? (location.isStation
                        ? const Color(0xFFDF0024)
                        : const Color(0xFFFF8F00))
                    : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              location.isStation ? Icons.store : Icons.mail,
              color: isSelected
                  ? (location.isStation
                      ? const Color(0xFFDF0024)
                      : const Color(0xFFFF8F00))
                  : Colors.white,
              size: isSelected ? 28 : 22,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _portugalCenter,
              initialZoom: 7.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (_, __) {
                setState(() {
                  _selectedLocation = null;
                  _isSearching = false;
                });
                FocusScope.of(context).unfocus();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'pt.ctt.finder',
              ),
              MarkerLayer(markers: _buildMarkers()),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search, color: Color(0xFFDF0024)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: l.searchHint,
                              border: InputBorder.none,
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            onChanged: _onSearch,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          ),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        IconButton(
                          icon: Badge(
                            isLabelVisible: _selectedDistrict != null ||
                                !_showStations ||
                                !_showMailboxes,
                            backgroundColor: const Color(0xFFDF0024),
                            child:
                                const Icon(Icons.tune, color: Color(0xFFDF0024)),
                          ),
                          onPressed: _openFilterSheet,
                        ),
                      ],
                    ),
                  ),
                ),

                // Search results dropdown
                if (_isSearching && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (ctx, index) {
                        final loc = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            loc.isStation ? Icons.store : Icons.mail,
                            color: loc.isStation
                                ? const Color(0xFFDF0024)
                                : const Color(0xFFFF8F00),
                          ),
                          title: Text(
                            loc.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${loc.address}, ${loc.locality ?? loc.district}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => _selectLocation(loc),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFFDF0024)),
                ),
              ),
            ),

          // Location count badge
          Positioned(
            bottom: _selectedLocation != null ? 200 : 24,
            left: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Color(0xFFDF0024)),
                    const SizedBox(width: 4),
                    Text(
                      _filteredLocations.isEmpty && !_isLoading
                          ? l.useFiltersToSearch
                          : '${_filteredLocations.length} ${l.locations}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Zoom to Portugal button
          Positioned(
            bottom: _selectedLocation != null ? 200 : 24,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'language',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final newLocale =
                        l.isPt ? const Locale('en') : const Locale('pt');
                    l.onLocaleChanged(newLocale);
                  },
                  child: Text(
                    l.isPt ? 'EN' : 'PT',
                    style: const TextStyle(
                      color: Color(0xFFDF0024),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 14.0);
                    } else {
                      _determineUserLocation();
                    }
                  },
                  child: Icon(
                    _userLocation != null
                        ? Icons.my_location
                        : Icons.location_searching,
                    color: const Color(0xFFDF0024),
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_pt',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _mapController.move(_portugalCenter, 7.0);
                  },
                  child: const Icon(Icons.public, color: Color(0xFFDF0024)),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'list_view',
                  backgroundColor: Colors.white,
                  onPressed: _openListView,
                  child: const Icon(Icons.list, color: Color(0xFFDF0024)),
                ),
              ],
            ),
          ),

          // Creator signature
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Anima Rasa Prod. 2026',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black.withValues(alpha: 0.35),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // Selected location card
          if (_selectedLocation != null)
            Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: LocationCard(
                location: _selectedLocation!,
                onTap: () => _openDetail(_selectedLocation!),
                onClose: () => setState(() => _selectedLocation = null),
              ),
            ),
        ],
      ),
    );
  }

  /// Opens a draggable bottom-sheet listing all loaded locations.
  void _openListView() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.list, color: Color(0xFFDF0024)),
                    const SizedBox(width: 8),
                    Text(
                      '${l.allLocations} (${_filteredLocations.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredLocations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final loc = _filteredLocations[index];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: loc.isStation
                              ? const Color(0xFFDF0024)
                              : const Color(0xFFFF8F00),
                          child: Icon(
                            loc.isStation ? Icons.store : Icons.mail,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          loc.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${loc.address}\n${loc.locality ?? ''} · ${loc.district}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(ctx);
                          _selectLocation(loc);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
