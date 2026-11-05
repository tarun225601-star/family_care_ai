import 'package:flutter/material.dart';
import 'dart:async';

// Global Configurations shared across screens
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
};

String globalCustomAIPrompt = "Detect intruders, smoke, children near stairs, and unauthorized delivery agents.";

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
      "event": "VIP Visitor identified based on custom prompt rules.",
      "level": "Low"
    },
    {
      "time": "11:40 AM",
      "camera": "Living Room Hub",
      "event": "Motion recognized near secure perimeter. Clip encrypted.",
      "level": "Medium"
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
            "camera": "Mobile Live Sensor",
            "event": "⚡ AI Prompt Rule Triggered: All scanned frames normal.",
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
            // Wallet Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
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
                        style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
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
                            isSystemArmed ? 'AI Guard Active' : 'System Disarmed',
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: handleWalletTopUp,
                    child: const Text('Top-Up ₹500', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // MOBILE LIVE CAMERA PREVIEW & AI DETECTION BUTTON
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF4F46E5),
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Live Mobile Camera & AI Scanner',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                ),
                subtitle: Text(
                  'Active Prompt: "$globalCustomAIPrompt"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MobileCamDetectionScreen()),
                    );
                  },
                  child: const Text('Open Cam'),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Connected Hardware Hubs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: globalEnterpriseCameras.length,
              itemBuilder: (context, index) {
                String camName = globalEnterpriseCameras.keys.elementAt(index);
                var data = globalEnterpriseCameras[camName]!;
                bool isActive = data["active"];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.videocam_rounded, color: isActive ? const Color(0xFF4F46E5) : Colors.grey),
                    title: Text(camName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('IP: ${data["ip"]} • Status: ${data["status"]}', style: const TextStyle(fontSize: 11)),
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
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: enterpriseLogs.length,
              itemBuilder: (context, index) {
                var log = enterpriseLogs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade50),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFF4F46E5), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log["event"]!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            Text('Time: ${log["time"]}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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

// =========================================================================
// MOBILE LIVE CAMERA DEMO & AI OBJECT DETECTION SCREEN
// =========================================================================
class MobileCamDetectionScreen extends StatefulWidget {
  const MobileCamDetectionScreen({super.key});

  @override
  State<MobileCamDetectionScreen> createState() => _MobileCamDetectionScreenState();
}

class _MobileCamDetectionScreenState extends State<MobileCamDetectionScreen> {
  bool isDetecting = true;
  String detectedObject = "Scanning frame for custom prompt...";

  @override
  void initState() {
    super.initState();
    // Simulate real-time object recognition based on user's custom prompt
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        detectedObject = "⚡ Object Recognized: Human Face & Motion Verified (Confidence: 98.4%)";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live Mobile AI Camera Stream', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_front_rounded, size: 80, color: Colors.white54),
                const SizedBox(height: 20),
                const Text(
                  '📱 Mobile Camera Active (Demo Stream)',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    'Active Prompt Filter: "$globalCustomAIPrompt"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.greenAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      detectedObject,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// SETTINGS SCREEN WITH PROMPT INPUT & MODEL SELECTION
// =========================================================================
class EnterpriseSettingsScreen extends StatefulWidget {
  const EnterpriseSettingsScreen({super.key});

  @override
  State<EnterpriseSettingsScreen> createState() => _EnterpriseSettingsScreenState();
}

class _EnterpriseSettingsScreenState extends State<EnterpriseSettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController(text: "sk_live_enterprise_998877665544");
  final TextEditingController _nodeIpController = TextEditingController();
  final TextEditingController _nodeNameController = TextEditingController();
  final TextEditingController _promptController = TextEditingController(text: globalCustomAIPrompt);
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
    globalCustomAIPrompt = _promptController.text.trim();

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
        content: Text('Enterprise Prompt & Node Configuration synchronized!'),
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
            'Custom AI Detection Prompt / Instructions:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'Enter what AI should look for (e.g., Detect smoke, intruder, pets)...',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
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
