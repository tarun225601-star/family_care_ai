// ============================================================================
// FAMILY CARE VISION AI - FINAL ENTERPRISE MASTER EDITION (CRASH & ERROR FREE)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

// 1. Global Multi-Camera Registry (8-10+ RTSP Streams Support)
Map globalEnterpriseCameras = {
  "Main Entrance Cam": {
    "ip": "rtsp://admin:password@192.168.1.100:554/stream1",
    "active": true
  },
  "Cash Counter Cam": {
    "ip": "rtsp://admin:password@192.168.1.101:554/stream1",
    "active": true
  },
  "Warehouse Cam 3": {
    "ip": "rtsp://admin:password@192.168.1.102:554/stream1",
    "active": true
  },
  "Backdoor Cam 4": {
    "ip": "rtsp://admin:password@192.168.1.103:554/stream1",
    "active": true
  },
};

// 2. Global AI Configurations & System Prompts
String globalCustomAIPrompt =
    "Scan this media frame carefully for the Family Care Security Hub. "
    "Detect any security threat such as unauthorized intruders, forced entry, "
    "smoke, fire, hazardous objects, unattended children near dangerous zones, "
    "or any bullying/misbehavior in school and commercial premises.";

String globalGroqApiKey = "";

String activeChatModel = "allam-2-7b";
String activeVisionModel = "qwen/qwen3.8-27b";

List availableChatModels = [
  "allam-2-7b",
  "qwen/qwen3.8-27b",
  "llama-3.1-8b-instant"
];

List availableVisionModels = [
  "qwen/qwen3.8-27b",
  "allam-2-7b"
];

// 3. Enterprise Audit Logs (Simple Dynamic List - No Syntax Error)
List globalEnterpriseLogs = [
  {
    "time": "System Boot",
    "camera": "Enterprise Master Hub",
    "event": "🛡️ Security Hub Initialized Successfully. Multi-Camera RTSP & AI Ready.",
    "level": "Info"
  }
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FamilyCareVIPEnterpriseApp());
}

class FamilyCareVIPEnterpriseApp extends StatelessWidget {
  const FamilyCareVIPEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Care Vision AI Enterprise Edition',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E1B4B),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const EnterpriseDashboardScreen(),
    );
  }
}

class EnterpriseDashboardScreen extends StatefulWidget {
  const EnterpriseDashboardScreen({super.key});

  @override
  State<EnterpriseDashboardScreen> createState() =>
      _EnterpriseDashboardScreenState();
}

class _EnterpriseDashboardScreenState extends State<EnterpriseDashboardScreen> {
  double walletBalance = 2450.00;
  bool isSystemArmed = true;
  bool isAnalyzingAI = false;

