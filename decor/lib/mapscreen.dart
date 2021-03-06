import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List pipelist;
  double screenHeight, screenWidth, latitude=6.445298, longitude=100.4242398;
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController gmcontroller;
  CameraPosition _cameraPos;
  GlobalKey<RefreshIndicatorState> refreshKey;
  List markerlist;
  // A map of markers
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  final f = new DateFormat('dd-MM-yyyy hh:mm a');
  Position _currentPosition;

  @override
  void initState() {
    super.initState();
     _cameraPos =
            CameraPosition(target: LatLng(latitude, longitude), zoom: 14);
    _loadPipes();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Pipe Location'),
      ),
      body: Center(
        child: Container(
          child: pipelist == null
              ? Flexible(
                  child: Container(
                      child: Center(
                          child: Text(
                  "Loading map...",
                  style: TextStyle(
                      color: Color.fromRGBO(101, 255, 218, 50),
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ))))
              : Flexible(
                  child: Container(
                  //height: screenHeight / 2,
                  //width: screenWidth / 1.05,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _cameraPos,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                      Factory<OneSequenceGestureRecognizer>(
                          () => ScaleGestureRecognizer())
                    ].toSet(),
                    markers: Set<Marker>.of(markers.values),
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                )),
        ),
      ),
    );
  }

  _loadPipes() {
    markers.clear();
    String urlLoadRoute = "https://slumberjer.com/decor/load_pipes.php";
    http.post(urlLoadRoute, body: {}).then((res) {
      print(res.body);
      if (res.body != 'failed') {
        var extractdata = json.decode(res.body);
        setState(() {
          pipelist = extractdata["pipes"];
        });
        buildMarkers();
      }
    });
  }

  int generateIds() {
    var rng = new Random();
    var randomInt;
    randomInt = rng.nextInt(100);
    print(rng.nextInt(100));
    return randomInt;
  }

  buildMarkers() {
    markerlist = new List();
    for (var i = 0; i < pipelist.length; i++) {
      var markerIdVal = generateIds();
      markerlist.insert(i, markerIdVal);
      final MarkerId markerId = MarkerId(markerIdVal.toString());
      final Marker marker = Marker(
          markerId: markerId,
          position: LatLng(
            double.parse(pipelist[i]["latitude"]),
            double.parse(pipelist[i]["longitude"]),
          ),
          infoWindow: InfoWindow(
            title: pipelist[i]["pipeid"] +"/"+  pipelist[i]["latest"],
            snippet: f.format(DateTime.parse(pipelist[i]["date"])),
          ));

      // you could do setState here when adding the markers to the Map
      markers[markerId] = marker;
    }
    var markerIdVal = generateIds();
    markerlist.insert(
        markerlist.length, markerIdVal); //user current location marker
    final MarkerId markerId = MarkerId(markerIdVal.toString());
    final Marker marker2 = Marker(
        markerId: markerId,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        position: LatLng(
          latitude,
          longitude,
        ),
        infoWindow: InfoWindow(
          title: "Your Location",
          snippet: "Current location",
        ));
    print(markerlist);
    markers[markerId] = marker2;
  }
}
