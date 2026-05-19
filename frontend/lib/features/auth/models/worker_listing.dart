import 'package:flutter/material.dart';

class WorkerListing {
  const WorkerListing({
    required this.id,
    required this.name,
    required this.fullName,
    required this.category,
    required this.city,
    required this.skills,
    required this.bio,
    required this.rate,
    required this.isVerified,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String fullName;
  final String category;
  final String city;
  final String skills;
  final String bio;
  final double rate;
  final bool isVerified;
  final bool isAvailable;

  factory WorkerListing.fromJson(dynamic json) {
    final map = json is Map ? json : <String, dynamic>{};
    final user = map['User'] is Map ? map['User'] as Map : null;
    final profile = map['WorkerProfile'] is Map
        ? map['WorkerProfile'] as Map
        : map;
    final email = map['email']?.toString() ?? user?['email']?.toString();
    final name = _nameFromEmail(email) ?? "Worker";
    final rawRate = profile['rate'];
    final skills = _readText(profile['skills']);
    final trade = _readText(
      profile['category'],
      fallback: _firstSkill(skills) ?? "Worker",
    );
    final city = _readText(profile['city'], fallback: "Riyadh");

    return WorkerListing(
      id: _readText(map['id'] ?? user?['id']),
      name: name,
      fullName: name,
      category: trade,
      city: city,
      skills: skills,
      bio: _readText(
        profile['bio'],
        fallback:
            "Experienced $trade available for jobs in $city. Contact to discuss availability, timing, and job details.",
      ),
      rate: rawRate is num
          ? rawRate.toDouble()
          : double.tryParse("$rawRate") ?? 0,
      isVerified: profile['isVerified'] == true,
      isAvailable: true,
    );
  }

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      final end = words.first.length < 2 ? words.first.length : 2;
      return words.first.substring(0, end).toUpperCase();
    }
    return "${words.first[0]}${words.last[0]}".toUpperCase();
  }

  double get ratingValue => isVerified ? 4.9 : 4.5;
  String get rating => ratingValue.toStringAsFixed(1);
  int get jobsDone => isVerified ? 38 : 0;
  String get jobsLabel => isVerified ? "$jobsDone jobs" : "0 jobs";
  int get experienceYears => isVerified ? 5 : 1;
  int get reviewCount => isVerified ? 36 : 0;
  String get distanceLabel => isVerified ? "2.1km" : "3.8km";
  String get rateLabel =>
      rate > 0 ? "SAR\n${rate.toStringAsFixed(0)}" : "SAR\n--";
  Color get color => isVerified ? const Color(0xFF005BAC) : Colors.lightGreen;

  Map<String, dynamic> toProfileMap() {
    return {
      'id': id,
      'name': name,
      'fullName': fullName,
      'initials': initials,
      'trade': category,
      'city': city,
      'skills': skills,
      'distance': distanceLabel,
      'rating': ratingValue,
      'reviews': reviewCount,
      'jobsDone': jobsDone,
      'experience': experienceYears,
      'rate': rate.round(),
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'color': color,
      'bio': bio,
      'review': isVerified
          ? "Finished the work on time and kept everything tidy."
          : "New on Honar and ready to take jobs.",
      'reviewerName': isVerified ? "Sarah M." : "Honar user",
    };
  }

  static String _readText(dynamic value, {String fallback = ""}) {
    final text = value?.toString().trim() ?? "";
    return text.isEmpty ? fallback : text;
  }

  static String? _nameFromEmail(String? email) {
    if (email == null || email.trim().isEmpty) return null;
    final handle = email.split('@').first;
    final words = handle
        .split(RegExp(r'[._-]+'))
        .where((word) => word.trim().isNotEmpty)
        .map((word) => "${word[0].toUpperCase()}${word.substring(1)}");
    return words.isEmpty ? null : words.join(" ");
  }

  static String? _firstSkill(String skills) {
    final values = skills
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty);
    return values.isEmpty ? null : values.first;
  }
}