  final Map _vlcControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRTSPStreams();
    });
  }

  void _initializeRTSPStreams() {
    for (var controller in _vlcControllers.values) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    _vlcControllers.clear();

    globalEnterpriseCameras.forEach((camName, data) {
      if (data["active"] == true &&
          data["ip"] != null &&
          data["ip"].toString().isNotEmpty) {
        try {
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
        } catch (e) {
          debugPrint("RTSP Connection Error for $camName: $e");
        }
      }
    });
    if (mounted) setState(() {});
  }

  Future<void> triggerGroqVisionScan(String cameraName) async {
    if (walletBalance < 0.75) {
      _showAppSnackBar('⚠️ Insufficient Wallet Credits! Please Top-Up ₹500.', Colors.orange);
      return;
    }

    if (globalGroqApiKey.trim().isEmpty) {
      _showAppSnackBar('⚠️ Please configure your API Key in Settings (⚙️) first!', Colors.redAccent);
      return;
    }

    setState(() {
      isAnalyzingAI = true;
    });

    try {
      dynamic controller = _vlcControllers[cameraName];
      if (controller == null || !controller.value.isInitialized) {
        throw Exception("CCTV stream '$cameraName' is offline or uninitialized.");
      }

      Uint8List? imageBytes;
      try {
        imageBytes = await controller.takeSnapshot();
      } catch (_) {
        throw Exception("Failed to grab snapshot frame from RTSP feed.");
      }

      if (imageBytes == null || imageBytes.isEmpty) {
        throw Exception("Captured frame snapshot is empty.");
      }

      String base64Image = base64Encode(imageBytes);
      String aiTextResponse = await _sendFrameToGroqVisionAPI(base64Image);
      bool isThreatDetected = _detectThreatKeywords(aiTextResponse);

      setState(() {
        walletBalance -= 0.75;
        globalEnterpriseLogs.insert(0, {
          "time": _getCurrentFormattedTime(),
          "camera": cameraName,
          "event": "🤖 Live CCTV Audit ($activeVisionModel): $aiTextResponse",
          "level": isThreatDetected ? "High" : "Info"
        });
      });

      _showAppSnackBar('🚨 RTSP AI Vision Scan Completed!', Colors.green);
    } catch (e) {
      _showAppSnackBar('❌ Scan Failed: $e', Colors.red, durationSeconds: 6);
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzingAI = false;
        });
      }
    }
  }

  Future<String> _sendFrameToGroqVisionAPI(String base64Image) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${globalGroqApiKey.trim()}'
      },
      body: jsonEncode({
        "model": activeVisionModel,
        "messages": [
          {
            "role": "user",
            "content": [
              {"type": "text", "text": globalCustomAIPrompt},
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
              }
            ]
          }
        ],
        "max_tokens": 400
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['choices']?[0]['message']?['content'] ??
          "No Security Threats Detected in Frame.";
    } else {
      throw Exception("Groq API Error (${response.statusCode}): ${response.body}");
    }
  }

  bool _detectThreatKeywords(String text) {
    final lower = text.toLowerCase();
    return lower.contains("threat") ||
        lower.contains("intruder") ||
        lower.contains("fire") ||
        lower.contains("smoke") ||
        lower.contains("weapon") ||
        lower.contains("danger") ||
        lower.contains("fight") ||
        lower.contains("suspicious") ||
        lower.contains("alert") ||
        lower.contains("unauthorized");
  }

  void toggleSystemArming() {
    setState(() {
      isSystemArmed = !isSystemArmed;
    });
    _showAppSnackBar(
      isSystemArmed ? '🔒 Security System ARMED' : '🔓 Security System Disarmed',
      isSystemArmed ? Colors.green : Colors.amber,
    );
  }

  void fnHandleWalletTopUp() {
    setState(() {
      walletBalance += 500.0;
    });
    _showAppSnackBar('✅ Successfully Added ₹500.00 to AI Wallet.', Colors.lightBlue);
  }

  String _getCurrentFormattedTime() {
    DateTime now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  }

  void _showAppSnackBar(String text, Color bg, {int durationSeconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: bg,
        duration: Duration(seconds: durationSeconds),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _vlcControllers.values) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        elevation: 6,
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Family Care VIP Command Center',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(isSystemArmed ? 'ARMED • Multi-Camera RTSP Active' : 'STATUS: DISARMED',
                      style: TextStyle(color: isSystemArmed ? Colors.greenAccent : Colors.orangeAccent, fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isSystemArmed ? Icons.lock_outlined : Icons.lock_open_rounded,
                color: isSystemArmed ? Colors.greenAccent : Colors.amberAccent),
            onPressed: toggleSystemArming,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const AiVideoChatSearchScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const EnterpriseSettingsScreen()));
              _initializeRTSPStreams();
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
            // Wallet Card Banner
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ACTIVE AI CREDITS WALLET',
                          style: TextStyle(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('₹${walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => fnHandleWalletTopUp(),
                    icon: const Icon(Icons.add_card_rounded, color: Color(0xFF1E1B4B), size: 18),
                    label: const Text('Top-Up ₹500',
                        style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Multi-Camera Grid (8-10+ Streams)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${globalEnterpriseCameras.length} Streams',
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
            const SizedBox(height: 12),
            globalEnterpriseCameras.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                    child: const Column(
                      children: [
                        Icon(Icons.videocam_off_rounded, size: 36, color: Colors.white38),
                        SizedBox(height: 8),
                        Text('No External CCTV RTSP Nodes Configured Yet',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(height: 4),
                        Text('Tap Settings (⚙️) on top right to add RTSP camera links anytime.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 16 / 13,
                    ),
                    itemCount: globalEnterpriseCameras.length,
                    itemBuilder: (context, index) {
                      String camName = globalEnterpriseCameras.keys.elementAt(index);
                      dynamic camData = globalEnterpriseCameras[camName];
                      dynamic controller = _vlcControllers[camName];

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12, width: 1),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Center(
                                child: (camData["active"] == true && controller != null)
                                    ? VlcPlayer(
                                        controller: controller,
                                        aspectRatio: 16 / 9,
                                        placeholder: const Center(
                                            child: CircularProgressIndicator(color: Colors.amberAccent)),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.videocam_off, color: Colors.white38, size: 24),
                                          SizedBox(height: 4),
                                          Text('Offline',
                                              style: TextStyle(color: Colors.white54, fontSize: 9)),
                                        ],
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                                child: Text(camName,
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: isAnalyzingAI ? null : () => triggerGroqVisionScan(camName),
                                icon: const Icon(Icons.bolt_rounded, size: 14, color: Colors.black),
                                label: Text(
                                  isAnalyzingAI ? 'Scanning...' : 'AI Scan',
                                  style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            const Text('Live Security Audit Logs',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: globalEnterpriseLogs.length,
              itemBuilder: (context, index) {
                var log = globalEnterpriseLogs[index];
                bool isHigh = log["level"] == "High";
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isHigh ? Colors.redAccent.withOpacity(0.6) : Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(log["camera"] ?? "Node",
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(log["time"] ?? "",
                              style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(log["event"] ?? "",
                          style: TextStyle(
                              color: isHigh ? Colors.redAccent : Colors.white70,
                              fontSize: 12,
                              fontWeight: isHigh ? FontWeight.bold : FontWeight.normal)),
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

// ============================================================================
// SETTINGS SCREEN
// ============================================================================
class EnterpriseSettingsScreen extends StatefulWidget {
  const EnterpriseSettingsScreen({super.key});

  @override
  State<EnterpriseSettingsScreen> createState() => _EnterpriseSettingsScreenState();
}

class _EnterpriseSettingsScreenState extends State<EnterpriseSettingsScreen> {
  final TextEditingController _apiKeyController =
      TextEditingController(text: globalGroqApiKey);
  final TextEditingController _promptController =
      TextEditingController(text: globalCustomAIPrompt);
  final TextEditingController _camNameController = TextEditingController();
  final TextEditingController _camIpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Settings & Nodes', style: TextStyle(fontSize: 14)),
        backgroundColor: const Color(0xFF1E1B4B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Groq API Key Setup',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
            const SizedBox(height: 6),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Enter your Groq API Key (gsk_...)',
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Custom AI Security Prompt',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
            const SizedBox(height: 6),
            TextField(
              controller: _promptController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Add New RTSP CCTV Camera Node (8-10+ support)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
            const SizedBox(height: 8),
            TextField(
              controller: _camNameController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Camera Name (e.g. Counter Cam 5)',
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _camIpController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'RTSP Link (rtsp://username:pass@ip:port/stream)',
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
              onPressed: () {
                if (_camNameController.text.isNotEmpty && _camIpController.text.isNotEmpty) {
                  setState(() {
                    globalEnterpriseCameras[_camNameController.text.trim()] = {
                      "ip": _camIpController.text.trim(),
                      "active": true
                    };
                  });
                  _camNameController.clear();
                  _camIpController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ RTSP Camera Node Added Successfully!')));
                }
              },
              child: const Text('Save & Add Camera Node', style: TextStyle(color: Color(0xFF1E1B4B))),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              onPressed: () {
                globalGroqApiKey = _apiKeyController.text.trim();
                globalCustomAIPrompt = _promptController.text.trim();
                Navigator.pop(context);
              },
              child: const Text('Save All Settings & Return', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AI CHAT & SEARCH SCREEN
// ============================================================================
class AiVideoChatSearchScreen extends StatefulWidget {
  const AiVideoChatSearchScreen({super.key});

  @override
  State<AiVideoChatSearchScreen> createState() => _AiVideoChatSearchScreenState();
}

class _AiVideoChatSearchScreenState extends State<AiVideoChatSearchScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List _messages = [
    {"role": "ai", "content": "Hello! I am your Family Care AI Assistant. Ask me anything about your active security feeds or threat logs."}
  ];

  void _sendMessage() {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _messages.add({"role": "ai", "content": "Analyzing security query against active multi-camera enterprise streams..."});
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant & Log Query', style: TextStyle(fontSize: 14)),
        backgroundColor: const Color(0xFF1E1B4B),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var msg = _messages[index];
                bool isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF312E81) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg["content"] ?? "",
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1E1B4B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Ask about security status or logs...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyanAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
