import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Config {
  final String appName = 'Travel Together';
  final String mapAPIKey = 'AIzaSyCjQksUJ7yWe1Qgq5vLx4nE6RvnQJCvNsI';
  final String countryName = 'Bangladesh';
  final String splashIcon = 'assets/images/splash.png';
  final String supportEmail = 'waruntorn83@gmail.com';
  final String privacyPolicyUrl = 'https://www.mrb-lab.com/privacy-policy';
  final String iOSAppId = '000000';

  final String yourWebsiteUrl = 'https://www.mrb-lab.com';
  final String facebookPageUrl = 'https://www.facebook.com/bell.kui';
  final String youtubeChannelUrl =
      'https://www.youtube.com/channel/UCxnJ_4zcgz0jaUEtk_5OQgQ';

  // app theme color - primary color
  static final Color appThemeColor = Colors.blueAccent;

  //special two states name that has been already upload from the admin panel
  final String specialState1 = 'วัดไร่ขิงพระอารามหลวง';
  final String specialState2 = 'ตลาดน้ำดอนหวาย';

  //relplace by your country lattitude & longitude
  final CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(13.744876, 100.259291), //here
    zoom: 20,
  );

  //google maps marker icons
  final String hotelIcon = 'assets/images/hotel.png';
  final String restaurantIcon = 'assets/images/restaurant.png';
  final String hotelPinIcon = 'assets/images/hotel_pin.png';
  final String restaurantPinIcon = 'assets/images/restaurant_pin.png';
  final String drivingMarkerIcon = 'assets/images/driving_pin.png';
  final String destinationMarkerIcon =
      'assets/images/destination_map_marker.png';

  //Intro images
  final String introImage1 = 'assets/images/travel6.png';
  final String introImage2 = 'assets/images/travel1.png';
  final String introImage3 = 'assets/images/travel5.png';

  //Language Setup
  final List<String> languages = ['English', 'Thai'];

  static const String emptyImage =
      'https://innov8tiv.com/wp-content/uploads/2017/10/blank-screen-google-play-store-1280x720.png';
}
