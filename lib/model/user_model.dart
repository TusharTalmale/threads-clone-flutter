
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String? description;
  final String? avatar_url; // <-- CHANGED TO avatar_url to match Firestore field

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.description,
    this.avatar_url, // <-- CHANGED HERE
  });

  // Factory constructor to create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? '',
      description: data['description'],
      avatar_url: data['avatar_url'], // <-- Ensure this matches your Firestore field
    );
  }

  // Method to convert UserModel to a Map for Firestore (useful for updating profile)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'description': description,
      'avatar_url': avatar_url,
    };
  }
}