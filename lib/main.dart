import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WeatherApp());
}

/* ===================== APP ROOT ===================== */
class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ultra Weather',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Playfair',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            fontSize: 30,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: Colors.white70,
          ),
          headlineLarge: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            fontSize: 76,
            color: Colors.white,
          ),
          labelSmall: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      home: const WeatherHome(),
    );
  }
}

/* ===================== HOME ===================== */
class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  final TextEditingController _controller = TextEditingController();

  bool _loading = false;
  String _error = '';
  WeatherData? _weather;

  static const String apiKey = ' API_KEY_HERE ';

  Future<void> fetchWeather(String city) async {
    if (city.isEmpty) return;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final uri = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/weather',
        {
          'q': city,
          'appid': apiKey,
          'units': 'metric',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _weather = WeatherData.fromJson(data);
        });
      } else {
        setState(() {
          _error = 'City not found';
          _weather = null;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Network error';
        _weather = null;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/weather_bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: _weather == null
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  _searchBar(),
                  if (_weather != null) const SizedBox(height: 30),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),

                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _errorWidget(),
                    ),

                  if (_weather != null) _weatherCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* ===================== UI ===================== */
  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: fetchWeather,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search city',
              hintStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.25),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 30),
          onPressed: () => fetchWeather(_controller.text),
        )
      ],
    );
  }

  Widget _weatherCard() {
    return Expanded(
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_weather!.city, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '${_weather!.temperature.toStringAsFixed(1)}°C',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _weather!.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                WeatherInfo(
                    label: 'Humidity', value: '${_weather!.humidity}%'),
                WeatherInfo(label: 'Wind', value: '${_weather!.wind} m/s'),
                WeatherInfo(label: 'Pressure', value: '${_weather!.pressure} hPa'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return const Text(
      'Something went wrong',
      style: TextStyle(color: Colors.redAccent, fontSize: 18),
    );
  }
}

/* ===================== MODEL ===================== */
class WeatherData {
  final String city;
  final double temperature;
  final String description;
  final int humidity;
  final double wind;
  final int pressure;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.wind,
    required this.pressure,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      city: json['name'],
      temperature: (json['main']['temp']).toDouble(),
      description: json['weather'][0]['description'],
      humidity: json['main']['humidity'],
      wind: (json['wind']['speed']).toDouble(),
      pressure: json['main']['pressure'],
    );
  }
}

/* ===================== COMPONENTS ===================== */
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: child,
    );
  }
}

class WeatherInfo extends StatelessWidget {
  final String label;
  final String value;

  const WeatherInfo({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
