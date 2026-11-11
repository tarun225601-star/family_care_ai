import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

Map globalEnterpriseCameras = {};
String globalCustomAIPrompt = "Scan this video frame carefully. Detect any security threat such as unauthorized intruders, forced entry, smoke/fire, or unattended children near stairs.";
String globalGroqApiKey = "";

// कड़े नियमों के साथ अलग-अलग मॉडल
String activeChatModel = "llama-3.3-70b-versatile"; 
String activeVisionModel = "llama-3.2-11b-vision-preview"; 
bool isModelsAutoConfigured = false;

List globalEnterpriseLogs = [];

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E1B4B),
          brightness: Brightness.dark,
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
  bool isAnalyzingAI = false;
  final Map _vlcControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeRTSPStreams();
    if (globalGroqApiKey.isNotEmpty) {
      _autoDetectWorkingModels();
    }
  }

  // 🚀 सही मॉडल अलग-अलग छाँटने का ऑटो-डिस्कवरी लूप
  Future<void> _autoDetectWorkingModels() async {
    if (globalGroqApiKey.trim().isEmpty) return;

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/models');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${globalGroqApiKey.trim()}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List models = data['data'] ?? [];
        
        List<String> availableModelIds = [];
        for (var m in models) {
          if (m['id'] != null) {
            availableModelIds.add(m['id'].toString());
          }
        }

        // 1. विजन मॉडल सिर्फ वही उठेगा जिसमें 'vision' होगा!
        for (String m in availableModelIds) {
          if (m.toLowerCase().contains('vision')) {
            activeVisionModel = m;
            break;
          }
        }

        // 2. चैट मॉडल जिसके पास 'versatile' या 'instant' हो
        for (String m in availableModelIds) {
          if ((m.toLowerCase().contains('70b') || m.toLowerCase().contains('instant')) && !m.toLowerCase().contains('vision')) {
            activeChatModel = m;
            break;
          }
        }

        setState(() {
          isModelsAutoConfigured = true;
        });
        debugPrint("✅ Locked Chat Model: $activeChatModel");
        debugPrint("✅ Locked Vision Model: $activeVisionModel");
      }
    } catch (e) {
      debugPrint("⚠️ Auto-discovery fallback active: $e");
    }
  }

  void _initializeRTSPStreams() {
    for (var controller in _vlcControllers.values) {
      controller.dispose();
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
          debugPrint("Stream init error: $e");
        }
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    for (var controller in _vlcControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 👁️ विजन स्कैन के लिए सिर्फ विजन वाले मॉडल्स की ही लिस्ट लूप में चलेगी
  Future<void> triggerGroqVisionScan(String cameraName) async {
    if (walletBalance < 0.75) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Insufficient Wallet Balance!'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (globalGroqApiKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter your Groq API Key in Settings (⚙️)!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      isAnalyzingAI = true;
    });

    try {
      dynamic controller = _vlcControllers[cameraName];
      if (controller == null || !controller.value.isInitialized) {
        throw Exception("Camera stream not connected");
      }

      var imageBytes = await controller.takeSnapshot();
      String base64Image = base64Encode(imageBytes);

      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      // सिर्फ पक्के विजन मॉडल्स
      List<String> visionOnlyFallbacks = [
        activeVisionModel, 
        'llama-3.2-11b-vision-preview', 
        'llama-3.2-90b-vision-preview'
      ];
      
      bool success = false;
      String aiTextResponse = "";

      for (String modelName in visionOnlyFallbacks) {
        try {
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${globalGroqApiKey.trim()}'
            },
            body: jsonEncode({
              "model": modelName,
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
              "max_tokens": 300
            }),
          );

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            aiTextResponse = responseData['choices']?[0]['message']?['content'] ?? "No Threat Detected";
            success = true;
            break; 
          }
        } catch (_) {
          // अगला विजन मॉडल ट्राई करो
        }
      }

      if (!success) {
        throw Exception("All vision models failed.");
      }

      String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
      String localSavedPath = "/storage/emulated/0/DCIM/FamilyCare_Evidence_$timeStamp.mp4";

      setState(() {
        walletBalance -= 0.75;
        globalEnterpriseLogs.insert(0, {
          "time": "Just now",
          "camera": cameraName,
          "event": "🤖 AI Vision Scan: $aiTextResponse",
          "videoPath": localSavedPath,
          "level": "High"
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 AI Scan Completed Successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ AI Scan Failed: $e'), backgroundColor: Colors.red),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 22),
            const SizedBox(width: 8),
            Text('Smart AI Hub (${isModelsAutoConfigured ? "Synced" : "Default"})', style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AiVideoChatSearchScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const EnterpriseSettingsScreen()));
              _initializeRTSPStreams();
              _autoDetectWorkingModels();
              setState(() {});
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
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAnalyzingAI ? 'SCANNING...' : 'AI WALLET BALANCE', style: const TextStyle(fontSize: 10, color: Colors.amberAccent)),
                      const SizedBox(height: 4),
                      Text('₹${walletBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
                    onPressed: handleWalletTopUp,
                    child: const Text('Top-Up ₹500', style: TextStyle(color: Color(0xFF1E1B4B))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Live Camera Feeds (RTSP Multi-View)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            globalEnterpriseCameras.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                    child: const Center(
                      child: Text('No Camera Nodes Configured. Tap Settings (⚙️) to add RTSP URL.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 16 / 12),
                    itemCount: globalEnterpriseCameras.length,
                    itemBuilder: (context, index) {
                      String camName = globalEnterpriseCameras.keys.elementAt(index);
                      dynamic controller = _vlcControllers[camName];
                      return Container(
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                        child: Stack(
                          children: [
                            Center(
                              child: controller != null
                                  ? VlcPlayer(controller: controller, aspectRatio: 16 / 9, placeholder: const CircularProgressIndicator())
                                  : const Text('Connecting...', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            ),
                            Positioned(top: 6, left: 6, child: Text(camName, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: InkWell(
                                onTap: isAnalyzingAI ? null : () => triggerGroqVisionScan(camName),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('AI SCAN', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 22),
            const Text('Intelligence & Evidence Logs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                  child: Text(log["event"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AiVideoChatSearchScreen extends StatefulWidget {
  const AiVideoChatSearchScreen({super.key});

  @override
  State<AiVideoChatSearchScreen> createState() => _AiVideoChatSearchScreenState();
}

class _AiVideoChatSearchScreenState extends State<AiVideoChatSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List _chatMessages = [];
  bool _isSearching = false;

  // 💬 चैट के लिए सिर्फ टेक्स्ट वाले मॉडल्स की लिस्ट
  Future<void> _performSmartChatSearch(String query) async {
    if (globalGroqApiKey.trim().isEmpty) {
      setState(() {
        _chatMessages.add({'sender': 'ai', 'message': '❌ API Key missing! Add it in Settings.'});
      });
      return;
    }

    setState(() {
      _chatMessages.add({'sender': 'user', 'message': query});
      _isSearching = true;
    });

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      List<String> chatOnlyFallbacks = [
        activeChatModel,
        'llama-3.3-70b-versatile',
        'llama-3.1-8b-instant'
      ];

      bool success = false;
      String aiReply = "";

      for (String modelName in chatOnlyFallbacks) {
        try {
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${globalGroqApiKey.trim()}'
            },
            body: jsonEncode({
              "model": modelName,
              "messages": [
                {
                  "role": "system",
                  "content": "You are the AI Video Search Engine for security logs."
                },
                {
                  "role": "user",
                  "content": "Query: $query. Search logs and summarize."
                }
              ]
            }),
          );

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            aiReply = responseData['choices']?[0]['message']?['content'] ?? "No records found.";
            success = true;
            break;
          }
        } catch (_) {
          // अगला चैट मॉडल ट्राई करो
        }
      }

      if (!success) {
        throw Exception("All chat models failed.");
      }

      setState(() {
        _chatMessages.add({'sender': 'ai', 'message': aiReply});
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({'sender': 'ai', 'message': '❌ Error: $e'});
        _isSearching = false;
      });
    }
    _queryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart AI Chat', style: TextStyle(color: Colors.white, fontSize: 14)), backgroundColor: const Color(0xFF1E1B4B)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                bool isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isUser ? Colors.blue : const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                    child: Text(msg['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                  ),
                );
              },
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(color: Colors.amberAccent),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1E1B4B),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _queryController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Ask about footage...', border: InputBorder.none))),
                IconButton(icon: const Icon(Icons.send_rounded, color: Colors.amberAccent), onPressed: () => _performSmartChatSearch(_queryController.text.trim())),
              ],
            ),
          ),
        ],
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
  final TextEditingController _keyController = TextEditingController(text: globalGroqApiKey);
  final TextEditingController _nodeIpController = TextEditingController();
  final TextEditingController _nodeNameController = TextEditingController();

  void _save() {
    globalGroqApiKey = _keyController.text.trim();
    String name = _nodeNameController.text.trim();
    String ip = _nodeIpController.text.trim();

    if (name.isNotEmpty && ip.isNotEmpty) {
      globalEnterpriseCameras[name] = {"active": true, "ip": ip};
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Configuration', style: TextStyle(color: Colors.white, fontSize: 16)), backgroundColor: const Color(0xFF1E1B4B)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Groq API Key:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(controller: _keyController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(filled: true, fillColor: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          const Text('Add RTSP Camera Node:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _nodeNameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Camera Name (e.g. Gate)', filled: true, fillColor: Color(0xFF1E293B))),
          const SizedBox(height: 10),
          TextField(controller: _nodeIpController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'RTSP URL (rtsp://...)', filled: true, fillColor: Color(0xFF1E293B))),
          const SizedBox(height: 30),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent), onPressed: _save, child: const Text('Save & Auto-Sync Models', style: TextStyle(color: Color(0xFF1E1B4B)))),
        ],
      ),
    );
  }
}
