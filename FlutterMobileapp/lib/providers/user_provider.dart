import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String? _name;
  String? _email;
  String? _profilePhoto;
  bool _pushNotifications = true;
  bool _emailNotifications = true;

  String? get name => _name;
  String? get email => _email;
  String? get profilePhoto => _profilePhoto;
  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;

  bool get isLoggedIn => _email != null;

  UserProvider() {
    _loadUser();
  }

  Future<void> setUser(String name, String email,
      {String? profilePhoto,
      bool? pushNotifications,
      bool? emailNotifications}) async {
    _name = name;
    _email = email;
    _profilePhoto = profilePhoto;
    if (pushNotifications != null) _pushNotifications = pushNotifications;
    if (emailNotifications != null) _emailNotifications = emailNotifications;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('email_notifications', _emailNotifications);

    if (profilePhoto != null) {
      await prefs.setString('user_photo', profilePhoto);
    } else {
      await prefs.remove('user_photo');
    }

    notifyListeners();
  }

  Future<void> updateSettings(
      {bool? pushNotifications, bool? emailNotifications}) async {
    if (pushNotifications != null) _pushNotifications = pushNotifications;
    if (emailNotifications != null) _emailNotifications = emailNotifications;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('email_notifications', _emailNotifications);

    notifyListeners();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name');
    _email = prefs.getString('user_email');
    _profilePhoto = prefs.getString('user_photo');
    _pushNotifications = prefs.getBool('push_notifications') ?? true;
    _emailNotifications = prefs.getBool('email_notifications') ?? true;
    notifyListeners();
  }

  Future<void> clearUser() async {
    _name = null;
    _email = null;
    _profilePhoto = null;
    _pushNotifications = true;
    _emailNotifications = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_photo');
    await prefs.remove('push_notifications');
    await prefs.remove('email_notifications');

    notifyListeners();
  }
}
