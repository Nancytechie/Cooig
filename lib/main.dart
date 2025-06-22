import 'package:cooig_firebase/splashscreen/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _spotifyAccessToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _getSpotifyAccessToken();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getSpotifyAccessToken() async {
    const String clientId = '5ad3ac6e91e64df59f6949998235db4e';
    const String clientSecret = 'YOUR_CLIENT_SECRET'; // Replace this
    const String tokenUrl = 'https://accounts.spotify.com/api/token';

    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final String accessToken = jsonResponse['access_token'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('spotify_access_token', accessToken);

      setState(() {
        _spotifyAccessToken = accessToken;
      });
    } else {
      print('Failed to get Spotify access token');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : const homescreen(),
    );
  }
}
