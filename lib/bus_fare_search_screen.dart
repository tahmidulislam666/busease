import 'dart:convert';
import 'bus_search_screen.dart';
import 'bus_name_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BusFareSearchScreen extends StatefulWidget {
  const BusFareSearchScreen({super.key});

  @override
  _BusFareSearchScreenState createState() => _BusFareSearchScreenState();
}

class _BusFareSearchScreenState extends State<BusFareSearchScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  List<String> _allFromStops = [];
  Map<String, Set<String>> _fromToMap = {};
  String _message = "";
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadAllStops();
  }

  Future<void> _loadAllStops() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/kotovara_full_data.json');
      final List<dynamic> data = json.decode(jsonString);

      Set<String> uniqueFrom = {};
      Map<String, Set<String>> fromToMap = {};

      for (var route in data) {
        final from = route['From'];
        final to = route['To'];
        if (from != null) {
          uniqueFrom.add(from);
          fromToMap.putIfAbsent(from, () => <String>{});
          if (to != null) {
            fromToMap[from]!.add(to);
          }
        }
      }

      setState(() {
        _allFromStops = uniqueFrom.toList()..sort();
        _fromToMap = fromToMap;
      });
    } catch (e) {
      print("❌ Error loading stops: $e");
    }
  }

  Future<void> _searchFare() async {
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      setState(() {
        _message = "⚠️ Please enter both start and end locations.";
        _searchResults = [];
      });
      return;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/kotovara_full_data.json');
      final List<dynamic> data = json.decode(jsonString);

      final results = data.where((entry) {
        return entry['From'] == _startController.text &&
            entry['To'] == _endController.text;
      }).toList();

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(results);
        _message = results.isEmpty ? "🚫 No fare information found for the selected route." : "";
      });
    } catch (e) {
      setState(() {
        _message = "❌ Error loading fare data.";
        _searchResults = [];
      });
      print("❌ Error: $e");
    }
  }

  Future<void> _showLocationDialog({
    required String title,
    required List<String> options,
    required TextEditingController controller,
    required VoidCallback? onSelected,
  }) async {
    String searchText = '';
    List<String> filteredOptions = List.from(options);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Select or Search Location",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey[900]),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.search, size: 28),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchText = value;
                                filteredOptions = options
                                    .where((stop) => stop.toLowerCase().contains(searchText.toLowerCase()))
                                    .toList();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredOptions.length,
                        separatorBuilder: (_, __) => Divider(height: 1),
                        itemBuilder: (context, index) {
                          final stop = filteredOptions[index];
                          return ListTile(
                            title: Text(stop),
                            onTap: () {
                              controller.text = stop;
                              Navigator.of(context).pop();
                              if (onSelected != null) onSelected();
                            },
                          );
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Close"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPopupLocationField({
    required String label,
    required TextEditingController controller,
    required List<String> options,
    required VoidCallback? onTap,
    required VoidCallback? onSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        if (onTap != null) onTap();
        if (label.contains("End") && _startController.text.isEmpty) {
          setState(() {
            _message = "⚠️ Please select your start location first.";
          });
          return;
        }
        await _showLocationDialog(
          title: label,
          options: options,
          controller: controller,
          onSelected: onSelected,
        );
        if (label.contains("Start")) {
          // Clear end location if start changes
          _endController.clear();
          setState(() {});
        } else {
          setState(() {});
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // For end location, show only To stops for selected From
    List<String> endOptions = [];
    if (_fromToMap.containsKey(_startController.text)) {
      endOptions = _fromToMap[_startController.text]!.toList()..sort();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Bus Fare Search"),
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BusSearchScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Search Buses'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BusNameSearchScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Bus Fare'),
              onTap: () {
                Navigator.pushReplacement(
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
                // Navigate to the About screen if needed
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPopupLocationField(
              label: "📍 Start Location",
              controller: _startController,
              options: _allFromStops,
              onTap: null,
              onSelected: () {
                // Clear end location if start changes
                _endController.clear();
                setState(() {});
              },
            ),
            SizedBox(height: 10),
            _buildPopupLocationField(
              label: "🏁 End Location",
              controller: _endController,
              options: endOptions,
              onTap: () {
                if (_startController.text.isEmpty) {
                  setState(() {
                    _message = "⚠️ Please select your start location first.";
                  });
                }
              },
              onSelected: () {
                setState(() {});
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _searchFare,
              icon: Icon(Icons.search),
              label: Text("Search Fare"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            _message.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_message, style: TextStyle(color: Colors.red, fontSize: 16)),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              "${result['From']} ➡️ ${result['To']}",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Route: ${result['Route']}\nFare: ${result['Fare']}, Distance: ${result['Distance']}",
                            ),
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
