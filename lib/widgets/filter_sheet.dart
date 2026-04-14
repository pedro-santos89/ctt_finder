/// Filter bottom-sheet for narrowing CTT search results.
///
/// Presents location-type toggles (stations / mailboxes) and
/// cascading dropdowns for district → municipality → parish.
/// The selected filters are returned via [FilterSheet.onApply].
library;

import 'package:flutter/material.dart';
import '../services/app_localizations.dart';
import '../services/ctt_service.dart';

/// Modal bottom-sheet with geographic and type filters.
///
/// The initial state of every control is passed in through the
/// constructor so that re-opening the sheet preserves the user’s
/// last selection.
class FilterSheet extends StatefulWidget {
  /// Whether the “stations” toggle is active.
  final bool showStations;

  /// Whether the “mailboxes” toggle is active.
  final bool showMailboxes;

  /// Previously selected district (may be `null`).
  final GeoEntry? selectedDistrict;

  /// Previously selected municipality (may be `null`).
  final GeoEntry? selectedMunicipality;

  /// Previously selected parish (may be `null`).
  final GeoEntry? selectedParish;

  /// Full list of districts to populate the first dropdown.
  final List<GeoEntry> districts;

  /// Service instance used to load municipalities / parishes on demand.
  final CttService cttService;

  /// Callback invoked when the user taps “Search”.
  final void Function(
    bool showStations,
    bool showMailboxes,
    GeoEntry? district,
    GeoEntry? municipality,
    GeoEntry? parish,
  ) onApply;

