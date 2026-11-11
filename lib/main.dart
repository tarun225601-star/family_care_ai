import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// ============================================================================
// 1. GLOBAL ENTERPRISE STATE & CONFIGURATION CONSTANTS
// ============================================================================

Map globalEnterpriseCameras = {
  "Main Gate Entrance": {
    "active": true,
    "ip": "rtsp://192.168.1.100:554/stream1"
  },
  "Backyard Perimeter": {
    "active": true,
    "ip": "rtsp://192.168.1.101:554/stream1"
  },
  "Living Room Staircase": {
    "active": true,
    "ip": "rtsp://192.168.1.102:554/stream1"
  },
  "Garage & Parking": {
    "active": true,
    "ip": "rtsp://192.168.1.103:554/stream1"
  }
};

String globalCustomAIPrompt = 
    "Scan this video frame carefully for the Family Care Security Hub. "
    "Detect any security threat such as unauthorized intruders, forced entry, "
    "smoke, fire, hazardous objects, or unattended children near dangerous zones.";

String globalGroqApiKey = "";

// Default Stabilized Target Models for Enterprise Production
String activeChatModel = "llama-3.1-8b-instant";
String activeVisionModel = "llama-3.2-11b-vision-preview";

List globalEnterpriseLogs = [
  {
    "time": "System Boot",
    "camera": "Master Hub",
    "event": "🛡️ Enterprise Security Hub Initialized Successfully in Armed Mode.",
    "videoPath": "N/A",
    "level": "Info"
  }
];

// ============================================================================
// 2. MAIN APPLICATION ENTRY POINT & THEME CONFIGURATION
// ============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FamilyCareVIPApp());
}

class FamilyCareVIPApp extends StatelessWidget {
  const FamilyCareVIPApp({super.key});

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

// ============================================================================
// 3. ENTERPRISE DASHBOARD SCREEN (MAIN MULTI-VIEW COMMAND CENTER)
// ============================================================================

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

  // Initialize and manage VLC RTSP Network Streams safely
  void _initializeRTSPStreams() {
    for (var controller in _vlcControllers.values) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    _vlcControllers.clear();

    globalEnterpriseCameras.forEach((camName, data) {
      if (data["active"] == true && data["ip"] != null && data["ip"].toString().isNotEmpty) {
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
          debugPrint("RTSP Stream Connection Error for $camName: $e");
        }
      }
    });
    setState(() {});
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

  // 👁️ GROQ AI VISION SCANNER WITH TRANSPARENT DIAGNOSTIC ERROR OUTPUT
  Future<void> triggerGroqVisionScan(String cameraName) async {
    if (walletBalance < 0.75) {
      _showAppSnackBar('⚠️ Insufficient Wallet Balance! Please Top-Up ₹500.', Colors.orange);
      return;
    }

    if (globalGroqApiKey.trim().isEmpty) {
      _showAppSnackBar('⚠️ Please enter your Groq API Key in Settings (⚙️)!', Colors.redAccent);
      return;
    }

    setState(() {
      isAnalyzingAI = true;
    });

    try {
      dynamic controller = _vlcControllers[cameraName];
      if (controller == null || !controller.value.isInitialized) {
        throw Exception("Camera stream '$cameraName' is offline, uninitialized, or connection failed.");
      }

      var imageBytes = await controller.takeSnapshot();
      if (imageBytes.isEmpty) {
        throw Exception("Failed to capture image frame snapshot from RTSP feed.");
      }

      String base64Image = base64Encode(imageBytes);
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

      String aiTextResponse = "";
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        aiTextResponse = responseData['choices']?[0]['message']?['content'] ?? "No Threats Detected in Frame.";
      } else {
        throw Exception("Groq Server HTTP ${response.statusCode}: ${response.body}");
      }

      String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
      String localSavedPath = "/storage/emulated/0/DCIM/FamilyCare_Evidence_$timeStamp.jpg";

      setState(() {
        walletBalance -= 0.75;
        globalEnterpriseLogs.insert(0, {
          "time": _getCurrentFormattedTime(),
          "camera": cameraName,
          "event": "🤖 AI Vision Scan: $aiTextResponse",
          "videoPath": localSavedPath,
          "level": "High"
        });
      });

      _showAppSnackBar('🚨 AI Vision Scan Completed Successfully!', Colors.green);
    } catch (e) {
      _showAppSnackBar('❌ AI Scan Failed: $e', Colors.red, durationSeconds: 6);
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
    _showAppSnackBar('✅ Successfully Added ₹500.00 to AI Credits Wallet.', Colors.lightBlue);
  }

