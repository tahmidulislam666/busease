import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'bus_details_screen.dart';
import 'bus_search_screen.dart'; // Ensure this import is added

class BusNameSearchScreen extends StatefulWidget {
  const BusNameSearchScreen({super.key});

  @override
  _BusNameSearchScreenState createState() => _BusNameSearchScreenState();
}

class _BusNameSearchScreenState extends State<BusNameSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  List<String> _allBusNames = [];

  @override
  void initState() {
    super.initState();
    _loadAllBusNames();
    _loadAllBuses(); // Load all buses on init
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAllBusNames() async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> buses = await db.query('buses');

      setState(() {
        _allBusNames = buses.map((bus) => bus['bus_name'].toString()).toList();
      });
    } catch (e) {
      print("❌ Error loading bus names: $e");
    }
  }

  Future<void> _loadAllBuses() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> buses = await db.query('buses');
      setState(() {
        _results = buses;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading buses: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchBuses(String query) async {
    setState(() {
      _isLoading = true;
    });
    if (query.isEmpty) {
      _loadAllBuses();
    } else {
      final results = await DatabaseHelper().searchBusesByName(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Buses by Name'),
        backgroundColor: Colors.blueAccent,
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
                'BusEase',
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
                // Navigate to search buses screen
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _allBusNames.where((busName) =>
                          busName.toLowerCase().contains(textEditingValue.text.toLowerCase()));
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
                          labelText: 'Search by bus name',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20),
                        ),
                        onSubmitted: (value) => _searchBuses(value),
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _searchBuses(_controller.text);
                  },
                  child: Text('Find Bus'),
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            var bus = _results[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: bus['image'] != null && bus['image'].isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(bus['image'], width: 50, height: 50, fit: BoxFit.cover),
                                      )
                                    : Icon(Icons.directions_bus, color: Colors.blue, size: 50),
                                title: Text(bus['bus_name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                subtitle: Text(bus['service_type']),
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
        ],
      ),
    );
  }
}
