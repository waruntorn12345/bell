import 'package:cloud_firestore/cloud_firestore.dart';

class Guide {
  String? startpointName;
  String? endpointName;
  double? startpointName1;
  double? endpointName1;
  double? startpointName2;
  double? endpointName2;
  String? price;
  List? paths;
  List? paths1;
  List? paths2;
  String? name;
  String? detail;
  String? image;
  final String id;
  final double latitude;
  final double longitude;
  int? radius;
  String? audioUrl;

  Guide({
    this.startpointName,
    this.endpointName,
    this.startpointName1,
    this.endpointName1,
    this.startpointName2,
    this.endpointName2,
    this.price,
    this.paths,
    this.paths1,
    this.paths2,
    this.name,
    this.image,
    this.detail,
    required this.latitude,
    required this.longitude,
    this.radius,
    this.audioUrl,
    required this.id,
  });

  factory Guide.fromFirestore(DocumentSnapshot snapshot) {
    Map d = snapshot.data() as Map<dynamic, dynamic>;
    return Guide(
      startpointName: d['startpoint name'],
      endpointName: d['endpoint name'],
      startpointName1: d['startpointName1'],
      endpointName1: d['endpointName1'],
      startpointName2: d['startpointName2'],
      endpointName2: d['endpointName2'],
      price: d['price'],
      paths: d['paths'],
      paths1: d['paths1'],
      paths2: d['paths2'],
      name: d['name'],
      detail: d['detail'],
      image: d['image'],
      latitude: d['latitude'],
      longitude: d['longitude'],
      radius: d['radius'],
      audioUrl: d['audioUrl'],
      id: d['id'],
    );
  }
}
