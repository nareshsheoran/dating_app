import 'package:flame_finder/google_ads_provider.dart';
import 'package:flame_finder/match_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'main_page.dart';
import 'player_setup_page.dart';
import 'data_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<Player?> _loadPlayer() async {
    try {
      return await Player.fromLocalStorage();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MatchProvider>(create: (_) => MatchProvider()),
        ChangeNotifierProvider<GoogleAdsProvider>(create: (_) => GoogleAdsProvider()),
      ],
      child: MaterialApp(
        title: 'Flame Finder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: FutureBuilder<Player?>(
          future: _loadPlayer(),
          builder: (BuildContext context, AsyncSnapshot<Player?> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              print("snapshot.data:::${snapshot.data}");
              if (snapshot.hasData) {
                return MainPage(player: snapshot.data!);
              } else {
                return PlayerSetupPage();
              }
            } else {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
    );
  }
}
