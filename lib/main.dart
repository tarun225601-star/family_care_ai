import 'package:flutter/material.dart';
import 'dart:async';

// Global Cameras Map so both Dashboard and Settings can access it without any scope error
Map<String, Map<String, dynamic>> globalEnterpriseCameras = {
  "Main Entrance Gate": {
    "active": true,
    "ip": "rtsp://192.168.1.101:554/live",
    "status": "Secure",
    "resolution": "4K Ultra HD",
    "latency": "18ms",
  },
  "Living Room Hub": {
    "active": true,
    "ip": "rtsp://192.168.1.102:554/live",
    "status": "Secure",
    "resolution": "1080p FHD",
    "latency": "24ms",
  },
  "Backyard Perimeter": {
    "active": false,
    "ip": "rtsp://192.168.1.103:554/live",
    "status": "Standby",
    "resolution": "1080p FHD",
    "latency": "--",
  },
  "Kids Play Zone": {
    "active": true,
    "ip": "rtsp://192.168.1.104:554/live",
    "status": "Secure",
    "resolution": "2K Quad HD",
    "latency": "21ms",
  }
};

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FamilyCareVIPApp());
}

class FamilyCareVIPApp extends StatelessWidget {
  const FamilyCareVIPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Care Vision AI Enterprise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E1B4B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const EnterpriseDashboardScreen(),
    );
  }
}

class EnterpriseDashboardScreen extends StatefulWidget {
  const EnterpriseDashboardScreen({super.key});

  @override
  State<EnterpriseDashboardScreen> createState() => _EnterpriseDashboardScreenState();
}

class _EnterpriseDashboardScreenState extends State<EnterpriseDashboardScreen> {
  double walletBalance = 2450.00;
  bool isSystemArmed = true;
  Timer? _aiSimulationTimer;
  String activeModelChoice = "YOLOv8 Edge Model (Local/Fast)";

  var enterpriseLogs = [
    {
      "time": "12:15 PM",
      "camera": "Main Entrance Gate",
      "event": "VIP Visitor identified: Authorized personnel scanned.",
      "level": "Low"
    },
    {
      "time": "11:40 AM",
      "camera": "Living Room Hub",
      "event": "Motion recognized near secure perimeter. Clip encrypted.",
      "level": "Medium"
    },
    {
      "time": "10:05 AM",
      "camera": "Kids Play Zone",
      "event": "Routine activity normal. Zero anomalies found.",
      "level": "Normal"
    }
  ];

  @override
  void initState() {
    super.initState();
    _initAutonomousEngine();
  }

  @override
  void dispose() {
    _aiSimulationTimer?.cancel();
    super.dispose();
  }

  void _initAutonomousEngine() {
    _aiSimulationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted || !isSystemArmed) return;

