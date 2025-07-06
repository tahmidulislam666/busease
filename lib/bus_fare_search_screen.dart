import 'dart:convert';
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

  Widget _buildAutoCompleteField({
    required String label,
    required TextEditingController controller,
    required List<String> options,
    required VoidCallback? onTap,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return options;
        }
        return options.where((stop) => stop.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        controller.text = selection;
        if (label.contains("Start")) {
          // Clear end location if start changes
          _endController.clear();
          setState(() {});
        }
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
          readOnly: false,
          onTap: onTap,
        );
      },
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAutoCompleteField(
              label: "📍 Start Location",
              controller: _startController,
              options: _allFromStops,
              onTap: () {
                // No-op, but required for interface
              },
            ),
            SizedBox(height: 10),
            _buildAutoCompleteField(
              label: "🏁 End Location",
              controller: _endController,
              options: endOptions,
              onTap: () {
                if (_startController.text.isEmpty) {
                  setState(() {
                    _message = "⚠️ Please select your start location first.";
                  });
                  FocusScope.of(context).requestFocus(FocusNode()); // Remove focus
                }
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
