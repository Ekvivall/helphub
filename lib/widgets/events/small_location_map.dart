import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SmallLocationMap extends StatefulWidget {
  final LatLng location;
  final String? title;
  final String? snippet;

  const SmallLocationMap({
    super.key,
    required this.location,
    this.title,
    this.snippet,
  });

  @override
  State<SmallLocationMap> createState() => _SmallLocationMapState();
}

class _SmallLocationMapState extends State<SmallLocationMap> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarker();
  }

  void _createMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('location'),
        position: widget.location,
        infoWindow: InfoWindow(
          title: widget.title ?? '',
          snippet: widget.snippet ?? '',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: widget.location,
          zoom: 15,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
        markers: _markers,
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
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
