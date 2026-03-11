
import 'package:cloud_firestore/cloud_firestore.dart';

class Prestador {
  final String uid;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final bool isOnline;
  final GeoPoint? location;
  final double ratingAvg;
  final int ratingCount;
  final List<String> categories;
  final Map<String, List<String>> workingHours;
  final List<DateTime> blockedDates;

  Prestador({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.isOnline = false,
    this.location,
    this.categories = const [],
    this.workingHours = const {},
    this.blockedDates = const [],
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  factory Prestador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse workingHours
    final Map<String, List<String>> parsedHours = {};
    if (data['workingHours'] is Map) {
      (data['workingHours'] as Map).forEach((key, value) {
        if (value is List) {
          parsedHours[key.toString()] = value.map((e) => e.toString()).toList();
        }
      });
    }

    // Parse blockedDates
    List<DateTime> parsedBlockedDates = [];
    if (data['blockedDates'] is List) {
      parsedBlockedDates = (data['blockedDates'] as List).map((e) {
        if (e is Timestamp) return e.toDate();
        return DateTime.now(); // Fallback
      }).toList();
    }

    return Prestador(
      uid: doc.id,
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      isOnline: data['isOnline'] ?? false,
      location: data['lastLocation'] as GeoPoint?, 
      categories: List<String>.from(data['categories'] ?? []),
      workingHours: parsedHours,
      blockedDates: parsedBlockedDates,
      ratingAvg: (data['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (bio != null) 'bio': bio,
      'isOnline': isOnline,
      if (location != null) 'lastLocation': location,
      'categories': categories,
      'workingHours': workingHours,
      'blockedDates': blockedDates.map((e) => Timestamp.fromDate(e)).toList(),
    };
  }
}
