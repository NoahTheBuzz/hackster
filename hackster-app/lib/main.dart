import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'package:spotify_sdk/models/track.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemStatusBarContrastEnforced: true,
        systemNavigationBarColor: Colors.black.withOpacity(0.002),
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top]);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: 'HACKSTER',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
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
  bool connected = false, playing = false, initial = true;
  Track? track;
  Uint8List? image;

  @override
  void initState() {
    setupSpotify();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        color: Theme.of(context).primaryColor.withOpacity(playing ? 1 : 0.2),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              if (!playing && track != null && !initial)
                Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (image != null)
                        Image.memory(
                          image!,
                          height: 80,
                          width: 80,
                        ),
                      SizedBox(
                        width: image != null ? 24 : 0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Last track:",
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width -
                                  (image != null ? 160 : 40),
                            ),
                            child: Text(
                              track!.name,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Colors.cyan,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            track!.artists[0].name!,
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Connect to Spotify"),
                  ),
                ),
              if (connected && playing)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // SizedBox(
                    //   height: 150,
                    //   width: 150,
                    //   child: StreamBuilder<PlayerState>(
                    //       stream: SpotifySdk.subscribePlayerState(),
                    //       builder: (context, snapshot) {
                    //         Track? track = snapshot.data?.track;
                    //         double? progress;
                    //         try {
                    //           progress = snapshot.data!.playbackPosition /
                    //               track!.duration;
                    //         } catch (e) {
                    //           progress = null;
                    //         }
                    //         return CircularProgressIndicator(
                    //           value: progress,
                    //           strokeWidth: 10,
                    //           color: Colors.white,
                    //           backgroundColor: Colors.white.withOpacity(0.2),
                    //         );
                    //       }),
                    // ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.black),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.all(32)),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
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
                            color: Colors.white,
                            size: 64,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  void onDetect(BarcodeCapture capture) {
    if (!playing) {
      HapticFeedback.heavyImpact();
      try {
        SpotifySdk.play(
            spotifyUri: capture.barcodes[0].displayValue.toString());
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            initial = false;
          });
        });
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
      if (track?.imageUri != null && track?.imageUri != event.track?.imageUri) {
        updateImage(track!.imageUri);
      }
      Wakelock.toggle(enable: !event.isPaused);
      setState(() {
        playing = !event.isPaused;
        track = event.track;
      });
      log("Paused: ${event.isPaused}");
      log("Track: ${event.track?.name}");
    });
  }

  updateImage(ImageUri uri) async {
    Uint8List? albumArt = await SpotifySdk.getImage(
      imageUri: uri,
      dimension: ImageDimension.thumbnail,
    );
    setState(() {
      image = albumArt;
    });
  }
}
