import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';


void main() {
  runApp(HomePage());
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
          body: FireMap()
        )
    );
  }
}

class FireMap extends StatefulWidget {
  @override
  State createState() => FireMapState();
}

class FireMapState extends State<FireMap> {
  GoogleMapController mapController;
  String _mapStyle;

  BitmapDescriptor customIcon;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    var list = new Set<GeoPoint>();
    GeoPoint testPoint = new GeoPoint(52.07961021059982, 4.313284507953123); //just a constant point for testing purposes
    list.add(testPoint);
    BitmapDescriptor testIcon = await getCustomIcon(circleAvatarKey);
    int id = 0;
    setState(() {
      for(GeoPoint l in list) {
          _markers.add(
          Marker(
            markerId: MarkerId(id.toString()),
            position: LatLng(l.latitude, l.longitude),
            icon: testIcon == null ? BitmapDescriptor.defaultMarker : testIcon
          )
        );
        id++;
      }
    });
  }
  
  GlobalKey circleAvatarKey = GlobalKey();

  Future<String> _getProfilePic() { //Normally this function get's the profile picture url, but I just made a future which returns a constant image for testing purposes
    var completer = new Completer<String>();
    completer.complete("https://logowik.com/content/uploads/images/flutter5786.jpg");
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<String>(
          future: _getProfilePic(), // getting the profile picture from the cloud storage
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            Widget result;
            if (snapshot.hasData) {
              result = RepaintBoundary(
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(snapshot.data),
                ),
                key: circleAvatarKey
              );
            } else if (snapshot.hasError) {
              result = RepaintBoundary(
                child: Text(snapshot.error)
              );
            } else {
              result = SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              );
            }
            return result;
          },
        ),
        GoogleMap(
          initialCameraPosition: CameraPosition(target: LatLng(52.07961021059982, 4.313284507953123), zoom: 15),
            onMapCreated: (GoogleMapController controller) {
            mapController = controller;
            mapController.setMapStyle(_mapStyle);
          },
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ]
    );
  }

  Future<BitmapDescriptor> getCustomIcon(GlobalKey iconKey) async {
    Future<Uint8List> _capturePng(GlobalKey iconKey) async {
      try {
        print('inside');
        RenderRepaintBoundary boundary = iconKey.currentContext.findRenderObject();
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        var pngBytes = byteData.buffer.asUint8List();
        print(pngBytes);
        return pngBytes;
      } catch (e) {
        print(e);
      }
    }

    Uint8List imageData = await _capturePng(iconKey);
    print("testIcon set");
    return BitmapDescriptor.fromBytes(imageData);
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }
}
