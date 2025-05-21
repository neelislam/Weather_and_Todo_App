import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui'; //Import for ImageFilter
import 'todo_list_page.dart'; //Import the new ToDoList page

//ThemeProvider Class
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode'; // Key for SharedPreferences
  late bool _isDarkMode;

  //Constructor: initializes with the provided initial theme mode
  ThemeProvider(this._isDarkMode);

  //Getter for current dark mode status
  bool get isDarkMode => _isDarkMode;

  //Getter for the current ThemeData light or dark
  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  //light theme
  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue, //Primary color for light mode
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
      secondary: Colors.amber, // Accent color for light mode
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.orangeAccent,
      foregroundColor: Colors.black,
      elevation: 25,
    ),
    cardColor: Colors.redAccent, // Existing card color for light mode
    scaffoldBackgroundColor: Colors.blueGrey,
    // buttonTheme: ButtonThemeData(
    //   buttonColor: Colors.red,
    //   textTheme: ButtonTextTheme.primary,
    // ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.black),
      hintStyle: TextStyle(color: Colors.black45),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
  );

  //dark theme
  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.indigo, //Primary color for dark mode
    primaryColor: Colors.indigo,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo).copyWith(
      secondary: Colors.tealAccent, //Accent color for dark mode
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    cardColor: Colors.grey[850], // Existing card color for dark mode
    scaffoldBackgroundColor: Colors.grey[900],
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.indigo,
      textTheme: ButtonTextTheme.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.white),
      hintStyle: TextStyle(color: Colors.grey[500]),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.grey[300]),
    ),
  );

  // Toggles the theme and saves the preference to SharedPreferences
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Notify listeners to rebuild widgets that depend on this provider
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  // Static method to retrieve the initial theme mode from SharedPreferences
  static Future<bool> getInitialThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false; // Default to light mode if no preference is saved
  }
}
// --- End ThemeProvider Class ---

class WeatherApp extends StatelessWidget {
  const WeatherApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return WeatherHome(
          toggleTheme: themeProvider.toggleTheme, // Pass the toggle function
          isDarkMode: themeProvider.isDarkMode, // Pass the current theme mode
        );
      },
    );
  }
}

