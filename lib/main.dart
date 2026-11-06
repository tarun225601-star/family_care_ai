import 'package:flutter/material.dart';
import 'dart:async';

// Global Configurations (Without generic angle brackets to prevent markdown issues)
Map globalEnterpriseCameras = {
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
  "Server Room": {
    "active": true,
    "ip": "rtsp://192.168.1.103:554/live",
    "status": "Secure",
    "resolution": "1080p FHD",
    "latency": "12ms",
  },
};

String globalCustomAIPrompt = "Detect intruders, smoke, children near stairs, and unauthorized delivery agents.";
String globalGeminiApiKey = "AIzaSy_Demo_Gemini_Vision_Key_998877";

// Global Logs containing evidence file paths saved in phone memory
List globalEnterpriseLogs = [
  {
    "time": "12:15 PM",
    "camera": "Main Entrance Gate",
    "event": "⚠️ Intruder Detected based on Gemini Prompt rules.",
    "videoPath": "/storage/emulated/0/Download/evidence_101.mp4",
    "level": "High"
  },
  {
    "time": "11:40 AM",
    "camera": "Living Room Hub",
    "event": "Motion recognized near secure perimeter.",
    "videoPath": "/storage/emulated/0/Download/evidence_102.mp4",
    "level": "Medium"
  }
];

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
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
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

  @override
  void initState() {
    super.initState();
    // फालतू ऑटोमैटिक टाइमर यहाँ से हमेशा के लिए हटा दिया गया है
  }

  @override
  void dispose() {
    super.dispose();
  }

  // असली इवेंट या मैन्युअल थ्रेट डिटेक्ट होने पर ही यह चलेगा
  void recordRealEvidence(String cameraName, String threatDescription) {
    String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    String localSavedPath = "/storage/emulated/0/DCIM/FamilyCare_Evidence_$timeStamp.mp4";

    setState(() {
      walletBalance -= 0.75;
      globalEnterpriseLogs.insert(0, {
        "time": "Just now",
        "camera": cameraName,
        "event": threatDescription,
        "videoPath": localSavedPath,
        "level": "High"
      });

      if (globalEnterpriseLogs.length > 20) {
        globalEnterpriseLogs.removeLast();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 Real Evidence Saved: $localSavedPath'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  

  void handleWalletTopUp() {
    setState(() {
      walletBalance += 500.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 ₹500 successfully added to Enterprise Wallet!'),
        backgroundColor: Color(0xFF1E1B4B),
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
            Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 26),
            SizedBox(width: 10),
            Text(
              'Command Center Dashboard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
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
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Bar & Recording Indicator
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRecordingEvidence
                      ? [const Color(0xFF881337), const Color(0xFF9F1239)]
                      : [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isRecordingEvidence ? 'REC • SAVING VIDEO TO STORAGE' : 'AI WALLET BALANCE',
                            style: TextStyle(
                              fontSize: 10,
                              color: isRecordingEvidence ? Colors.redAccent : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: const Color(0xFF1E1B4B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: handleWalletTopUp,
                    child: const Text('Top-Up ₹500', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Cameras Split Grid View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Camera Feeds (Multi-View)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${globalEnterpriseCameras.length} Active Nodes',
                  style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
                ),
              ],
            ),
            const SizedBox(height: 10),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 16 / 11,
              ),
              itemCount: globalEnterpriseCameras.length,
              itemBuilder: (context, index) {
                String camName = globalEnterpriseCameras.keys.elementAt(index);
                Map data = globalEnterpriseCameras[camName] as Map;
                bool isActive = data["active"] as bool;

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isRecordingEvidence
                          ? Colors.redAccent
                          : (isActive ? Colors.indigo.shade400 : Colors.red.shade400),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_rounded,
                              size: 32,
                              color: isRecordingEvidence
                                  ? Colors.redAccent
                                  : (isActive ? Colors.greenAccent : Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isRecordingEvidence ? "REC CLIP..." : (isActive ? "LIVE FEED" : "STANDBY"),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isRecordingEvidence
                                    ? Colors.redAccent
                                    : (isActive ? Colors.greenAccent : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            camName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Live Event Intelligence Logs & Evidence Videos Section
            const Text(
              'Real-Time Evidence Logs & Saved Video Clips',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: globalEnterpriseLogs.length,
              itemBuilder: (context, index) {
                Map log = globalEnterpriseLogs[index] as Map;
                String videoPath = log["videoPath"] != null ? log["videoPath"].toString() : "No Video";

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade900),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.videocam_sharp, color: Colors.amberAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log["event"].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Node: ${log["camera"]}  •  Time: ${log["time"]}',
                                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (log["videoPath"] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.folder_zip_rounded, color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Saved MP4: $videoPath',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: Colors.greenAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
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
  final TextEditingController _geminiKeyController = TextEditingController(text: globalGeminiApiKey);
  final TextEditingController _nodeIpController = TextEditingController();
  final TextEditingController _nodeNameController = TextEditingController();
  final TextEditingController _promptController = TextEditingController(text: globalCustomAIPrompt);
  bool _hideGeminiKey = true;

  void _saveSystemConfiguration() {
    String name = _nodeNameController.text.trim();
    String ip = _nodeIpController.text.trim();
    globalCustomAIPrompt = _promptController.text.trim();
    globalGeminiApiKey = _geminiKeyController.text.trim();

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
        content: Text('Settings & Prompts updated!'),
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
        title: const Text('System Configuration', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E1B4B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Google Gemini API Key:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _geminiKeyController,
            obscureText: _hideGeminiKey,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.key_rounded, color: Colors.amberAccent),
              suffixIcon: IconButton(
                icon: Icon(_hideGeminiKey ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white60),
                onPressed: () => setState(() => _hideGeminiKey = !_hideGeminiKey),
              ),
              filled: true,
              fillColor: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Custom AI Detection Prompt:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _promptController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text(
            'Add New RTSP Camera Node:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nodeNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'Camera Location (e.g. Backdoor)',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nodeIpController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'RTSP URL (rtsp://192.168.X.X:554/live)',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: const Color(0xFF1E1B4B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveSystemConfiguration,
              child: const Text('Save & Apply Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
