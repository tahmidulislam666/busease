import 'package:flutter/material.dart';
import 'bus_search_screen.dart';
import 'bus_name_search_screen.dart';
import 'load_json_to_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await insertBusDataFromJson();  // Load JSON data into SQLite

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BusSearchScreen(), // Set the initial route to BusSearchScreen
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Ease'),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text('Search Buses by Route'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BusSearchScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Search Buses by Name'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BusNameSearchScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Welcome to Bus Ease'),
      ),
    );
  }
}