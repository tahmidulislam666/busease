import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'bus_details_screen.dart';
import 'bus_name_search_screen.dart';
import 'bus_fare_search_screen.dart'; // Import the new screen

class BusSearchScreen extends StatefulWidget {
  const BusSearchScreen({super.key});

  @override
  _BusSearchScreenState createState() => _BusSearchScreenState();
}

class _BusSearchScreenState extends State<BusSearchScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  List<String> _allStops = [];
  List<Map<String, dynamic>> _busResults = [];
  bool _isLoading = false;
  String _message = "";

  @override
  void initState() {
    super.initState();
    _loadAllStops();
  }

  Future<void> _loadAllStops() async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> routes = await db.query('bus_routes');

      Set<String> uniqueStops = {};
      for (var route in routes) {
        if (route['stops'] != null) {
          List<String> stops = route['stops'].split(',');
          uniqueStops.addAll(stops);
        }
      }

      setState(() {
        _allStops = uniqueStops.toList()..sort();
      });
    } catch (e) {
      print("❌ Error loading stops: $e");
    }
  }

  Future<void> searchBuses() async {
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      setState(() {
        _message = "⚠️ Please enter both start and end locations.";
        _busResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _busResults = [];
      _message = "";
    });

    try {
      DatabaseHelper dbHelper = DatabaseHelper();
      List<Map<String, dynamic>> results = await dbHelper.searchBusRoutes(
        _startController.text,
        _endController.text,
      );

      setState(() {
        _busResults = List<Map<String, dynamic>>.from(results);
        _isLoading = false;
        _message = results.isEmpty ? "🚫 No buses found for the selected route." : "";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "❌ Error searching for buses.";
      });
      print("❌ Error searching buses: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🚌 Bus Search"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Search Buses'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BusNameSearchScreen()), // Navigate to BusNameSearchScreen
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Bus Fare'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BusFareSearchScreen()), // Navigate to BusFareSearchScreen
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to the About screen
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAutoCompleteField("📍 Start Location", _startController),
            SizedBox(height: 10),
            _buildAutoCompleteField("🏁 End Location", _endController),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: searchBuses,
              icon: Icon(Icons.search),
              label: Text("Find Bus"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _message.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_message, style: TextStyle(color: Colors.red, fontSize: 16)),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _busResults.length,
                          itemBuilder: (context, index) {
                            var bus = _busResults[index];
                            List<String> stops = bus['stops'].split(',');

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: bus['image'] != null && bus['image'].isNotEmpty
                                    ? Image.network(bus['image'], width: 50, height: 50, fit: BoxFit.cover)
                                    : Icon(Icons.directions_bus, color: Colors.blue, size: 50),
                                title: Text(bus['bus_name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Text(stops.first, style: TextStyle(fontSize: 16)),
                                        SizedBox(width: 5),
                                        Icon(Icons.swap_horiz, size: 16),
                                        SizedBox(width: 5),
                                        Text(stops.last, style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BusDetailsScreen(bus: bus),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  /// 🔍 Creates an Autocomplete text field for location search
  Widget _buildAutoCompleteField(String label, TextEditingController controller) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _allStops.where((stop) => stop.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
        );
      },
    );
  }
}