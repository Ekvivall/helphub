import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helphub/data/models/event_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/event/event_view_model.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../routes/app_router.dart';

class EventMapScreen extends StatefulWidget {
  const EventMapScreen({super.key});

  @override
  State<EventMapScreen> createState() => _EventMapScreenState();
}

class _EventMapScreenState extends State<EventMapScreen> {
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  LatLng? _userCurrentLatLng;
  bool _isMapReady = false;
  bool _isLocationLoading = true;
  Timer? _debounceTimer;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(48.464717, 35.046183),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setLocationLoadingComplete();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setLocationLoadingComplete();
        return;
      }
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationLoadingComplete();
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );
      if (mounted) {
        setState(() {
          _userCurrentLatLng = LatLng(position.latitude, position.longitude);
          _initialCameraPosition = CameraPosition(
            target: _userCurrentLatLng!,
            zoom: 14,
          );
        });
        if (_isMapReady && mapController != null) {
          await mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_userCurrentLatLng!, 14),
          );
        }
      }
    } catch (e) {
      print('Error getting user location: $e');
      // Fallback to default location
    } finally {
      _setLocationLoadingComplete();
    }
  }

  void _setLocationLoadingComplete() {
    if (mounted) {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  void _updateMarkers(List<EventModel> events) {
    if (!mounted || _isMapReady == false || events.isEmpty) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      _performMarkerUpdate(events);
    });
  }

  void _performMarkerUpdate(List<EventModel> events) {
    if (!mounted) return;
    final Set<Marker> newMarkers = {};
    final validEvents = events
        .where((event) => event.locationGeoPoint != null && event.id != null)
        .toList();
    for (var event in validEvents) {
      final LatLng position = LatLng(
        event.locationGeoPoint!.latitude,
        event.locationGeoPoint!.longitude,
      );
      newMarkers.add(
        Marker(
          markerId: MarkerId(event.id!),
          position: position,
          infoWindow: InfoWindow(
            title: event.name,
            snippet: event.locationText,
            onTap: () {
              _navigateToEventDetails(event);
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          onTap: () {
            _onMarkerTap(event);
          },
        ),
      );
    }
    if (!setEquals(_markers, newMarkers)) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _navigateToEventDetails(EventModel event) {
    Navigator.of(context).pushNamed(
      AppRoutes.eventDetailScreen,
      arguments: event.id,
    );
  }

  void _onMarkerTap(EventModel event) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.name,
                style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${event.locationText} - ${event.date.day}.${event.date.month}.${event.date.year} ${DateFormat('HH:mm').format(event.date)}',
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 16),
              CustomElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToEventDetails(event);
                },
                text: 'Детальніше про подію',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    if (_userCurrentLatLng != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_userCurrentLatLng!, 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventViewModel>(
      builder: (context, viewModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (viewModel.filteredEvents.isNotEmpty) {
            _updateMarkers(viewModel.filteredEvents);
          }
        });
        if (viewModel.isLoading && _isLocationLoading && _markers.isEmpty) {
          return _buildLoadingWidget();
        }
        if (viewModel.errorMessage != null) {
          return _buildErrorWidget(viewModel.errorMessage!);
        }
        return _buildMapWidget();
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: appThemeColors.successGreen),
          SizedBox(height: 16),
          Text(
            'Завантаження карти...',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.textMediumGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: appThemeColors.backgroundLightGrey,
            ),
            SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _getUserLocation();
              },
              child: Text('Спробувати знову'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWidget() {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _initialCameraPosition,
          onMapCreated: _onMapCreated,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          // Performance optimizations
          liteModeEnabled: false,
          trafficEnabled: false,
          buildingsEnabled: true,
          indoorViewEnabled: false,
          // Gesture settings
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
            Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
          },
        ),

        if (!_isMapReady)
          Container(
            color: Colors.white.withAlpha(174),
            child: Center(
              child: CircularProgressIndicator(
                color: appThemeColors.successGreen,
              ),
            ),
          ),
      ],
    );
  }
}
