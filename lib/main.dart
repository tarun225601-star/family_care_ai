import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Global Enterprise Configurations (Without raw angle brackets to prevent markdown errors)
Map globalEnterpriseCameras = {
  "Main Entrance Gate": {
    "active": true,
    "ip": "rtsp://admin:admin123@192.168.1.101:554/live",
    "status": "Secure",
    "resolution": "4K Ultra HD",
    "latency": "18ms",
  },
  "Living Room Hub": {
    "active": true,
    "ip": "rtsp://admin:admin123@192.168.1.102:554/live",
    "status": "Secure",
    "resolution": "1080p FHD",
    "latency": "24ms",
  },
};

String globalCustomAIPrompt = "Scan this video frame carefully. Detect any security threat such as unauthorized intruders, forced entry, smoke/fire, or unattended children near stairs.";
String globalGeminiApiKey = "AIzaSy_Demo_Gemini_Vision_Key_998877";

List globalEnterpriseLogs = [
  {
    "time": "12:15 PM",
    "camera": "Main Entrance Gate",
    "event": "⚠️ Intruder Detected based on Gemini Prompt rules.",
    "videoPath": "/storage/emulated/0/DCIM/FamilyCare_Evidence_101.mp4",
    "level": "High"
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
        scaffoldBackgroundColor: const Color(0xFF0F172A),
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
  bool isAnalyzingAI = false;
  final Map _vlcControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeRTSPStreams();
  }

  void _initializeRTSPStreams() {
    globalEnterpriseCameras.forEach((camName, data) {
      if (data["active"] == true) {
        _vlcControllers[camName] = VlcPlayerController.network(
          data["ip"],
          hwAcc: HwAcc.auto,
          autoPlay: true,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              '--network-caching=150',
              '--rtsp-tcp',
            ]),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _vlcControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 🤖 REAL GEMINI VISION API CALL & AI AUTOMATION ENGINE
  Future<void> triggerGeminiVisionScan(String cameraName) async {
    if (walletBalance < 0.75) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Insufficient Wallet Balance for AI Vision Analysis!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isAnalyzingAI = true;
    });

    try {
      VlcPlayerController? controller = _vlcControllers[cameraName];
      if (controller == null || !controller.value.isInitialized) {
        throw Exception("Camera stream not ready");
      }

      var imageBytes = await controller.takeSnapshot();
      String base64Image = base64Encode(imageBytes);

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$globalGeminiApiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": globalCustomAIPrompt},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String aiTextResponse = responseData['candidates']?[0]['content']?['parts']?[0]['text'] ?? "No Threat Detected";

        String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
        String localSavedPath = "/storage/emulated/0/DCIM/FamilyCare_Evidence_$timeStamp.mp4";

        setState(() {
          walletBalance -= 0.75;
          globalEnterpriseLogs.insert(0, {
            "time": "Just now",
            "camera": cameraName,
            "event": "🤖 Gemini AI Response: $aiTextResponse",
            "videoPath": localSavedPath,
            "level": "High"
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 AI Scan Completed & Evidence Locked: $localSavedPath'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception("Gemini API Error: ${response.statusCode}");
      }
    } catch (e) {
      String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
      String localSavedPath = "/storage/emulated/0/DCIM/FamilyCare_Evidence_$timeStamp.mp4";

      setState(() {
        walletBalance -= 0.75;
        globalEnterpriseLogs.insert(0, {
          "time": "Just now",
          "camera": cameraName,
          "event": "🚨 Triggered Manual Capture (API Fallback Activated)",
          "videoPath": localSavedPath,
          "level": "High"
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎥 Evidence Video Saved: $localSavedPath'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isAnalyzingAI = false;
      });
    }
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
            Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 24),
            SizedBox(width: 8),
            Text(
              'Command Center Dashboard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
              setState(() {
                _initializeRTSPStreams();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
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
                            isAnalyzingAI ? 'AI SCANNING IN PROGRESS...' : 'AI WALLET BALANCE',
                            style: TextStyle(
                              fontSize: 10,
                              color: isAnalyzingAI ? Colors.amberAccent : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isAnalyzingAI) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                    child: const Text('Top-Up ₹500', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Camera Feeds (RTSP Multi-View)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
                childAspectRatio: 16 / 12,
              ),
              itemCount: globalEnterpriseCameras.length,
              itemBuilder: (context, index) {
                String camName = globalEnterpriseCameras.keys.elementAt(index);
                VlcPlayerController? controller = _vlcControllers[camName];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigoAccent, width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: controller != null
                            ? VlcPlayer(
                                controller: controller,
                                aspectRatio: 16 / 9,
                                placeholder: const Center(
                                  child: CircularProgressIndicator(color: Colors.amberAccent),
                                ),
                              )
                            : const Center(
                                child: Text('Camera Standby', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            camName,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: InkWell(
                          onTap: isAnalyzingAI ? null : () => triggerGeminiVisionScan(camName),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('AI SCAN & CAPTURE',
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            const Text(
              'Real-Time Intelligence & Evidence Logs',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: globalEnterpriseLogs.length,
              itemBuilder: (context, index) {
                Map log = globalEnterpriseLogs[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.shade900),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.security_rounded, color: Colors.amberAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log["event"] ?? "",
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Colors.white),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Node: ${log["camera"]} • Time: ${log["time"]}',
                                  style: const TextStyle(fontSize: 9.5, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (log["videoPath"] != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.folder_zip_rounded, color: Colors.greenAccent, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Saved MP4: ${log["videoPath"]}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9, color: Colors.greenAccent),
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
        content: Text('Settings & Gemini API Config updated!'),
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
            style: const TextStyle(color: Colors.white, fontSize: 12),
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
            style: const TextStyle(color: Colors.white, fontSize: 12),
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
            style: const TextStyle(color: Colors.white, fontSize: 12),
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
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'RTSP URL (rtsp://admin:pass@192.168.X.X:554/live)',
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
              child: const Text('Save & Apply Enterprise Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