      bool activeCheck = globalEnterpriseCameras.values.any((c) => c["active"] == true);
      if (activeCheck && walletBalance > 5.0) {
        setState(() {
          walletBalance -= 0.75;
          enterpriseLogs.insert(0, {
            "time": "Just now",
            "camera": "Main Entrance Gate",
            "event": "⚡ AI Engine: Vision processed via $activeModelChoice. Secure.",
            "level": "Normal"
          });
          if (enterpriseLogs.length > 15) {
            enterpriseLogs.removeLast();
          }
        });
      }
    });
  }

  void toggleCameraState(String camKey) {
    setState(() {
      bool current = globalEnterpriseCameras[camKey]!["active"];
      globalEnterpriseCameras[camKey]!["active"] = !current;
      globalEnterpriseCameras[camKey]!["status"] = !current ? "Secure" : "Standby";
    });
  }

  void handleWalletTopUp() {
    setState(() {
      walletBalance += 500.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 ₹500 successfully added to Enterprise Wallet!'),
        backgroundColor: Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 28),
            SizedBox(width: 10),
            Text(
              'Family Care Enterprise',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSystemArmed ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: isSystemArmed ? Colors.greenAccent : Colors.redAccent,
            ),
            onPressed: () {
              setState(() {
                isSystemArmed = !isSystemArmed;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EnterpriseSettingsScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              padding: const EdgeInsets.all(22.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ENTERPRISE WALLET BALANCE',
                        style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSystemArmed ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSystemArmed ? 'AI Guard Active ($activeModelChoice)' : 'System Disarmed',
                            style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: const Color(0xFF1E1B4B),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: handleWalletTopUp,
                    child: const Text('Top-Up ₹500', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Connected Hardware Hubs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  '${globalEnterpriseCameras.length} Nodes Active',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: globalEnterpriseCameras.length,
              itemBuilder: (context, index) {
                String camName = globalEnterpriseCameras.keys.elementAt(index);
                var data = globalEnterpriseCameras[camName]!;
                bool isActive = data["active"];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFEEF2FF) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.videocam_rounded,
                        color: isActive ? const Color(0xFF4F46E5) : Colors.grey,
                      ),
                    ),
                    title: Text(
                      camName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'IP: ${data["ip"]} • ${data["resolution"]}\nLatency: ${data["latency"]} | Status: ${data["status"]}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Switch.adaptive(
                      value: isActive,
                      activeColor: const Color(0xFF4F46E5),
                      onChanged: (val) => toggleCameraState(camName),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Live Enterprise Event Intelligence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: enterpriseLogs.length,
              itemBuilder: (context, index) {
                var log = enterpriseLogs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.indigo.shade50, width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFF4F46E5), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log["event"]!,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Node: ${log["camera"]}  •  Time: ${log["time"]}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EnterpriseSettingsScreen extends StatefulWidget {
  const EnterpriseSettingsScreen({super.key});

  @override
  State<EnterpriseSettingsScreen> createState() => _EnterpriseSettingsScreenState();
}

class _EnterpriseSettingsScreenState extends State<EnterpriseSettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController(text: "sk_live_enterprise_998877665544");
  final TextEditingController _nodeIpController = TextEditingController();
  final TextEditingController _nodeNameController = TextEditingController();
  bool _hideApiKey = true;

  static String selectedAIModel = "YOLOv8 Edge Model (Local/Fast)";
  final List<String> availableAIModels = [
    "YOLOv8 Edge Model (Local/Fast)",
    "Custom Cloud Vision LLM (High Accuracy)",
    "Hybrid Neural Mesh (Edge + Cloud Sync)"
  ];

  void _saveSystemConfiguration() {
    String name = _nodeNameController.text.trim();
    String ip = _nodeIpController.text.trim();

    if (name.isNotEmpty && ip.isNotEmpty) {
      globalEnterpriseCameras[name] = {
        "active": true,
        "ip": ip,
        "status": "Secure",
        "resolution": "1080p FHD",
        "latency": "15ms",
      };
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enterprise Configuration synchronized successfully!'),
        backgroundColor: Color(0xFF1E1B4B),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Configuration', style: TextStyle(color: Colors.white, fontSize: 17)),
        backgroundColor: const Color(0xFF1E1B4B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            'Global Vision AI API Authorization Key:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _hideApiKey,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF4F46E5)),
              suffixIcon: IconButton(
                icon: Icon(_hideApiKey ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _hideApiKey = !_hideApiKey),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select Active Neural Inference Engine:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedAIModel,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.memory_rounded, color: Color(0xFF4F46E5)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: availableAIModels.map((String model) {
              return DropdownMenuItem<String>(
                value: model,
                child: Text(model, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              );
            }).toList(),
            onChanged: (String? val) {
              if (val != null) {
                setState(() {
                  selectedAIModel = val;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          const Divider(thickness: 1.5),
          const SizedBox(height: 16),
          const Text(
            'Provision New RTSP Hardware Node:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nodeNameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'Node Location (e.g. Server Room)',
              prefixIcon: const Icon(Icons.label_rounded, color: Color(0xFF4F46E5)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nodeIpController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'RTSP Address (rtsp://192.168.X.X:554/live)',
              prefixIcon: const Icon(Icons.router_rounded, color: Color(0xFF4F46E5)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1B4B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: _saveSystemConfiguration,
              child: const Text(
                'Save & Deploy Node Configuration',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
