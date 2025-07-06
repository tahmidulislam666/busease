import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'bus_details_screen.dart';
import 'bus_search_screen.dart';
import 'bus_fare_search_screen.dart';
import 'details_bus.dart';

class BusNameSearchScreen extends StatefulWidget {
  const BusNameSearchScreen({super.key});

  @override
  _BusNameSearchScreenState createState() => _BusNameSearchScreenState();
}

class _BusNameSearchScreenState extends State<BusNameSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _allBuses = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  List<String> _allBusNames = [];
  String _message = "";

  @override
  void initState() {
    super.initState();
    _loadBusData();
  }

  Future<void> _loadBusData() async {
    setState(() {
      _isLoading = true;
      _message = "";
    });
    try {
      final String jsonString = await rootBundle.loadString('assets/dhaka-city-local-bus.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> buses = jsonData['data'] ?? [];
      _allBuses = buses.cast<Map<String, dynamic>>();
      _allBusNames = _allBuses.map((bus) => bus['english'].toString()).toList();
      setState(() {
        _results = List<Map<String, dynamic>>.from(_allBuses);
        _isLoading = false;
        _message = _results.isEmpty ? "🚫 No buses found." : "";
      });
    } catch (e) {
      print("❌ Error loading bus data: $e");
      setState(() {
        _isLoading = false;
        _message = "Failed to load bus data.";
      });
    }
  }

  void _searchBuses(String query) {
    setState(() {
      _isLoading = true;
      _message = "";
    });
    Future.delayed(Duration(milliseconds: 100), () {
      List<Map<String, dynamic>> results;
      if (query.isEmpty) {
        results = List<Map<String, dynamic>>.from(_allBuses);
      } else {
        results = _allBuses.where((bus) =>
          (bus['english'] ?? '').toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
      setState(() {
        _results = results;
        _isLoading = false;
        _message = results.isEmpty ? "🚫 No buses found for this name." : "";
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🚌 Search Buses by Name"),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusSearchScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Search Buses'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Bus Fare'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BusFareSearchScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to about screen
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final input = textEditingValue.text;
                if (input.isEmpty && _allBusNames.isNotEmpty) {
                  return _allBusNames;
                }
                return _allBusNames.where((busName) =>
                    busName.toLowerCase().contains(input.toLowerCase()));
              },
              onSelected: (String selection) {
                _controller.text = selection;
                _searchBuses(selection);
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Bus Name',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {},
                  onSubmitted: (value) => _searchBuses(value),
                );
              },
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                _searchBuses(_controller.text);
              },
              icon: Icon(Icons.search),
              label: Text('Find Bus'),
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
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            var bus = _results[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: bus['image'] != null &&
                                        bus['image'] is String &&
                                        bus['image'].isNotEmpty
                                    ? Image.network(
                                        bus['image'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(Icons.directions_bus, color: Colors.blue, size: 50),
                                title: Text(
                                  bus['english'] ?? '',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(bus['service_type'] ?? ''),
                                trailing: Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailsBus(bus: bus),
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
}
