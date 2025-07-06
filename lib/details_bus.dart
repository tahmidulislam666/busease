import 'package:flutter/material.dart';

class DetailsBus extends StatelessWidget {
  final Map<String, dynamic> bus;

  const DetailsBus({Key? key, required this.bus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use stops if available, else fallback to routes
    List<String> stops = [];
    if (bus['stops'] != null && bus['stops'] is String) {
      stops = List<String>.from((bus['stops'] as String).split(',').map((s) => s.trim()));
    } else if (bus['routes'] != null && bus['routes'] is List) {
      stops = List<String>.from(bus['routes'].map((s) => s.toString()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(bus['bus_name'] ?? bus['english'] ?? 'Bus Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: bus['image'] != null && (bus['image'] as String).isNotEmpty
                  ? Image.network(bus['image'], height: 150, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 150, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            Text(
              "🚌 Bus Name:  ${bus['bus_name'] ?? bus['english'] ?? ''}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Service Type: ${bus['service_type'] ?? 'N/A'}",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 15),
            const Text(
              "📍 Stops:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: stops.isEmpty
                  ? const Center(child: Text("No stops available"))
                  : ListView.builder(
                      itemCount: stops.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.directions_bus, color: Colors.blue),
                          title: Text(stops[index]),
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
