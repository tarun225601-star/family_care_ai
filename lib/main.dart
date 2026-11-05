import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FamilyCareAIApp());
}

class FamilyCareAIApp extends StatelessWidget {
  const FamilyCareAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Care Vision AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double walletBalance = 150.0;
  bool isSystemArmed = true;
  Timer? _aiEngineSimulationTimer;

  final Map<String, dynamic> homeCameras = {
    "Living Room": {
      "active": true, 
      "ip": "rtsp://192.168.1.50:554/stream1", 
      "status": "Secure",
      "resolution": "1080p",
    },
    "Balcony": {
      "active": false, 
      "ip": "rtsp://192.168.1.51:554/stream1", 
      "status": "Paused",
      "resolution": "720p",
    },
    "Main Gate": {
      "active": true, 
      "ip": "rtsp://192.168.1.52:554/stream1", 
      "status": "Secure",
      "resolution": "1080p",
    },
    "Kids Room": {
      "active": true, 
      "ip": "rtsp://192.168.1.53:554/stream1", 
      "status": "Secure",
      "resolution": "2K Ultra",
    }
  };

  // यहाँ एंगल ब्रैकेट्स हटा दिए हैं ताकि मार्कडाउन की समस्या दोबारा न आए
  var aiAlertsLog = [
    {
      "time": "11:20 AM", 
      "camera": "Living Room", 
      "event": "⚡ Child movement detected near stairs (10s clip generated)",
    },
    {
      "time": "10:05 AM", 
      "camera": "Main Gate", 
      "event": "📦 Delivery courier verified at doorstep",
    }
  ];

  @override
  void initState() {
    super.initState();
    _startAIEngineBackgroundLoop();
  }

  @override
  void dispose() {
    _aiEngineSimulationTimer?.cancel();
    super.dispose();
  }

  void _startAIEngineBackgroundLoop() {
    _aiEngineSimulationTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (!mounted || !isSystemArmed) return;
      
      bool hasActiveCameras = homeCameras.values.any((cam) => cam["active"] == true);
      if (hasActiveCameras && walletBalance > 2.0) {
        setState(() {
          walletBalance -= 0.50;
          aiAlertsLog.insert(0, {
            "time": "Just now",
            "camera": "Living Room",
            "event": "🚨 Smart Vision AI: Activity recognized. Secure clip saved.",
          });
          if (aiAlertsLog.length > 10) {
            aiAlertsLog.removeLast();
          }
        });
      }
    });
  }

  void toggleCameraAI(String cameraName, bool currentStatus) {
    setState(() {
      homeCameras[cameraName]["active"] = !currentStatus;
      homeCameras[cameraName]["status"] = !currentStatus ? "Secure" : "Paused";
    });
  }

  void topUpWallet() {
    setState(() {
      walletBalance += 100.0;
    });
  }

  void toggleMasterSystem() {
    setState(() {
      isSystemArmed = !isSystemArmed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.remove_red_eye, color: Colors.white),
            SizedBox(width: 8),
            Text('Family Care AI SaaS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(isSystemArmed ? Icons.shield : Icons.shield_outlined, color: Colors.white),
            onPressed: toggleMasterSystem,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Prepaid Wallet (Pay-As-You-Go)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('₹${walletBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        const SizedBox(height: 2),
                        Text(isSystemArmed ? "🟢 AI Engine: Active" : "🔴 AI Engine: Disarmed", style: TextStyle(fontSize: 11, color: isSystemArmed ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: topUpWallet,
                      icon: const Icon(Icons.account_balance_wallet, size: 18),
                      label: const Text('Top-Up ₹100', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Connected Home Hub Cameras', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('${homeCameras.length} Devices Linked', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: ListView(
                children: homeCameras.entries.map((entry) {
                  String camName = entry.key;
                  bool isActive = entry.value["active"];
                  String ipAddress = entry.value["ip"];
                  String resolution = entry.value["resolution"];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isActive ? Colors.deepOrange.shade100 : Colors.grey.shade200,
                        child: Icon(Icons.videocam, color: isActive ? Colors.deepOrange : Colors.grey),
                      ),
                      title: Text(camName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('IP: $ipAddress ($resolution)\nStatus: ${isActive ? "AI Guard Active" : "Paused"}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      isThreeLine: true,
                      trailing: Switch(
                        value: isActive,
                        activeColor: Colors.deepOrange,
                        onChanged: (val) => toggleCameraAI(camName, isActive),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Live AI Event & Alert Feed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: aiAlertsLog.length,
                itemBuilder: (context, index) {
                  var alert = aiAlertsLog[index];
                  return Card(
                    color: Colors.orange.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.bolt, color: Colors.deepOrange),
                      title: Text(alert["event"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      subtitle: Text("Camera: ${alert['camera']} | Time: ${alert['time']}", style: const TextStyle(fontSize: 10, color: Colors.black54)),
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController(text: "sk-proj-visionai-live-key-9988");
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  bool _obscureKey = true;

  void saveConfigurations() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings & API Keys', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Text('Plug-and-Play Vision AI API Key:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key, color: Colors.deepOrange),
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
