import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:lesson72/services/location_service.dart';

class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({super.key});

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late GoogleMapController mapController;
  final LatLng najotTalim = const LatLng(41.2856806, 69.2034646);
  LatLng myCurrentPosition = const LatLng(41.2856806, 69.2034646);
  Set<Marker> myMarkers = {};
  Set<Polyline> polylines = {};
  List<LatLng> myPositions = [];
  TravelMode travelMode = TravelMode.driving;
  MapType mapType = MapType.normal;
  final TextEditingController _textEditingController = TextEditingController();

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      await LocationService.getCurrentLocation();
      setState(() {});
    });
  }

  void onCameraMove(CameraPosition position) {
    setState(() {
      myCurrentPosition = position.target;
    });
  }

  void watchMyLocation() {
    LocationService.getLiveLocation().listen((location) {});
  }

  void addLocationMarker() {
    setState(() {
      myMarkers.add(
        Marker(
          markerId: MarkerId(myMarkers.length.toString()),
          position: myCurrentPosition,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );

      myPositions.add(myCurrentPosition);

      if (myPositions.length > 1) {
        LocationService.fetchPolylinePoints(myPositions, travelMode)
            .then((List<LatLng> positions) {
          setState(() {
            polylines.add(
              Polyline(
                polylineId: PolylineId(UniqueKey().toString()),
                color: Colors.blue,
                width: 8,
                points: positions,
              ),
            );
          });
        });
      }
    });
  }

  void _goToCurrentLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: najotTalim,
          zoom: 16.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            buildingsEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: najotTalim,
              zoom: 16.0,
            ),
            onCameraMove: onCameraMove,
            mapType: mapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId("najotTalim"),
                icon: BitmapDescriptor.defaultMarker,
                position: najotTalim,
                infoWindow: const InfoWindow(
                  title: "Najot Ta'lim",
                  snippet: "Xush kelibsiz",
                ),
              ),
              Marker(
                markerId: const MarkerId("myCurrentPosition"),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
                position: myCurrentPosition,
                infoWindow: const InfoWindow(
                  title: "Najot Ta'lim",
                  snippet: "Xush kelibsiz",
                ),
              ),
              ...myMarkers,
            },
            polylines: polylines,
          ),
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: GooglePlacesAutoCompleteTextFormField(
                textEditingController: _textEditingController,
                googleAPIKey: "AIzaSyBEjfX9jrWudgRcWl2scld4R7s0LtlaQmQ",
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () {
                      _textEditingController.clear();
                    },
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        CupertinoIcons.delete,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (postalCodeResponse) {
                  double latitude = double.parse(postalCodeResponse.lat!);
                  double longitude = double.parse(postalCodeResponse.lng!);
                  myCurrentPosition = LatLng(latitude, longitude);
                  setState(() {
                    mapController.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: myCurrentPosition,
                          zoom: 16.0,
                        ),
                      ),
                    );
                  });
                },
                onChanged: (value) {},
                itmClick: (prediction) {
                  _textEditingController.text = prediction.description!;
                  _textEditingController.selection = TextSelection.fromPosition(
                    TextPosition(
                      offset: prediction.description!.length,
                    ),
                  );
                }),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            child: PopupMenuButton<String>(
              onSelected: (String result) {
                setState(() {
                  if (result == 'hybrid') {
                    mapType = MapType.hybrid;
                  } else if (result == 'terrain') {
                    mapType = MapType.terrain;
                  }
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'hybrid',
                  child: ListTile(
                    leading: Icon(
                      Icons.layers,
                    ),
                    title: Text('Sputnik'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'terrain',
                  child: ListTile(
                    leading: Icon(
                      CupertinoIcons.triangle_righthalf_fill,
                    ),
                    title: Text('Relyef'),
                  ),
                ),
              ],
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(55),
                ),
                child: const Center(
                  child: Icon(
                    Icons.remove_red_eye,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Positioned(
          child: GestureDetector(
            onDoubleTap: () {
              mapController.animateCamera(
                CameraUpdate.zoomOut(),
              );
            },
            onLongPress: () {
              mapController.animateCamera(
                CameraUpdate.zoomIn(),
              );
            },
            onTap: _goToCurrentLocation,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        FloatingActionButton(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(55),
          ),
          onPressed: addLocationMarker,
          child: const Icon(
            Icons.add_location_alt_outlined,
            color: Colors.white,
          ),
        ),
      ]),
    );
  }
}
