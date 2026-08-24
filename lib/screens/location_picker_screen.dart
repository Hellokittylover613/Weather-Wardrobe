import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

/// Full-screen destination picker, styled after the ride-hailing
/// "where to?" pattern (inDrive / Uber style):
///   - a pinned "use current location" row at the top
///   - a rounded search field
///   - a results list with circular pin markers
///
/// Pushed as its own screen (not a bottom sheet) so it has room to
/// breathe the way those pickers do. Pops with the selected location
/// map (or null if the user backs out).
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _debounce;

  List<Map<String, dynamic>> _results = [];

  bool _isSearching = false;
  bool _isLocating = false;

  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // SEARCH
  // ----------------------------------------------------------

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _searchLocations(query),
    );
  }

  Future<void> _searchLocations(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) return;

    setState(() {
      _isSearching = true;
      _lastQuery = trimmedQuery;
    });

    try {
      final results = await WeatherService.searchLocations(trimmedQuery);

      if (!mounted) return;

      // Don't display an older search result over a newer query.
      if (_lastQuery != trimmedQuery) return;

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _results = [];
        _isSearching = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ----------------------------------------------------------
  // USE CURRENT GPS LOCATION
  // ----------------------------------------------------------

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      final position = await LocationService.getCurrentLocation();

      if (!mounted) return;

      Navigator.pop(context, {
        'name': 'Current Location',
        'region': '',
        'country': '',
        'lat': position.latitude,
        'lon': position.longitude,
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLocating = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _locationSubtitle(Map<String, dynamic> location) {
    final region = location['region'] ?? '';
    final country = location['country'] ?? '';

    final parts = <String>[];

    if (region.toString().isNotEmpty) parts.add(region.toString());
    if (country.toString().isNotEmpty) parts.add(country.toString());

    return parts.join(', ');
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchField(),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // Slim top bar: back arrow + title, no elevation, matches the
  // clean white/grey ride-hailing look.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.plum),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            'Set your location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.plum,
            ),
          ),
        ],
      ),
    );
  }

  // Pill-shaped search field with a pin-style leading icon, sitting
  // directly under the header the way a "Where to?" field would.
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgBottom,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: AppColors.plum),
          decoration: InputDecoration(
            hintText: 'Search for a city or destination',
            hintStyle: TextStyle(color: AppColors.hintGrey),
            prefixIcon: const Icon(
              Icons.radio_button_checked,
              color: AppColors.coral,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.hintGrey),
                    onPressed: () {
                      _searchController.clear();

                      setState(() {
                        _results = [];
                        _isSearching = false;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // While the search box is empty, show the "use current location"
    // shortcut pinned above wherever a recent-places list would go.
    if (_searchController.text.trim().isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildCurrentLocationTile(),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.bgBottom),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.location_searching,
                  size: 44,
                  color: AppColors.hintGrey,
                ),
                const SizedBox(height: 12),
                Text(
                  'Search above to find any city\nor pick your current spot',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.hintGrey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 44,
              color: AppColors.hintGrey,
            ),
            const SizedBox(height: 12),
            const Text(
              'No locations found',
              style: TextStyle(fontSize: 15, color: AppColors.plum),
            ),
            const SizedBox(height: 4),
            Text(
              'Try another search',
              style: TextStyle(fontSize: 13, color: AppColors.hintGrey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.bgBottom),
      itemBuilder: (context, index) {
        final location = _results[index];
        return _buildResultTile(location);
      },
    );
  }

  // The "GPS locate me" row — always available at the top, styled as
  // a highlighted pill the way ride-hailing apps surface it.
  Widget _buildCurrentLocationTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isLocating ? null : _useCurrentLocation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: _isLocating
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Use current location',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.plum,
                      ),
                    ),
                    Text(
                      'Detect automatically via GPS',
                      style: TextStyle(fontSize: 12, color: AppColors.hintGrey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.hintGrey),
            ],
          ),
        ),
      ),
    );
  }

  // A single search result row: circular pin marker, name + subtitle.
  Widget _buildResultTile(Map<String, dynamic> location) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(context, location),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.coral,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location['name']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.plum,
                      ),
                    ),
                    Text(
                      _locationSubtitle(location),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.hintGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
