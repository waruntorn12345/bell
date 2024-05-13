import 'dart:async';
import 'dart:typed_data';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geo/geo.dart' as geo;
import 'package:travel_hour/geofence_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:travel_hour/blocs/ads_bloc.dart';
import 'package:travel_hour/models/colors.dart';
import 'package:travel_hour/config/config.dart';
import 'package:travel_hour/models/guide.dart';
import 'package:travel_hour/models/place.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:travel_hour/utils/convert_map_icon.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/src/platform_specifics/android/enums.dart'
    as notification_enums;

import '../models/MarkerGenerator.dart';

class GuidePage1 extends StatefulWidget {
  final Place? d;
  GuidePage1({Key? key, required this.d}) : super(key: key);

  _GuidePage1State createState() => _GuidePage1State();
}

class _GuidePage1State extends State<GuidePage1> {
  late GoogleMapController mapController;
  Completer<GoogleMapController> _controller = Completer();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  final assetsAudioPlayer = AssetsAudioPlayer();
  Map<String, String> _geofenceAudioUrls = {};
  List<Marker> _markers = [];
  Map? data = {};
  String distance = 'O km';
  late var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  final _geofenceStreamController = StreamController<Geofence>();
  late Uint8List _sourceIcon;
  late Uint8List _destinationIcon;
  final _activityStreamController = StreamController<Activity>();
  Future getData() async {
    await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.d!.timestamp)
        .collection('travel guide1')
        .doc(widget.d!.timestamp)
        .get()
        .then((DocumentSnapshot snap) {
      setState(() {
        data = snap.data() as Map<dynamic, dynamic>?;
      });
    });
  }

  Future _setMarkerIcons() async {
    _sourceIcon = await getBytesFromAsset(Config().drivingMarkerIcon, 110);
    _destinationIcon =
        await getBytesFromAsset(Config().destinationMarkerIcon, 110);
  }

  Future addMarker() async {
    List m = [
      Marker(
          markerId: MarkerId(data!['startpoint name']),
          position: LatLng(
              data!['paths1'][0]['latitude'], data!['paths1'][0]['longitude']),
          infoWindow: InfoWindow(title: data!['startpoint name']),
          icon: BitmapDescriptor.fromBytes(_sourceIcon)),
      Marker(
          markerId: MarkerId(data!['endpoint name']),
          position: LatLng(
              data!['paths1'][data!['paths1'].length - 1]['latitude'],
              data!['paths1'][data!['paths1'].length - 1]['longitude']),
          infoWindow: InfoWindow(title: data!['endpoint name']),
          icon: BitmapDescriptor.fromBytes(_destinationIcon))
    ];
    setState(() {
      m.forEach((element) {
        _markers.add(element);
      });
    });
  }

  Future computeDistance() async {
    var p1 = geo.LatLng(data!['startpoint lat'], data!['startpoint lng']);
    var p2 = geo.LatLng(data!['endpoint lat'], data!['endpoint lng']);
    double _distance = geo.computeDistanceBetween(p1, p2) / 1000;
    setState(() {
      distance = '${_distance.toStringAsFixed(2)} km';
    });
  }

  Future _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Config().mapAPIKey,
      PointLatLng(
          data!['paths1'][0]['latitude'], data!['paths1'][0]['longitude']),
      PointLatLng(data!['paths1'][data!['paths1'].length - 1]['latitude'],
          data!['paths1'][data!['paths1'].length - 1]['longitude']),
      travelMode: TravelMode.walking,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    _addPolyLine();
  }

  _addPolyLine() async {
    final List<PointLatLng> points = [];
    for (var data in data!['paths1']) {
      PointLatLng point = PointLatLng(data['latitude'], data['longitude']);
      points.add(point);
    }

    final List<LatLng> polylineCoordinates = [];
    List<List<PointLatLng>> paths1 = await _getpaths1(points);
    for (int i = 0; i < points.length - 1; i++) {
      final latitude = points[i].latitude;
      final longitude = points[i].longitude;
      polylineCoordinates.add(LatLng(latitude, longitude));

      if (i < paths1.length) {
        for (int j = 0; j < paths1[i].length; j++) {
          final pathLatitude = paths1[i][j].latitude;
          final pathLongitude = paths1[i][j].longitude;
          polylineCoordinates.add(LatLng(pathLatitude, pathLongitude));
        }
      }
    }

// Add last point
    final lastLatitude = points.last.latitude;
    final lastLongitude = points.last.longitude;
    polylineCoordinates.add(LatLng(lastLatitude, lastLongitude));
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Color.fromARGB(255, 40, 122, 198),
      points: polylineCoordinates,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  Future<List<List<PointLatLng>>> _getpaths1(List<PointLatLng> points) async {
    List<List<PointLatLng>> paths1 = [];
    for (int i = 0; i < points.length - 1; i++) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        Config().mapAPIKey,
        points[i],
        points[i + 1],
        travelMode: TravelMode.driving,
      );
      paths1.add(result.points);
    }
    return paths1;
  }

  void animateCamera() {
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(
          data!['paths1'][0]['latitude'], data!['paths1'][0]['longitude']),
      zoom: 15,
      tilt: 50.0,
      bearing: 45.0,
    )));
  }

  void onMapCreated(controller) {
    // controller.setMapStyle(MapUtils.mapStyles);
    setState(() {
      mapController = controller;
    });
  }

  @override
  void initState() {
    super.initState();
    getMealsData();

    Future.delayed(Duration(milliseconds: 0)).then((value) async {
      context.read<AdsBloc>().initiateAds();
    });
    _setMarkerIcons()
        .then((value) => getData())
        .then((value) => addMarker())
        .then((value) {
      if (data!.isNotEmpty) {
        animateCamera();
      }
      _getPolyline();
      computeDistance();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geofenceService
          .addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
      _geofenceService.addLocationChangeListener(_onLocationChanged);
      _geofenceService.addLocationServicesStatusChangeListener(
          _onLocationServicesStatusChanged);
      _geofenceService.addActivityChangeListener(_onActivityChanged);
      _geofenceService.addStreamErrorListener(_onError);
      _geofenceService.start(_geofenceList).catchError(_onError);

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      var initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      var initializationSettingsIOS = IOSInitializationSettings();
      var initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS);
      flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Request permission to show notifications
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: false,
            badge: false,
            sound: false,
          );
      // Request permission to show notifications
    });

    _geofenceService
        .removeGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    // // _geofenceService.removeLocationChangeListener(_onLocationChanged);
    // // _geofenceService.removeLocationServicesStatusChangeListener(
    // //     _onLocationServicesStatusChanged);
    // // _geofenceService.removeActivityChangeListener(_onActivityChanged);
    // // _geofenceService.removeStreamErrorListener(_onError);
    // // _geofenceService.clearAllListeners();
    _geofenceService.stop();
  }

  final _geofenceService = GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 60000,
      statusChangeDelayMs: 10000,
      useActivityRecognition: true,
      allowMockLocations: false,
      printDevLog: false,
      geofenceRadiusSortType: GeofenceRadiusSortType.DESC);
  void _add1(List<dynamic> paths1Data) {
    _geofenceList.clear();
    _geofenceAudioUrls.clear();
    for (int i = 0; i < paths1Data.length; i++) {
      final path1 = paths1Data[i] as Map<String, dynamic>;
      final name = path1['name'];
      final latitude = path1['latitude'];
      final longitude = path1['longitude'];
      final audio = path1['audioUrl'];
      final radius = [
        GeofenceRadius(
          id: path1['radius'],
          length: 25,
        ),
        // GeofenceRadius(id: '$name-100m', length: 100),
        // GeofenceRadius(id: '$name-200m', length: 200),
        // GeofenceRadius(id: '$name-250m', length: 250),
      ];
      final geofence = Geofence(
        id: name,
        latitude: latitude,
        longitude: longitude,
        audio: audio,
        radius: radius,
      );
      _geofenceList.add(geofence);
      _geofenceAudioUrls[name] = audio;
    }
  }

  final _geofenceList = <Geofence>[];
  DateTime? _enterTime;
  DateTime? _exitTime;
  int _score = 0;
  List<String> _finishedLocations = [];
  List<String> _visitedLocations = [];
  Map<String, int> _scoreMap = {};
  Map<String, int> _locationScores = {};
  String _locationText = '';
  int _totalDuration = 0;
  int _rating = 0;
  DateTime? _firstEnterTime;
  String? _currentLocation;
  bool _isInsideGeofence = false;

  Future<void> _onGeofenceStatusChanged(
    Geofence geofence,
    GeofenceRadius geofenceRadius,
    GeofenceStatus geofenceStatus,
    Location location,
  ) async {
    print('geofence: ${geofence.toJson()}');
    print('geofenceRadius: ${geofenceRadius.toJson()}');
    print('geofenceStatus: ${geofenceStatus.toString()}');
    if (_geofenceList.isNotEmpty &&
        _geofenceList.contains(geofence) &&
        geofenceRadius.id ==
            _geofenceList[_geofenceList.indexOf(geofence)].radius.first.id) {
      final audioUrl = _geofenceAudioUrls[geofence.id];
      if (!_visitedLocations.contains(geofence.id)) {
        _enterTime = DateTime.now();
        _visitedLocations.add(geofence.id);
        _scoreMap.update(geofence.id, (value) => value + 1, ifAbsent: () => 1);
        _score += _scoreMap[geofence.id]!;
        _updateSummary(_score, _visitedLocations);
        _updateTotalDuration();
        _locationScores[geofence.id] = _scoreMap[geofence.id]!;
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(geofence.latitude, geofence.longitude),
              zoom: 19,
              tilt: 50.0,
              bearing: 45.0,
            ),
          ),
        );
        var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'channel id',
          'channel name',
          'channel_description',
          importance: Importance.max,
          priority: notification_enums.Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        var iOSPlatformChannelSpecifics = IOSNotificationDetails();
        var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );
        // Show notification
        await flutterLocalNotificationsPlugin.show(
          0,
          'เขตกิจกรรม',
          'คุณเข้าใกล้ ${geofence.id} ระยะ ${geofenceRadius.id}',
          platformChannelSpecifics,
          payload: 'item x',
        );
        assetsAudioPlayer.open(
          Audio.network(audioUrl!),
          respectSilentMode: true,
        );
      } else if (_finishedLocations.contains(geofence.id)) {
        // Code for when the geofence has already been finished
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('คุณได้ทำกิจกรรม ${geofence.id} ไปแล้ว'),
            duration: Duration(seconds: 1),
          ),
        );
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(geofence.latitude, geofence.longitude),
              zoom: 19,
              tilt: 50.0,
              bearing: 45.0,
            ),
          ),
        );
      } else if (geofenceStatus == GeofenceStatus.EXIT) {
        _finishedLocations.add(geofence.id);
        _exitTime = DateTime.now();
        assetsAudioPlayer.stop();
      }
      _currentLocation = geofence.id;
      _isInsideGeofence = geofenceStatus == GeofenceStatus.ENTER;
      // Calculate duration when all locations have been visited
    }
  }

  void resetData() {
    _enterTime = null;
    _exitTime = null;
    _score = 0;
    _finishedLocations = [];
    _visitedLocations = [];
    _scoreMap = {};
    _locationScores = {};
    _locationText = '';
    _totalDuration = 0;
    _rating = 0;
    _firstEnterTime = null;
    _currentLocation = null;
    _isInsideGeofence = false;
  }

  void onCancelOrRestart() {
    resetData();
    _updateSummary(0, []);
    assetsAudioPlayer.stop();
  }

  void _updateSummary(int score, List<String> visitedLocations) {
    setState(() {
      _score = score;
      _locationText =
          'คุณเข้าพื้นที่ไปแล้ว ${visitedLocations.length}/${_geofenceList.length} พื้นที่';
    });
  }

  void _updateTotalDuration() {
    if (_visitedLocations.length == 1) {
      _firstEnterTime = _enterTime;
    } else if (_visitedLocations.length == _geofenceList.length) {
      // แก้ตรงนี้
      Duration totalDuration = _exitTime!.difference(_firstEnterTime!);
      int hours = totalDuration.inHours;
      int minutes = totalDuration.inMinutes.remainder(60);
      int seconds = totalDuration.inSeconds.remainder(60);
      // int hours = 2; //ทดสอบตัวคะแนน
      // int minutes = 0;
      // int seconds = 0;
      _totalDuration = hours * 3600 + minutes * 60 + seconds;
    }
  }

  int calculateScore(double durationInSec) {
    //น้อยกว่า1ช.มให้ได้5คะแนน 1ช.มขึ้น ได้8คะแนน 2 ช.ม ขึ้นไปได้10 คะแนน
    if (durationInSec < 3600.0) {
      return 5;
    } else if (durationInSec < 7200.0) {
      return 8;
    } else {
      return 10;
    }
  }

  String getScoreDescription(int score) {
    switch (score) {
      case 10:
        return 'เยี่ยมมาก! คุณเป็นนักท่องเที่ยวที่ยอดเยี่ยม';
      case 8:
        return 'ดีมาก! คุณเป็นนักท่องเที่ยวที่เก่ง';
      case 5:
        return 'เก่งอยู่แล้ว! ยังมีโอกาสเพิ่มเติมในการท่องเที่ยว';
      default:
        return '';
    }
  }

  // This function is to be called when the activity has changed.
  void _onActivityChanged(Activity prevActivity, Activity currActivity) {
    // print('prevActivity: ${prevActivity.toJson()}');
    // print('currActivity: ${currActivity.toJson()}');
    _activityStreamController.sink.add(currActivity);
  }

  // This function is to be called when the location has changed.
  void _onLocationChanged(Location location) {
    // print('location: ${location.toJson()}');
  }

  // This function is to be called when a location services status change occurs
  // since the service was started.
  void _onLocationServicesStatusChanged(
    bool status,
  ) {
    print('isLocationServicesEnabled: $status');
  }

  // This function is used to handle errors that occur in the service.
  void _onError(error) {
    final errorCode = getErrorCodesFromError(error);
    if (errorCode == null) {
      print('Undefined error: $error');
      return;
    }

    // print('ErrorCode: $errorCode');
  }

  void _add(List<dynamic> paths1Data) async {
    final ImageCropper imageCropper = ImageCropper();
    for (final path1Data in paths1Data) {
      final name = path1Data['name'] as String;
      final detail = path1Data['detail'] as String;
      final image = path1Data['image'] as String;
      final latitude = path1Data['latitude'] as double;
      final longitude = path1Data['longitude'] as double;
      final MarkerId markerId = MarkerId(name);
      final Marker marker = Marker(
        markerId: markerId,
        position: LatLng(latitude, longitude),
        icon: await imageCropper.resizeAndCircle(image, 100),
        infoWindow: InfoWindow(
          title: name,
          snippet: detail,
        ),
        onTap: () {},
      );
      print("Adding marker $markerId");
      setState(() {
        markers[markerId] = marker;
      });
    }
  }

  Future<void> getMealsData() async {
    final DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.d!.timestamp)
        .collection('travel guide1')
        .doc(widget.d!.timestamp)
        .get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final paths1Data = data['paths1'] as List<dynamic>;
      _add(paths1Data);
      _add1(paths1Data);
    }
  }

  Widget _buildGeofenceMonitor() {
    return StreamBuilder<Geofence>(
      stream: _geofenceStreamController.stream,
      builder: (context, snapshot) {
        final updatedDateTime = DateTime.now();
        final content = snapshot.data?.toJson().toString() ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•\t\tGeofence (updated: $updatedDateTime)'),
            const SizedBox(
              height: 5.0,
              width: 200.0,
            ),
            Text(content),
          ],
        );
      },
    );
  }

  // Widget _buildContainer(List<Guide> mealsList) {
  //   return Align(
  //     alignment: Alignment.bottomLeft,
  //     child: Container(
  //       margin: EdgeInsets.symmetric(vertical: 20.0),
  //       height: 140.0,
  //       child: ListView.builder(
  //         itemCount: mealsList.length,
  //         scrollDirection: Axis.horizontal,
  //         itemBuilder: (context, index) {
  //           final Guide meals = mealsList[index];
  //           return _boxes(meals);
  //         },
  //       ),
  //     ),
  //   );
  // }

  // Widget _boxes(Guide meals) {
  //   return GestureDetector(
  //     onTap: () {
  //       _gotoLocation(meals.latitude, meals.longitude);
  //     },
  //     child: Container(
  //       margin: EdgeInsets.all(10),
  //       child: FittedBox(
  //         child: Material(
  //             color: Color(0xFF3B3B3B),
  //             elevation: 14.0,
  //             borderRadius: BorderRadius.circular(24.0),
  //             shadowColor: Color(0xFF383737),
  //             child: Row(
  //               children: [
  //                 Container(
  //                   width: 180,
  //                   height: 200,
  //                   child: ClipRRect(
  //                     borderRadius: BorderRadius.only(
  //                         topLeft: Radius.circular(24),
  //                         bottomLeft: Radius.circular(24)),
  //                     child: Image(
  //                       fit: BoxFit.fill,
  //                       image: NetworkImage(meals.image),
  //                     ),
  //                   ),
  //                 ),
  //                 Container(
  //                   width: 340,
  //                   height: 200,
  //                   padding: EdgeInsets.only(left: 15, right: 15, bottom: 4),
  //                   child: myDetailsContainer1(meals),
  //                 ),
  //               ],
  //             )),
  //       ),
  //     ),
  //   );
  // }

  // Widget myDetailsContainer1(Guide meals) {
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Container(
  //           child: Text(
  //         meals.name,
  //         style: TextStyle(
  //             color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold),
  //       )),
  //       Container(
  //           margin: EdgeInsets.only(top: 4),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //             children: <Widget>[
  //               // Container(
  //               //     child: Text(
  //               //   // meals.rating.toString(),
  //               //   style: TextStyle(
  //               //       color: Colors.orange,
  //               //       fontSize: 20.0,
  //               //       fontWeight: FontWeight.bold),
  //               // )),
  //               SizedBox(
  //                 width: 8,
  //               ),
  //               // RatingBar.builder(
  //               //   // initialRating: meals.rating,
  //               //   minRating: 1,
  //               //   direction: Axis.horizontal,
  //               //   allowHalfRating: true,
  //               //   updateOnDrag: false,
  //               //   ignoreGestures: true,
  //               //   itemSize: 35,
  //               //   itemCount: 5,
  //               //   itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
  //               //   itemBuilder: (context, _) => Icon(
  //               //     Icons.star,
  //               //     color: Colors.amber,
  //               //     size: 10,
  //               //   ),
  //               //   onRatingUpdate: (double value) {},
  //               // ),
  //               SizedBox(
  //                 width: 8,
  //               ),
  //               // Container(
  //               //     child: Text(
  //               //   "(${meals.id})",
  //               //   style: TextStyle(
  //               //       color: Colors.orange,
  //               //       fontSize: 20.0,
  //               //       fontWeight: FontWeight.bold),
  //               // )),
  //             ],
  //           )),
  //       Container(
  //           margin: EdgeInsets.only(top: 8),
  //           child: Text(
  //             meals.detail,
  //             maxLines: 2,
  //             overflow: TextOverflow.ellipsis,
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontSize: 18.0,
  //             ),
  //           )),
  //       Container(
  //           margin: EdgeInsets.only(top: 8),
  //           child: Text(
  //             "",
  //             style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 18.0,
  //                 fontWeight: FontWeight.bold),
  //           )),
  //     ],
  //   );
  // }

  Widget panelUI() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
            ),
          ],
        ),
        SizedBox(
          height: 10.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "travel guide(เที่ยวอิ่มท้อง)",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ).tr(),
          ],
        ),
        Container(
          margin: EdgeInsets.only(top: 8, bottom: 8),
          height: 3,
          width: 170,
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(40)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'คุณเข้าพื้นที่ไปแล้ว ${_visitedLocations.length}/${_geofenceList.length} พื้นที่',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                if (_visitedLocations.length == _geofenceList.length)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'คุณท่องเที่ยวเสร็จสิ้นทั้งหมดในเวลา ${_totalDuration != null ? '${_totalDuration ~/ 3600} ชั่วโมง ${(_totalDuration % 3600) ~/ 60} นาที ${_totalDuration % 60} วินาที' : '-'}',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ได้คะแนน ${calculateScore(_totalDuration.toDouble())} คะแนน\n${getScoreDescription(calculateScore(_totalDuration.toDouble()))}',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => onCancelOrRestart(),
                        child: Text(
                          'เริ่มการเดินทางอีกรอบ',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (_visitedLocations.isEmpty)
                  Text(
                    'คุณยังไม่ได้ท่องเที่ยวในพื้นที่',
                    style: TextStyle(
                      fontSize: 15.0,
                    ),
                  ),
                SizedBox(height: 8),
                if (_visitedLocations.length > 0 &&
                    _visitedLocations.length != _finishedLocations.length &&
                    _visitedLocations.length !=
                        _geofenceList.length) //ปุ่มยกเลิกการเดินทาง
                  ElevatedButton(
                    onPressed: onCancelOrRestart,
                    child: Text(
                      'ยกเลิกการเดินทาง',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Container(
            padding: EdgeInsets.all(15),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'steps',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ).tr(),
                Container(
                  margin: EdgeInsets.only(top: 8, bottom: 8),
                  height: 3,
                  width: 70,
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(40)),
                ),
              ],
            )),
        Expanded(
          child: data!.isEmpty
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.separated(
                  padding: EdgeInsets.only(bottom: 10),
                  itemCount: data!['paths1'].length,
                  itemBuilder: (BuildContext context, int index) {
                    final List paths1 = data!['paths1'];
                    paths1.sort((a, b) => a['name'].compareTo(b['name']));
                    final path1Data = paths1[index];
                    final name = path1Data['name'];
                    final image = path1Data['image'];
                    final detail = path1Data['detail'];
                    final audioUrl = path1Data['audioUrl'];
                    final latitude = path1Data['latitude'] as double;
                    final longitude = path1Data['longitude'] as double;
                    return Padding(
                      padding: const EdgeInsets.only(left: 5, right: 15),
                      child: Row(
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 15,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: ColorList().guideColors[
                                    index % ColorList().guideColors.length],
                              ),
                              Container(
                                height: 90,
                                width: 2,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  name,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                                SizedBox(height: 5),
                                Row(
                                  children: <Widget>[
                                    Image.network(
                                      image,
                                      width: 80,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          SizedBox(
                                            width: 17,
                                            height: 20,
                                          ),
                                          Text(
                                            detail,
                                            maxLines: 5,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              TextButton.icon(
                                                onPressed: () {
                                                  assetsAudioPlayer.open(
                                                    Audio.network(audioUrl!),
                                                  );
                                                },
                                                icon: Icon(Icons.volume_up),
                                                label: Text('เสียง'),
                                              ),
                                              // SizedBox(width: 10),
                                              TextButton.icon(
                                                onPressed: () {
                                                  mapController.animateCamera(
                                                    CameraUpdate
                                                        .newCameraPosition(
                                                      CameraPosition(
                                                        target: LatLng(latitude,
                                                            longitude),
                                                        zoom: 19,
                                                        tilt: 50.0,
                                                        bearing: 45.0,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon:
                                                    Icon(Icons.local_activity),
                                                label: Text('จุดบนแผนที่'),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return SizedBox();
                  },
                ),
        )
      ],
    );
  }

  Widget panelBodyUI(h, w) {
    return Container(
      width: w,
      child: GoogleMap(
        zoomControlsEnabled: false,
        initialCameraPosition: Config().initialCameraPosition,
        mapType: MapType.hybrid,
        onMapCreated: (controller) => onMapCreated(controller),
        // markers: Set.from(_markers),
        markers: Set<Marker>.of(markers.values),
        polylines: Set<Polyline>.of(polylines.values),
        compassEnabled: true,
        myLocationEnabled: true,
        zoomGesturesEnabled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return new Scaffold(
        body: SafeArea(
      child: Stack(children: <Widget>[
        panelBodyUI(h, w),
        // _buildGeofenceMonitor(),
        // panelUI(),
        // StreamBuilder<QuerySnapshot>(
        //   stream: FirebaseFirestore.instance
        //       .collection('places')
        //       .doc(widget.d!.timestamp)
        //       .collection("travel guide")
        //       .orderBy("name")
        //       .snapshots(),
        //   builder: (context, snapshot) {
        //     if (!snapshot.hasData) {
        //       return LinearProgressIndicator();
        //     } else {
        //       List<Guide> mealsList = [];
        //       snapshot.data?.docs.forEach((document) {
        //         final meals = Guide(
        //           name: document['name'],
        //           id: document.id,
        //           detail: document['detail'],
        //           image: document['image'],
        //           latitude: document['latitude'].toDouble(),
        //           longitude: document['longitude'].toDouble(),
        //           // rating: document['rating'].toDouble(),
        //         );
        //         mealsList.add(meals);
        //       });
        //       return _buildContainer(mealsList);
        //     }
        //   },
        // ),
        SlidingUpPanel(
            minHeight: 125,
            maxHeight: MediaQuery.of(context).size.height * 0.80,
            backdropEnabled: true,
            backdropOpacity: 0.2,
            backdropTapClosesPanel: true,
            isDraggable: true,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                  color: Colors.grey[400]!, blurRadius: 4, offset: Offset(1, 0))
            ],
            padding: EdgeInsets.only(top: 15, left: 10, bottom: 0, right: 10),
            panel: panelUI(),
            body: panelBodyUI(h, w)),
        Positioned(
          top: 15,
          left: 50,
          child: Container(
            child: Row(
              children: <Widget>[
                InkWell(
                  child: Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                              color: Colors.grey[300]!,
                              blurRadius: 10,
                              offset: Offset(3, 3))
                        ]),
                    child: Icon(Icons.keyboard_backspace),
                  ),
                  onTap: () {
                    // _geofenceService.removeGeofenceStatusChangeListener(
                    //     _onGeofenceStatusChanged);
                    // _geofenceService
                    //     .removeLocationChangeListener(_onLocationChanged);
                    // _geofenceService.removeLocationServicesStatusChangeListener(
                    //     _onLocationServicesStatusChanged);
                    // _geofenceService
                    //     .removeActivityChangeListener(_onActivityChanged);
                    // _geofenceService.removeStreamErrorListener(_onError);
                    // _geofenceService.clearAllListeners();
                    _geofenceService.stop();
                    assetsAudioPlayer.stop();
                    Navigator.pop(context);
                  },
                ),
                SizedBox(
                  width: 5,
                ),
                data!.isEmpty
                    ? Container()
                    : Container(
                        width: MediaQuery.of(context).size.width * 0.60,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey, width: 0.5)),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 15, top: 10, bottom: 10, right: 15),
                          child: Text(
                            '${data!['startpoint name']} - ${data!['endpoint name']}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
        data!.isEmpty && polylines.isEmpty
            ? Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              )
            : Container()
      ]),
    ));
  }

  Future<void> _gotoLocation(double lat, double long) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(lat, long),
      zoom: 25,
      tilt: 50.0,
      bearing: 45.0,
    )));
  }
}
