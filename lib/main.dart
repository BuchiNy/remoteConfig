import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import "remoteconfig.dart";

final RemoteConfigService remoteConfigService = RemoteConfigService();

Future<void> main() async {
  // Ensure that Flutter is initialized before using Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the default options.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set the user property **This is the group id**
  await FirebaseAnalytics.instance.setUserProperty(
    name: 'group_b',
    value: 'group_b',
  );

  await Future.delayed(Duration(seconds: 2));

  // Initialize Remote Config service.
  await remoteConfigService.initialize();

  // Run the app after Firebase initialization is complete.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _sliderValue = 0.0;
  late String _question = '';
  late int _questionsVersion = 0;
  int _versionChangeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRemoteConfig();

    // Listen to version update count
    remoteConfigService.versionUpdateCounter.addListener(() {
      setState(() {
        _versionChangeCount = remoteConfigService.versionUpdateCounter.value;
        _questionsVersion = remoteConfigService.currentQuestionsVersion;
      });
    });
  }

  Future<void> _loadRemoteConfig() async {
    try {
      setState(() {
        _question = remoteConfigService.question;
        _questionsVersion = remoteConfigService.currentQuestionsVersion;
      });
    } catch (e) {
      debugPrint('Error loading remote config: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              width: MediaQuery.of(context).size.height * 0.4,
              child: Card(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      _question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      'Version: $_questionsVersion',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Version change count: $_versionChangeCount',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                      ),
                    ),
                    //
                    const SizedBox(height: 20),
                    Slider(
                      value: _sliderValue,
                      min: 0.0,
                      max: 10.0,
                      divisions: 10,
                      label: _sliderValue.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await remoteConfigService.initialize();
                        setState(() {
                          _question = remoteConfigService.question;
                        });
                      },
                      child: Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
