import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HACKSTER',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool connected = false, playing = false;

  @override
  void initState() {
    setupSpotify();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        color: playing ? Theme.of(context).primaryColor : Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              if (connected && !playing)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: MobileScanner(
                    onDetect: onDetect,
                  ),
                ),
              const SizedBox(height: 32),
              if (!connected)
                ElevatedButton(
                  onPressed: setupSpotify,
                  child: const Text("Connect to Spotify"),
                ),
              if (connected && playing)
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.all(32)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                    ),
                  ),
                  onPressed: SpotifySdk.pause,
                  child: const Column(
                    children: [
                      Icon(
                        Icons.pause,
                        size: 64,
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  void onDetect(BarcodeCapture capture) {
    if (!playing) {
      try {
        SpotifySdk.play(
            spotifyUri: capture.barcodes[0].displayValue.toString());
      } catch (e) {
        log(e.toString());
      }
    }
    log(capture.barcodes[0].displayValue.toString());
  }

  void setupSpotify() async {
    bool success = await SpotifySdk.connectToSpotifyRemote(
        clientId: "07b123f034394b31a685bad127cc9a1d",
        redirectUrl: "de.freal.hackster://callback");
    setState(() {
      connected = success;
    });
    SpotifySdk.subscribeConnectionStatus().listen((event) {
      setState(() {
        connected = event.connected;
      });
      log(event.toString());
    });
    SpotifySdk.subscribePlayerState().listen((event) {
      setState(() {
        playing = !event.isPaused;
      });
      log("Paused: ${event.isPaused}");
    });
  }
}
