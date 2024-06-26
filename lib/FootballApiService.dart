import 'dart:convert';
import 'package:http/http.dart' as http;

class TooManyRequestsException implements Exception {
  final String message;
  TooManyRequestsException(this.message);
}

class FootballAPIService {
  static const String _baseUrl = 'http://localhost:3000/api';

  Future<List<dynamic>> fetchNextWeekLiveScores(String league) async {
    final response = await http.get(Uri.parse('$_baseUrl/$league/next-week-live-scores'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['matches'];
    } else if (response.statusCode == 429) {
      throw TooManyRequestsException('Too many requests. Please try again later.');
    } else {
      throw Exception('Failed to load next week live scores');
    }
  }

  Future<List<dynamic>> fetchTodayFinishedMatches(String league) async {
    final response = await http.get(Uri.parse('$_baseUrl/$league/results'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['matches'];
    } else if (response.statusCode == 429) {
      throw TooManyRequestsException('Too many requests. Please try again later.');
    } else {
      throw Exception('Failed to load today\'s finished matches');
    }
  }

  Future<List<dynamic>> fetchLastMonthFinishedMatches(String league) async {
    final response = await http.get(Uri.parse('$_baseUrl/$league/last-month-results'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['matches'];
    } else if (response.statusCode == 429) {
      throw TooManyRequestsException('Too many requests. Please try again later.');
    } else {
      throw Exception('Failed to load last month\'s finished matches');
    }
  }
}