  const FilterSheet({
    super.key,
    required this.showStations,
    required this.showMailboxes,
    required this.selectedDistrict,
    required this.selectedMunicipality,
    required this.selectedParish,
    required this.districts,
    required this.cttService,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  /// Local copy of the station toggle.
  late bool _showStations;

  /// Local copy of the mailbox toggle.
  late bool _showMailboxes;

  /// Currently selected district in the dropdown.
  GeoEntry? _selectedDistrict;

  /// Currently selected municipality in the dropdown.
  GeoEntry? _selectedMunicipality;

  /// Currently selected parish in the dropdown.
  GeoEntry? _selectedParish;

  /// Municipalities for the selected district.
  List<GeoEntry> _municipalities = [];

  /// Parishes for the selected municipality.
  List<GeoEntry> _parishes = [];

  /// Indicates whether the municipalities list is loading.
  bool _loadingMunicipalities = false;

  /// Indicates whether the parishes list is loading.
  bool _loadingParishes = false;

  @override
  void initState() {
    super.initState();
    _showStations = widget.showStations;
    _showMailboxes = widget.showMailboxes;
    _selectedDistrict = widget.selectedDistrict;
    _selectedMunicipality = widget.selectedMunicipality;
    _selectedParish = widget.selectedParish;
    if (_selectedDistrict != null) {
      _loadingMunicipalities = true;
      if (_selectedMunicipality != null) {
        _loadingParishes = true;
      }
      _loadMunicipalities(_selectedDistrict!.code, restore: true);
    }
  }

  /// Loads municipalities for [districtCode].
  ///
  /// When [restore] is `true` the previously selected municipality
  /// is preserved and its parishes are loaded automatically.
  Future<void> _loadMunicipalities(String districtCode,
      {bool restore = false}) async {
    setState(() => _loadingMunicipalities = true);
    final munis =
        await widget.cttService.fetchMunicipalities(districtCode);
    if (!mounted) return;
    setState(() {
      _municipalities = munis;
      _loadingMunicipalities = false;
      if (!restore) {
        _selectedMunicipality = null;
        _selectedParish = null;
        _parishes = [];
      } else if (_selectedMunicipality != null) {
        _loadParishes(districtCode, _selectedMunicipality!.code,
            restore: true);
      }
    });
  }

  /// Loads parishes for the given district + municipality.
  ///
  /// When [restore] is `true` the previously selected parish is
  /// kept; otherwise it is reset to `null`.
  Future<void> _loadParishes(
      String districtCode, String municipalityCode,
      {bool restore = false}) async {
    setState(() => _loadingParishes = true);
    final par =
        await widget.cttService.fetchParishes(districtCode, municipalityCode);
    if (!mounted) return;
    setState(() {
      _parishes = par;
      _loadingParishes = false;
      if (!restore) {
        _selectedParish = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFFD32F2F)),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).filters,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Type filters
          Text(
            AppLocalizations.of(context).locationType,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _FilterChip(
                  icon: Icons.store,
                  label: AppLocalizations.of(context).storesAndPoints,
                  selected: _showStations,
                  color: const Color(0xFFD32F2F),
                  onTap: () => setState(() => _showStations = !_showStations),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterChip(
                  icon: Icons.mail,
                  label: AppLocalizations.of(context).mailboxes,
                  selected: _showMailboxes,
                  color: const Color(0xFFFF8F00),
                  onTap: () => setState(() => _showMailboxes = !_showMailboxes),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // District dropdown
          _buildDropdownLabel(AppLocalizations.of(context).district),
          _buildGeoDropdown(
            value: _selectedDistrict,
            items: widget.districts,
            hint: AppLocalizations.of(context).allDistricts,
            onChanged: (entry) {
              setState(() {
                _selectedDistrict = entry;
                _selectedMunicipality = null;
                _selectedParish = null;
                _municipalities = [];
                _parishes = [];
              });
              if (entry != null) {
                _loadMunicipalities(entry.code);
              }
            },
          ),

          const SizedBox(height: 12),

          // Municipality dropdown
          _buildDropdownLabel(AppLocalizations.of(context).municipality),
          _loadingMunicipalities
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                      child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFD32F2F)),
                  )),
                )
              : _buildGeoDropdown(
                  value: _selectedMunicipality,
                  items: _municipalities,
                  hint: _selectedDistrict == null
                      ? AppLocalizations.of(context).selectDistrictFirst
                      : AppLocalizations.of(context).allMunicipalities,
                  enabled: _selectedDistrict != null,
                  onChanged: (entry) {
                    setState(() {
                      _selectedMunicipality = entry;
                      _selectedParish = null;
                      _parishes = [];
                    });
                    if (entry != null && _selectedDistrict != null) {
                      _loadParishes(_selectedDistrict!.code, entry.code);
                    }
                  },
                ),

          const SizedBox(height: 12),

          // Parish dropdown
          _buildDropdownLabel(AppLocalizations.of(context).parish),
          _loadingParishes
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                      child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFD32F2F)),
                  )),
                )
              : _buildGeoDropdown(
                  value: _selectedParish,
                  items: _parishes,
                  hint: _selectedMunicipality == null
                      ? AppLocalizations.of(context).selectMunicipalityFirst
                      : AppLocalizations.of(context).allParishes,
                  enabled: _selectedMunicipality != null,
                  onChanged: (entry) {
                    setState(() => _selectedParish = entry);
                  },
                ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showStations = true;
                      _showMailboxes = true;
                      _selectedDistrict = null;
                      _selectedMunicipality = null;
                      _selectedParish = null;
                      _municipalities = [];
                      _parishes = [];
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).clear),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _showStations,
                      _showMailboxes,
                      _selectedDistrict,
                      _selectedMunicipality,
                      _selectedParish,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).search),
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  /// Renders a grey section label above a dropdown.
  Widget _buildDropdownLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// Builds a geographic dropdown with a guard against stale values.
  ///
  /// If the current [value] is no longer present in [items] (e.g. after
  /// a parent dropdown changed), the dropdown falls back to `null`.
  Widget _buildGeoDropdown({
    required GeoEntry? value,
    required List<GeoEntry> items,
    required String hint,
    bool enabled = true,
    required ValueChanged<GeoEntry?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
            color: enabled ? Colors.grey.shade300 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: enabled ? null : Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value != null && items.any((e) => e.code == value.code)
              ? value.code
              : null,
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(
                  color: enabled ? null : Colors.grey.shade400)),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(hint),
            ),
            ...items.map((entry) {
              return DropdownMenuItem<String?>(
                value: entry.code,
                child: Text(entry.name),
              );
            }),
          ],
          onChanged: enabled
              ? (code) {
                  if (code == null) {
                    onChanged(null);
                  } else {
                    onChanged(items.firstWhere((e) => e.code == code));
                  }
                }
              : null,
        ),
      ),
    );
  }
}

/// Toggle chip used for station / mailbox type selection.
class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : Colors.grey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? color : Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
