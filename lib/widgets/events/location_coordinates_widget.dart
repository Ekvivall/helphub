import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../custom_text_field.dart';

class LocationCoordinatesWidget extends StatefulWidget {
  final GeoPoint? coordinates;
  final String? errorMessage;
  final bool isLoading;
  final Function(double?, double?) onCoordinatesChanged;

  const LocationCoordinatesWidget({
    super.key,
    this.coordinates,
    this.errorMessage,
    this.isLoading = false,
    required this.onCoordinatesChanged,
  });

  @override
  State<LocationCoordinatesWidget> createState() =>
      _LocationCoordinatesWidgetState();
}

class _LocationCoordinatesWidgetState extends State<LocationCoordinatesWidget> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final Completer<GoogleMapController> _mapController = Completer();

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  @override
  void didUpdateWidget(LocationCoordinatesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinates != widget.coordinates) {
      _updateControllers();
      _updateMapCamera();
    }
  }

  void _updateControllers() {
    if (widget.coordinates != null) {
      _latController.text = widget.coordinates!.latitude.toStringAsFixed(6);
      _lngController.text = widget.coordinates!.longitude.toStringAsFixed(6);
    } else {
      _latController.clear();
      _lngController.clear();
    }
  }

  void _updateMapCamera() async {
    if (widget.coordinates != null && _mapController.isCompleted) {
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            widget.coordinates!.latitude,
            widget.coordinates!.longitude,
          ),
        ),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    if (widget.coordinates == null) return {};

    return {
      Marker(
        markerId: const MarkerId('event_location'),
        position: LatLng(
          widget.coordinates!.latitude,
          widget.coordinates!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Місце проведення події',
        ),
      ),
    };
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Координати локації',
          style: TextStyleHelper.instance.title16Bold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        const SizedBox(height: 8),

        // Поля для координат
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _latController,
                label: 'Широта',
                hintText: '50.4501',
                labelColor: appThemeColors.backgroundLightGrey,
                inputType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final lat = double.tryParse(value);
                  final lng = double.tryParse(_lngController.text);
                  widget.onCoordinatesChanged(lat, lng);
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final lat = double.tryParse(value);
                    if (lat == null || lat < -90 || lat > 90) {
                      return 'Некоректна широта (-90 до 90)';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _lngController,
                label: 'Довгота',
                hintText: '30.5234',
                labelColor: appThemeColors.backgroundLightGrey,
                inputType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final lat = double.tryParse(_latController.text);
                  final lng = double.tryParse(value);
                  widget.onCoordinatesChanged(lat, lng);
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final lng = double.tryParse(value);
                    if (lng == null || lng < -180 || lng > 180) {
                      return 'Некоректна довгота (-180 до 180)';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Статус geocoding
        if (widget.isLoading)
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: appThemeColors.blueAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Пошук координат...',
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: appThemeColors.textLightColor,
                ),
              ),
            ],
          )
        else if (widget.errorMessage != null)
          Row(
            children: [
              Icon(Icons.warning, size: 16, color: appThemeColors.orangeLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.errorMessage!,
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.orangeLight,
                  ),
                ),
              ),
            ],
          )
        else if (widget.coordinates != null)
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: appThemeColors.lightGreenColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Координати знайдено автоматично',
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.lightGreenColor,
                  ),
                ),
              ],
            ),

        const SizedBox(height: 16),

        // Карта
        if (widget.coordinates != null) ...[
          Text(
            'Попередній перегляд на карті:',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: appThemeColors.backgroundLightGrey.withAlpha(74),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    widget.coordinates!.latitude,
                    widget.coordinates!.longitude,
                  ),
                  zoom: 15,
                ),
                markers: _buildMarkers(), // Використовуємо метод для побудови маркерів
                onMapCreated: (GoogleMapController controller) {
                  if (!_mapController.isCompleted) {
                    _mapController.complete(controller);
                  }
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                liteModeEnabled: false,
                trafficEnabled: false,
                buildingsEnabled: true,
                indoorViewEnabled: false,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                  Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                  Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                },
              ),
            ),
          ),
        ] else
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: appThemeColors.backgroundLightGrey.withAlpha(74),
              ),
              color: appThemeColors.backgroundLightGrey.withAlpha(40),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: appThemeColors.backgroundLightGrey.withAlpha(140),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Карта буде показана після\nвведення адреси',
                    textAlign: TextAlign.center,
                    style: TextStyleHelper.instance.title13Regular.copyWith(
                      color: appThemeColors.backgroundLightGrey.withAlpha(174),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}