class WeatherHome extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const WeatherHome({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  final String apiKey = '7b324b1582e50e7b3e38d081ee3c9775'; // Your OpenWeatherMap API Key
  final TextEditingController _cityController = TextEditingController();

  String _city = '';
  String _weatherMain = '';
  String _weatherDescription = '';
  double _temperature = 0.0;
  String _suggestion = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationWeather(); // Fetch weather on app start
  }

  Future<void> _getCurrentLocationWeather() async {
    setState(() => _isLoading = true);
    try {
      final position = await _determinePosition(); // Get current GPS position
      await _fetchWeatherByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains(']')) {
        errorMessage = errorMessage.split(']')[1].trim();
      }
      _showError('Location error: $errorMessage');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error(
          'Location services are disabled. Please enable them in your device settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error(
            'Location permissions are denied. Please grant permission for location services.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied. Please enable them from app settings.');
    }

    // When permissions are granted, get the current position.
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high); // Request high accuracy
  }

  // Fetches weather data for a specified city name
  Future<void> _fetchWeatherByCity() async {
    final String cityName = _cityController.text.trim();
    if (cityName.isEmpty) {
      _showError('Please enter a city name.');
      return;
    }

    setState(() {
      _isLoading = true;
      _city = cityName; // Optimistically update city for immediate UI feedback
    });

    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric';
    await _fetchWeatherData(url);
  }

  // Fetches weather data for given coordinates
  Future<void> _fetchWeatherByCoordinates(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    await _fetchWeatherData(url);
  }

  // Generic function to fetch weather data from OpenWeatherMap API
  Future<void> _fetchWeatherData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _updateWeatherData(data);
      } else if (response.statusCode == 404) {
        throw Exception('City not found. Please check the city name.');
      } else {
        throw Exception(
            'Failed to fetch weather data: HTTP ${response.statusCode}');
      }
    } catch (e) {
      // Log error for debugging
      print('Weather API Error: $e');
      _showError('Error fetching weather: ${e.toString()}');
      _resetWeatherData(); // Clear previous data on error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Updates the UI with fetched weather data
  void _updateWeatherData(Map<String, dynamic> data) {
    setState(() {
      _city = data['name'] ?? 'Unknown City'; // City name from API response
      if (data.containsKey('weather') && data['weather'].isNotEmpty) {
        _weatherMain = data['weather'][0]['main'] ?? '';
        _weatherDescription = data['weather'][0]['description'] ?? '';
      } else {
        _weatherMain = 'N/A';
        _weatherDescription = 'No weather information available';
      }
      _temperature = (data['main']['temp'] as num?)?.toDouble() ?? 0.0;
      _suggestion = _getWeatherSuggestion(_weatherMain, _temperature);
    });
  }

  // Resets weather data to initial loading state
  void _resetWeatherData() {
    setState(() {
      _city = '';
      _weatherMain = 'Loading...';
      _weatherDescription = 'Fetching weather data...';
      _temperature = 0.0;
      _suggestion = 'Please wait or try again.';
    });
  }

  // Provides weather-based suggestions
  String _getWeatherSuggestion(String weather, double temp) {
    final weatherLower = weather.toLowerCase();
    if (weatherLower.contains('thunderstorm')) {
      return '⚠️ Stay indoors! A thunderstorm is expected. Unplug electronics.';
    }
    if (weatherLower.contains('rain') || weatherLower.contains('drizzle')) {
      return '🌧️ Don\'t forget your umbrella and raincoat. Drive carefully.';
    }
    if (weatherLower.contains('snow')) {
      return '❄️ Bundle up! It\'s snowing. Be careful on slippery surfaces.';
    }
    if (temp > 30) {
      return '☀️ It\'s a hot day! Stay hydrated, wear light clothes. Avoid peak sun hours.';
    }
    if (temp < 10) {
      return '🥶 It\'s chilly! Wear warm clothes and a jacket.';
    }
    if (weatherLower.contains('clear')) {
      return '🌞 Enjoy the clear sky! Consider wearing sunglasses and sunscreen.';
    }
    if (weatherLower.contains('clouds')) {
      return '☁️ It\'s a cloudy day. Perfect for a walk, but keep an eye on the sky.';
    }
    if (weatherLower.contains('mist') ||
        weatherLower.contains('fog') ||
        weatherLower.contains('haze')) {
      return '🌫️ Limited visibility. Drive with caution and use fog lights.';
    }
    return 'Enjoy your day! Have a good one.';
  }

  // Displays a SnackBar with an error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() {
      _weatherMain = 'Error';
      _weatherDescription = message;
      _suggestion = 'Please try again later.';
      _isLoading = false;
    });
  }

  // Handles user sign out
  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      // The StreamBuilder in main.dart will automatically navigate to SignInPage
    } catch (e) {
      _showError('Error signing out: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Navigates to the ToDoList page
  void _navigateToToDoList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const toDolist()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_city.isEmpty ? 'Weather App' : 'Weather in $_city'),
        centerTitle: true,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          // Add button to navigate to ToDoList
          IconButton(
            icon: const Icon(Icons.list_alt), // Icon for the to-do list
            onPressed: _navigateToToDoList,
            tooltip: 'ToDo List',
          ),
          // Sign out button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : RefreshIndicator(
        //Allows pull-to-refresh functionality
        onRefresh:
        _city.isEmpty ? _getCurrentLocationWeather : _fetchWeatherByCity,
        child: SingleChildScrollView(
          physics:  AlwaysScrollableScrollPhysics(), // Ensures scroll ability even if content fits
          padding:  EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               _buildWeatherInfo(),
               SizedBox(height: 40),
              _buildSearchBar(),
              SizedBox(height: 20),
              _buildLocationButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the city search input field
  Widget _buildSearchBar() {
    return TextField(
      controller: _cityController,
      decoration: InputDecoration(
        labelText: 'Enter city name',
        hintText: 'e.g., London, New York',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: _fetchWeatherByCity,
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
      ),
      onSubmitted: (_) => _fetchWeatherByCity(), // Trigger search on keyboard submit
    );
  }

  // Builds the "Use Current Location" button


  // Builds the main weather information display
  Widget _buildWeatherInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        //Glassmorphism box for main weather info
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2), //Shadow for the glass effect
                blurRadius: 20,
                spreadRadius: 5,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), //Apply blur effect
              child: Container(
                padding: EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  //Translucent background color based on theme's card color
                  color: Theme.of(context).cardColor.withOpacity(0.3),
                  border: Border.all(
                    // Subtle border for the glass effect
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  //mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      _getWeatherIcon(_weatherMain), // Dynamic weather icon
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      _weatherMain,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      //textAlign: TextAlign.right,
                    ),
                  SizedBox(height: 5),
                    Text(
                      _weatherDescription.capitalize(), //Capitalize first letter
                      style: TextStyle(
                          fontSize: 20,
                          color:
                          Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
                      //textAlign: TextAlign.right,
                    ),
                     SizedBox(height: 12),
                    Text(
                      '${_temperature.toStringAsFixed(1)} °C', // Format temperature to one decimal
                      style:  TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
         SizedBox(height: 20), // Space between glass box and tip card
        //Existing Card for Quick Tip, with adjusted translucency
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin:  EdgeInsets.symmetric(horizontal: 10),
          color: widget.isDarkMode
              ? Colors.grey[800]!.withOpacity(0.5) // Make it more translucent for dark mode
              : Colors.blue.shade50!.withOpacity(0.5), // Make it more translucent for light mode
          child: Padding(
            padding:  EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Text(
                //   'Quick Tip:',
                //   style: TextStyle(
                //       fontSize: 20,
                //       fontWeight: FontWeight.bold,
                //       fontStyle: FontStyle.italic,
                //       color: Colors.black),
                //   textAlign: TextAlign.left,//Theme.of(context).colorScheme.primary),
                // ),
              SizedBox(height: 10),
                Text(
                  'Quick Tips: $_suggestion',
                  style: TextStyle(
                      fontSize: 24,
                      //fontStyle: FontStyle.italic,
                      color: Colors.white,
                    fontWeight: FontWeight.bold,) , //Theme.of(context).textTheme.bodyMedium?.color),
                  //textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildLocationButton() {
    return ElevatedButton.icon(
      onPressed: _getCurrentLocationWeather,
      icon: const Icon(Icons.location_on),
      label: const Text('Use Current Location'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
        backgroundColor:
        Theme.of(context).colorScheme.secondary, // Use accent color
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white, // Text color contrast
      ),
    );
  }
  // Helper function to get appropriate weather icon
  IconData _getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return Icons.sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.cloudy_snowing;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy; // Default icon
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}

// Extension to capitalize the first letter of a string
extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
