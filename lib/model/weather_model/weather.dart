import 'dart:convert';
import 'package:http/http.dart' as http;

class Weather {
  final String description;
  final double temperature;
  final String icon;

  Weather({
    required this.description,
    required this.temperature,
    required this.icon,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    try {
      return Weather(
        description: json['weather'][0]['description'] ?? 'No description',
        temperature: (json['main']['temp'] as num?)?.toDouble() ?? 0.0,
        icon: json['weather'][0]['icon'] ?? '',
      );
    } catch (e) {
      print('Error parsing weather data: $e');
      return Weather(
        description: 'No data',
        temperature: 0.0,
        icon: '',
      );
    }
  }
}

//suitelink
class WeatherService {
  final String apiKey = 'e7843c5b13d693cecf93dd5a566795a2';

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
