import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/area_waitlist.dart';
import '../core/constants/app_constants.dart';

class WaitlistProvider extends ChangeNotifier {
  List<AreaWaitlist> _myWaitlist = [];
  List<dynamic> _adminWaitlist = [];
  bool _isLoading = false;
  String? _error;

  List<AreaWaitlist> get myWaitlist => _myWaitlist;
  List<dynamic> get adminWaitlist => _adminWaitlist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static String get _apiUrl => AppConstants.apiUrl;

  Future<bool> joinWaitlist({
    required String areaName,
    required String region,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? email,
    required String authToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/area-waitlist/join'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: json.encode({
              'area_name': areaName,
              'region': region,
              'latitude': latitude,
              'longitude': longitude,
              'phone_number': phoneNumber,
              'email': email,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>?;
        if (data != null) {
          final newEntry = AreaWaitlist.fromStrapi(data);
          _myWaitlist.add(newEntry);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        _error = 'Failed to join waitlist';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> getMyWaitlist(String authToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/area-waitlist/my-entries'),
            headers: {'Authorization': 'Bearer $authToken'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          _myWaitlist =
              data.map((item) => AreaWaitlist.fromStrapi(item)).toList();
        }
      } else {
        _error = 'Failed to fetch waitlist';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> getAdminWaitlist(String authToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/area-waitlist/admin/all'),
            headers: {'Authorization': 'Bearer $authToken'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          _adminWaitlist = data;
        }
      } else {
        _error = 'Failed to fetch admin waitlist';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> notifyArea({
    required String region,
    required String areaName,
    required String authToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/area-waitlist/admin/notify'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: json.encode({
              'region': region,
              'area_name': areaName,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (!success) {
        _error = 'Failed to notify area';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromWaitlist(String id, String authToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .delete(
            Uri.parse('$_apiUrl/area-waitlist/$id/remove'),
            headers: {'Authorization': 'Bearer $authToken'},
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        _myWaitlist.removeWhere((item) => item.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to remove from waitlist';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Check if already on waitlist for area
  bool isOnWaitlist(String areaName, String region) {
    return _myWaitlist.any(
      (item) =>
          item.areaName.toLowerCase() == areaName.toLowerCase() &&
          item.region.toLowerCase() == region.toLowerCase() &&
          item.status != 'inactive',
    );
  }

  // Get high priority areas (more than 5 people waiting)
  List<dynamic> getHighPriorityAreas() {
    return _adminWaitlist.where((area) => area['priority'] == 'high').toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