  void toggleSystemArming() {
    setState(() {
      isSystemArmed = !isSystemArmed;
    });
    _showAppSnackBar(
      isSystemArmed ? '🔒 Security System ARMED & Active' : '🔓 Security System Disarmed',
      isSystemArmed ? Colors.green : Colors.amber,
    );
  }

  String _getCurrentFormattedTime() {
    DateTime now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  }

  void _showAppSnackBar(String text, Color bg, {int durationSeconds = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: bg,
        duration: Duration(seconds: durationSeconds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        elevation: 6,
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Family Care VIP Command Center', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(isSystemArmed ? 'STATUS: ARMED & SECURE' : 'STATUS: DISARMED', style: TextStyle(color: isSystemArmed ? Colors.greenAccent : Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isSystemArmed ? Icons.lock_outlined : Icons.lock_open_rounded, color: isSystemArmed ? Colors.greenAccent : Colors.amberAccent),
            onPressed: toggleSystemArming,
            tooltip: 'Arm/Disarm System',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AiVideoChatSearchScreen()));
            },
            tooltip: 'AI Intelligence Chat',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const EnterpriseSettingsScreen()));
              _initializeRTSPStreams();
              setState(() {});
            },
            tooltip: 'System Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.amberAccent,
        backgroundColor: const Color(0xFF1E1B4B),
        onRefresh: () async {
          _initializeRTSPStreams();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ENTERPRISE WALLET & SYSTEM METRICS BANNER ---
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isAnalyzingAI ? 'AI SCANNING IN PROGRESS...' : 'ACTIVE AI CREDITS WALLET', style: const TextStyle(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('₹${walletBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: handleWalletTopUp,
                          icon: const Icon(Icons.add_card_rounded, color: Color(0xFF1E1B4B), size: 18),
                          label: const Text('Top-Up ₹500', style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricChip(Icons.videocam_rounded, "${globalEnterpriseCameras.length} Nodes", "RTSP Feeds"),
                        _buildMetricChip(Icons.security_rounded, "${globalEnterpriseLogs.length} Events", "Logged"),
                        _buildMetricChip(Icons.memory_rounded, activeVisionModel.split('-').first.toUpperCase(), "Vision Engine"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('RTSP Camera Nodes Grid', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('${globalEnterpriseCameras.length} Active Streams', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
              const SizedBox(height: 12),

              // --- CAMERA FEED MULTI-VIEW GRID ---
              globalEnterpriseCameras.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        children: [
                          Icon(Icons.videocam_off_rounded, size: 48, color: Colors.white38),
                          SizedBox(height: 12),
                          Text('No Active RTSP Nodes Configured', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('Tap the Settings icon (⚙️) on top right to add RTSP streams.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11)),
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
                                  child: controller != null
                                      ? VlcPlayer(controller: controller, aspectRatio: 16 / 9, placeholder: const CircularProgressIndicator(color: Colors.amberAccent))
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(strokeWidth: 2),
                                            SizedBox(height: 8),
                                            Text('Connecting RTSP...', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                          ],
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 10),
                                      const SizedBox(width: 4),
                                      Text(camName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: isAnalyzingAI ? null : () => triggerGroqVisionScan(camName),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Colors.redAccent, Colors.deepOrange]),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('AI SCAN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enterprise Threat Intelligence Logs', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        globalEnterpriseLogs.clear();
                      });
                    },
                    child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // --- LOGS LISTVIEW ---
              globalEnterpriseLogs.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('No Threat Logs Recorded Yet.', style: TextStyle(color: Colors.white54, fontSize: 12))),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: globalEnterpriseLogs.length,
                      itemBuilder: (context, index) {
                        Map log = globalEnterpriseLogs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFF312E81),
                                radius: 16,
                                child: Icon(Icons.security_rounded, size: 16, color: Colors.amberAccent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(log["camera"] ?? "Node", style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                        Text(log["time"] ?? "", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(log["event"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 12)),
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
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.amberAccent, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}

// ============================================================================
// 4. AI CHAT & SEARCH ENGINE SCREEN (INTELLIGENCE HUB)
// ============================================================================

class AiVideoChatSearchScreen extends StatefulWidget {
  const AiVideoChatSearchScreen({super.key});

  @override
  State<AiVideoChatSearchScreen> createState() => _AiVideoChatSearchScreenState();
}

class _AiVideoChatSearchScreenState extends State<AiVideoChatSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List _chatMessages = [];
  bool _isSearching = false;

  // 💬 CHAT SCANNER WITH DIRECT TRANSPARENT ERROR DISPLAY (NO LOOPS)
  Future<void> _performSmartChatSearch(String query) async {
    if (query.trim().isEmpty) return;

    if (globalGroqApiKey.trim().isEmpty) {
      setState(() {
        _chatMessages.add({'sender': 'ai', 'message': '❌ API Key missing! Set it in System Settings (⚙️).'});
      });
      return;
    }

    setState(() {
      _chatMessages.add({'sender': 'user', 'message': query});
      _isSearching = true;
    });

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${globalGroqApiKey.trim()}'
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": [
            {
              "role": "system",
              "content": "You are the AI Assistant for the Family Care Security Hub. Use enterprise security context to answer queries accurately."
            },
            {
              "role": "user",
              "content": "User Inquiry: $query\nRecent System Logs: ${globalEnterpriseLogs.toString()}"
            }
          ],
          "max_tokens": 500
        }),
      );

      String aiReply = "";
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        aiReply = responseData['choices']?[0]['message']?['content'] ?? "No response generated by model.";
      } else {
        // Direct Server Diagnostic Error Output
        aiReply = "❌ Groq Server Error (${response.statusCode}):\n${response.body}";
      }

      setState(() {
        _chatMessages.add({'sender': 'ai', 'message': aiReply});
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({'sender': 'ai', 'message': '❌ Exception Caught: $e'});
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
    _queryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Security Intelligence Chat', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Active Chat Model: llama-3.1-8b-instant', style: const TextStyle(color: Colors.cyanAccent, fontSize: 9)),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B4B),
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatMessages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 48, color: Colors.white24),
                        SizedBox(height: 12),
                        Text('Ask AI anything about security logs or past events...', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[index];
                      bool isUser = msg['sender'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.indigoAccent : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                            ),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            msg['message'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isSearching) const LinearProgressIndicator(color: Colors.amberAccent),
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF1E1B4B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ask Groq AI about security status...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (val) => _performSmartChatSearch(val.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.amberAccent),
                  onPressed: () => _performSmartChatSearch(_queryController.text.trim()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. SYSTEM CONFIGURATION & PROMPT SETTINGS SCREEN
// ============================================================================

class EnterpriseSettingsScreen extends StatefulWidget {
  const EnterpriseSettingsScreen({super.key});

  @override
  State<EnterpriseSettingsScreen> createState() => _EnterpriseSettingsScreenState();
}

class _EnterpriseSettingsScreenState extends State<EnterpriseSettingsScreen> {
  late TextEditingController _keyController;
  late TextEditingController _promptController;
  final TextEditingController _nodeIpController = TextEditingController();
  final TextEditingController _nodeNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: globalGroqApiKey);
    _promptController = TextEditingController(text: globalCustomAIPrompt);
  }

  void _saveConfiguration() {
    globalGroqApiKey = _keyController.text.trim();
    globalCustomAIPrompt = _promptController.text.trim();

    String name = _nodeNameController.text.trim();
    String ip = _nodeIpController.text.trim();

    if (name.isNotEmpty && ip.isNotEmpty) {
      globalEnterpriseCameras[name] = {"active": true, "ip": ip};
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Configuration & AI Prompts Saved Successfully!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration & Models', style: TextStyle(color: Colors.white, fontSize: 15)),
        backgroundColor: const Color(0xFF1E1B4B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Groq API Key Authentication', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _keyController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Paste gsk_... API Key here',
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 22),

          const Text('Target Model Configurations', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: activeChatModel,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              labelText: 'Chat Model Engine',
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'llama-3.1-8b-instant', child: Text('llama-3.1-8b-instant (Fastest)')),
              DropdownMenuItem(value: 'llama-3.3-70b-versatile', child: Text('llama-3.3-70b-versatile (High IQ)')),
              DropdownMenuItem(value: 'mixtral-8x7b-32768', child: Text('mixtral-8x7b-32768 (Legacy)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => activeChatModel = val);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: activeVisionModel,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              labelText: 'Vision Scan Model Engine',
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'llama-3.2-11b-vision-preview', child: Text('llama-3.2-11b-vision-preview (Standard)')),
              DropdownMenuItem(value: 'llama-3.2-90b-vision-preview', child: Text('llama-3.2-90b-vision-preview (Pro Vision)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => activeVisionModel = val);
            },
          ),

          const SizedBox(height: 22),
          const Text('Custom AI Vision Threat Detection Prompt', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 22),

          const Text('Add RTSP Camera Node', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _nodeNameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Node Name (e.g., Garage Entrance)',
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nodeIpController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'RTSP Link (rtsp://admin:pass@192.168.1.X:554/live)',
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saveConfiguration,
            child: const Text('Save System Configurations', style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
