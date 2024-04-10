import 'dart:convert';
import 'package:http/http.dart' as http;

class FootballAPIService {
  static const String _baseUrl = 'http://localhost:3000/api';

  Future<List<dynamic>> fetchNextWeekLiveScores(String league) async {
    final response = await http.get(Uri.parse('$_baseUrl/$league/next-week-live-scores'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['matches'];
    } else {
      throw Exception('Failed to load next week live scores');
    }
  }


  Future<List<dynamic>> fetchTodayFinishedMatches(String league) async {
    final response = await http.get(Uri.parse('$_baseUrl/$league/results'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['matches'];
    } else {
      throw Exception('Failed to load today\'s finished matches');
    }
  }
}
