// ============================================================================
// FAMILY CARE VISION AI - ENTERPRISE HYBRID EDITION (CLEAN & FINAL)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

// ============================================================================
// GLOBAL STATE MANAGEMENT & CONFIGURATIONS
// ============================================================================

Map<String, dynamic> globalEnterpriseCameras = {};

String globalCustomAIPrompt =
    "Scan this media frame carefully for the Family Care Security Hub. "
    "Detect any security threat such as unauthorized intruders, forced entry, "
    "smoke, fire, hazardous objects, unattended children near dangerous zones, "
    "or any bullying/misbehavior in school and commercial premises.";

String globalGroqApiKey = "";

String activeChatModel = "qwen/qwen3.8-27b";
String activeVisionModel = "llama-3.2-11b-vision-preview";

int autoScanIntervalSeconds = 15;

List> globalEnterpriseLogs = [
  {
    "time": "System Boot",
    "camera": "Enterprise Master Hub",
    "event": "🛡️ Security Hub Initialized Successfully in Gallery & RTSP Hybrid Mode.",
    "videoPath": "N/A",
    "level": "Info"
  }
];

// ============================================================================
// APPLICATION ENTRY POINT
// ============================================================================

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

// ============================================================================
// ENTERPRISE COMMAND CENTER DASHBOARD SCREEN
// ============================================================================

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
  String? _lastPickedFilepath;

  final Map<String, VlcPlayerController> _vlcControllers = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRTSPStreams();
    });
  }

  // --------------------------------------------------------------------------
  // GALLERY MEDIA & VIDEO UPLOAD AI SCAN ENGINE
  // --------------------------------------------------------------------------
  Future<void> _pickAndScanFromGallery() async {
    if (globalGroqApiKey.trim().isEmpty) {
      _showAppSnackBar('⚠️ Please enter your Groq API Key in Settings (⚙️) first!', Colors.redAccent);
      return;
    }

    try {
      final XFile? media = await _picker.pickMedia();
      if (media == null) return;

      setState(() {
        _lastPickedFilepath = media.path;
        isAnalyzingAI = true;
      });

      var bytes = await media.readAsBytes();
      String base64Data = base64Encode(bytes);

      String aiTextResponse = await _sendFrameToGroqVisionAPI(base64Data);
      bool isThreatDetected = _detectThreatKeywords(aiTextResponse);

      setState(() {
        walletBalance -= 0.75;
        globalEnterpriseLogs.insert(0, {
          "time": _getCurrentFormattedTime(),
          "camera": "Gallery Media Audit Node",
          "event": "🤖 AI Video/Photo Audit: $aiTextResponse",
          "videoPath": media.path,
          "level": isThreatDetected ? "High" : "Info"
        });
      });

      _showAppSnackBar('✅ Gallery Media Scanned Successfully by Groq AI!', Colors.green);
    } catch (e) {
      _showAppSnackBar('❌ Gallery Scan Error: $e', Colors.red, durationSeconds: 5);
    } finally {
      setState(() {
        isAnalyzingAI = false;
      });
    }
  }

  // --------------------------------------------------------------------------
  // RTSP CCTV STREAMS INITIALIZATION
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // RTSP SNAPSHOT AI VISION SCANNER
  // --------------------------------------------------------------------------
  Future<void> triggerGroqVisionScan(String cameraName) async {
    if (walletBalance < 0.75) {
      _showAppSnackBar('⚠️ Insufficient Wallet Credits! Please Top-Up ₹500.', Colors.orange);
      return;
    }

    if (globalGroqApiKey.trim().isEmpty) {
      _showAppSnackBar('⚠️ Please configure your API Key in Settings (⚙️)!', Colors.redAccent);
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

      var imageBytes = await controller.takeSnapshot();
      if (imageBytes.isEmpty) {
        throw Exception("Failed to capture frame snapshot from RTSP feed.");
      }

      String base64Image = base64Encode(imageBytes);
      String aiTextResponse = await _sendFrameToGroqVisionAPI(base64Image);
      bool isThreatDetected = _detectThreatKeywords(aiTextResponse);

      setState(() {
        walletBalance -= 0.75;
        globalEnterpriseLogs.insert(0, {
          "time": _getCurrentFormattedTime(),
          "camera": cameraName,
          "event": "🤖 Live CCTV Audit: $aiTextResponse",
          "videoPath": "RTSP Live Stream Snapshot",
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

  // --------------------------------------------------------------------------
  // GROQ VISION API COMMUNICATION CLIENT
  // --------------------------------------------------------------------------
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

  void handleWalletTopUp() {
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

  // --------------------------------------------------------------------------
  // UI BUILD INTERFACE
  // --------------------------------------------------------------------------
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
                  Text(isSystemArmed ? 'ARMED • Hybrid Mode' : 'STATUS: DISARMED',
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
            tooltip: 'Arm/Disarm System',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const AiVideoChatSearchScreen()));
            },
            tooltip: 'AI Intelligence Chat',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const EnterpriseSettingsScreen()));
              _initializeRTSPStreams();
              setState(() {});
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WALLET CONTAINER
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
                    onPressed: handleWalletTopUp,
                    icon: const Icon(Icons.add_card_rounded, color: Color(0xFF1E1B4B), size: 18),
                    label: const Text('Top-Up ₹500',
                        style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // GALLERY VIDEO & PHOTO UPLOAD AI CHECK SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.video_library_rounded, size: 44, color: Colors.cyanAccent),
                  const SizedBox(height: 8),
                  const Text('Upload Video / Photo from Gallery for AI Threat Check',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Test Groq Vision AI instantly with local storage clips or images.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isAnalyzingAI ? null : _pickAndScanFromGallery,
                    icon: const Icon(Icons.upload_file_rounded, color: Color(0xFF0F172A), size: 18),
                    label: Text(
                      isAnalyzingAI ? 'AI Analyzing Media...' : 'Pick Video/Photo & Scan',
                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  if (_lastPickedFilepath != null) ...[
                    const SizedBox(height: 8),
                    Text('File: ${_lastPickedFilepath!.split('/').last}',
                        style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 22),

            // RTSP CCTV NODES GRID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Real CCTV RTSP Camera Nodes Grid',
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
                                    ? VlcPlayer(
                                        controller: controller,
                                        aspectRatio: 16 / 9,
                                        placeholder: const CircularProgressIndicator(color: Colors.amberAccent))
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(strokeWidth: 2),
                                          SizedBox(height: 6),
                                          Text('Connecting RTSP...', style: TextStyle(color: Colors.white54, fontSize: 9)),
                                        ],
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                                child: Text(camName,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('AI SCAN',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 26),

            // SECURITY THREAT LOGS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Enterprise Threat Intelligence Logs',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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

            globalEnterpriseLogs.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                        child: Text('No security audit logs recorded yet.',
                            style: TextStyle(color: Colors.white54, fontSize: 12))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: globalEnterpriseLogs.length,
                    itemBuilder: (context, index) {
                      var log = globalEnterpriseLogs[index];
                      bool isHigh = log["level"] == "High";
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isHigh ? Colors.redAccent.withOpacity(0.6) : Colors.white10, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(isHigh ? Icons.warning_amber_rounded : Icons.shield_outlined,
                                        color: isHigh ? Colors.redAccent : Colors.cyanAccent, size: 14),
                                    const SizedBox(width: 6),
                                    Text(log["camera"] ?? "Node",
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                Text(log["time"] ?? "", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(log["event"] ?? "",
                                style: TextStyle(
                                    color: isHigh ? Colors.red.shade100 : Colors.white70, fontSize: 12)),
                            if (log["videoPath"] != null && log["videoPath"] != "N/A") ...[
                              const SizedBox(height: 4),
                              Text("Evidence: ${log["videoPath"]}",
                                  style: const TextStyle(color: Colors.white38, fontSize: 9)),
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

// ============================================================================
// AI INTELLIGENCE CHAT SEARCH SCREEN
// ============================================================================

class AiVideoChatSearchScreen extends StatefulWidget {
  const AiVideoChatSearchScreen({super.key});

  @override
  State<AiVideoChatSearchScreen> createState() => _AiVideoChatSearchScreenState();
}

class _AiVideoChatSearchScreenState extends State<AiVideoChatSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List> _chatHistory = [
    {
      "role": "assistant",
      "content": "Hello! Ask me anything about your captured security audit logs, threat timestamps, or gallery video scan analyses."
    }
  ];
  bool _isSending = false;

  Future<void> _askSecurityAI() async {
    String userQuery = _queryController.text.trim();
    if (userQuery.isEmpty) return;

    if (globalGroqApiKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please add Groq API Key in Settings first!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _chatHistory.add({"role": "user", "content": userQuery});
      _queryController.clear();
      _isSending = true;
    });

    try {
      String logsContext = jsonEncode(globalEnterpriseLogs.take(25).toList());
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${globalGroqApiKey.trim()}'
        },
        body: jsonEncode({
          "model": activeChatModel,
          "messages": [
            {
              "role": "system",
              "content": "You are the Family Care Enterprise Security Analyst AI. Answer user questions based on these security logs: $logsContext"
            },
            {"role": "user", "content": userQuery}
          ],
          "max_tokens": 500
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply = data['choices']?[0]['message']?['content'] ?? "No response generated.";
        setState(() {
          _chatHistory.add({"role": "assistant", "content": reply});
        });
      } else {
        throw Exception("Server Error ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _chatHistory.add({"role": "assistant", "content": "Failed to fetch AI reply: $e"});
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Security Log Assistant', style: TextStyle(fontSize: 15)),
        backgroundColor: const Color(0xFF1E1B4B),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                var msg = _chatHistory[index];
                bool isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF312E81) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(msg["content"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                );
              },
            ),
          ),
          if (_isSending) const LinearProgressIndicator(color: Colors.amberAccent),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask about security threats, logs, or gallery video scans...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.amberAccent, padding: const EdgeInsets.all(12)),
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF1E1B4B)),
                  onPressed: _isSending ? null : _askSecurityAI,
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
// ENTERPRISE SETTINGS & RTSP CONFIGURATION SCREEN
// ============================================================================

class EnterpriseSettingsScreen extends StatefulWidget {
  const EnterpriseSettingsScreen({super.key});

  @override
  State<EnterpriseSettingsScreen> createState() => _EnterpriseSettingsScreenState();
}

class _EnterpriseSettingsScreenState extends State<EnterpriseSettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController(text: globalGroqApiKey);
  final TextEditingController _promptController = TextEditingController(text: globalCustomAIPrompt);
  final TextEditingController _camNameController = TextEditingController();
  final TextEditingController _camIpController = TextEditingController();

  void _addNewRtspCamera() {
    String name = _camNameController.text.trim();
    String ip = _camIpController.text.trim();
    if (name.isEmpty || ip.isEmpty) return;

    setState(() {
      globalEnterpriseCameras[name] = {
        "ip": ip,
        "active": true,
      };
      _camNameController.clear();
      _camIpController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ RTSP Node "$name" Added Successfully!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Hub Settings & BYOK', style: TextStyle(fontSize: 15)),
        backgroundColor: const Color(0xFF1E1B4B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('1. Groq API Key (BYOK Model)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'gsk_...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          const Text('2. Custom AI Security & School Audit Prompt',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          const Text('3. Add Real CCTV RTSP Camera Stream (VLC Engine)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 8),
          TextField(
            controller: _camNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Camera Name (e.g., Main Gate / Class 10A)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _camIpController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'RTSP URL (rtsp://admin:pass@192.168.1.50:554/stream1)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.cyanAccent),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _addNewRtspCamera,
            icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
            label: const Text('Add RTSP Camera Node', style: TextStyle(color: Colors.cyanAccent)),
          ),
          if (globalEnterpriseCameras.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...globalEnterpriseCameras.keys.map((camKey) => ListTile(
                  tileColor: const Color(0xFF1E293B),
                  title: Text(camKey, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(globalEnterpriseCameras[camKey]["ip"] ?? "",
                      style: const TextStyle(fontSize: 10, color: Colors.white54)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        globalEnterpriseCameras.remove(camKey);
                      });
                    },
                  ),
                )),
          ],
          const SizedBox(height: 28),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              globalGroqApiKey = _apiKeyController.text.trim();
              globalCustomAIPrompt = _promptController.text.trim();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ All Enterprise Settings Saved!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Save All Configuration',
                style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
