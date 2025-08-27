import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SensorPage(),
    );
  }
}

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});
  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  late IO.Socket socket;
  double temperature = 0.0;
  double humidity = 0.0;
  int gas = 0;

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  void initSocket() {
    socket = IO.io(
      'http://YOUR_SERVER_IP:3000', // Ganti dengan IP backend Anda
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    socket.onConnect((_) {
      print('[Flutter] Connected to backend');
    });

    socket.on('sensor_data', (data) {
      final decoded = json.decode(data);
      setState(() {
        temperature = decoded['temperature'] ?? 0.0;
        humidity = decoded['humidity'] ?? 0.0;
        gas = decoded['gas'] ?? 0;
      });
    });

    socket.onDisconnect((_) => print('[Flutter] Disconnected from backend'));
  }

  void sendControl(String action) {
    socket.emit('control_command', {'action': action});
    print('[Flutter] Sent control: $action');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("IoT Sensor Monitor"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Column(
          children: [
            buildSensorCard("Temperature", "$temperature °C", Colors.orange),
            const SizedBox(height: 20),
            buildSensorCard("Humidity", "$humidity %", Colors.blue),
            const SizedBox(height: 20),
            buildSensorCard(
              "Gas Level",
              "$gas",
              gas > 700 ? Colors.red : Colors.green,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildControlButton(
                  "Start",
                  Colors.green,
                  () => sendControl("start"),
                ),
                buildControlButton(
                  "Stop",
                  Colors.red,
                  () => sendControl("stop"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSensorCard(String label, String value, Color color) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildControlButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 20)),
    );
  }
}
