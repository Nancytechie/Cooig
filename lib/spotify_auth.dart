import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyAuthScreen extends StatelessWidget {
  final String clientId =
      '5ad3ac6e91e64df59f6949998235db4e'; // Replace with your Spotify client ID
  final String redirectUri = 'cooig://callback';
  final String scopes = 'user-read-private user-read-email';

  const SpotifyAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login with Spotify")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _launchSpotifyAuth();
          },
          child: const Text("Login with Spotify"),
        ),
      ),
    );
  }

  void _launchSpotifyAuth() async {
    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'token',
      'redirect_uri': redirectUri,
      'scope': scopes,
    });

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl);
    } else {
      throw 'Could not launch $authUrl';
    }
  }
}
