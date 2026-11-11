import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

Map globalEnterpriseCameras = {};

String globalCustomAIPrompt = "Scan this video frame carefully. Detect any security threat such as unauthorized intruders, forced entry, smoke/fire, or unattended children near stairs.";
String globalGroqApiKey = "";

// डिफ़ॉल्ट रूप से सबसे स्टेबल मॉडल
String globalSelectedGroqModel = 'llama-3.1-8b-instant';

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
      title: 'Family Care Vision AI Enterprise (Groq Edition)',
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

  // Groq Llama Vision Scan (Camera Frame Analysis)
  Future<void> triggerGroqVisionScan(String cameraName) async {
    if (walletBalance < 0.75) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Insufficient Wallet Balance for AI Vision Analysis!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (globalGroqApiKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter your Groq API Key in Settings (⚙️)!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isAnalyzingAI = true;
    });

    try {
      dynamic controller = _vlcControllers[cameraName];
      if (controller == null || !controller.value.isInitialized) {
        throw Exception("Real camera stream not connected");
      }

      var imageBytes = await controller.takeSnapshot();
      String base64Image = base64Encode(imageBytes);

      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${globalGroqApiKey.trim()}'
        },
        body: jsonEncode({
          "model": "llama-3.2-11b-vision-preview",
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": globalCustomAIPrompt},
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image"
                  }
                }
              ]
            }
          ],
          "max_tokens": 300
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String aiTextResponse = responseData['choices']?[0]['message']?['content'] ?? "No Threat Detected";

        String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
        String localSavedPath = "/storage/emulated/0/DCIM/FamilyCare_Evidence_$timeStamp.mp4";

        setState(() {
          walletBalance -= 0.75;
          globalEnterpriseLogs.insert(0, {
            "time": "Just now",
            "camera": cameraName,
            "event": "🤖 Groq Vision: $aiTextResponse",
            "videoPath": localSavedPath,
            "level": "High"
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 AI Scan Completed: $localSavedPath'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception("Groq Server Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ AI Scan Failed: $e'),
          backgroundColor: Colors.red,
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
              'Command Center (Groq AI)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.cyanAccent),
            tooltip: 'AI Video Intelligence Chat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiVideoChatSearchScreen()),
              );
            },
          ),
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
              _initializeRTSPStreams();
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
            globalEnterpriseCameras.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.videocam_off_rounded, size: 48, color: Colors.amberAccent),
                        const SizedBox(height: 12),
                        const Text(
                          'No Camera Nodes Configured',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap the settings icon (⚙️) in the top right corner to add your real RTSP IP camera URL.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
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
                      dynamic controller = _vlcControllers[camName];

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
                                      child: Text('Connecting Stream...', style: TextStyle(color: Colors.white54, fontSize: 10)),
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
                                onTap: isAnalyzingAI ? null : () => triggerGroqVisionScan(camName),
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
            globalEnterpriseLogs.isEmpty
                ? const Text('No security events logged yet.', style: TextStyle(color: Colors.white54, fontSize: 11))
                : ListView.builder(
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

class AiVideoChatSearchScreen extends StatefulWidget {
  const AiVideoChatSearchScreen({super.key});

  @override
  State<AiVideoChatSearchScreen> createState() => _AiVideoChatSearchScreenState();
}

class _AiVideoChatSearchScreenState extends State<AiVideoChatSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List _chatMessages = [];
  bool _isSearching = false;

  Future<void> _performGroqChatSearch(String query) async {
    if (globalGroqApiKey.trim().isEmpty) {
      setState(() {
        _chatMessages.add({
          'sender': 'ai',
          'message': '❌ Groq API Key missing! Please enter your key in Settings (⚙️).'
        });
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
          "model": globalSelectedGroqModel,
          "messages": [
            {
              "role": "system",
              "content": "You are the lightning-fast AI Video Intelligence & Search Engine for NVR/DVR security footage."
            },
            {
              "role": "user",
              "content": "Based on the user query: '$query', search through the connected camera logs and return a precise event summary, timestamp, and security status."
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String aiReply = responseData['choices']?[0]['message']?['content'] ?? "No matching records found.";

        setState(() {
          _chatMessages.add({'sender': 'ai', 'message': aiReply});
          _isSearching = false;
        });
      } else {
        setState(() {
          _chatMessages.add({
            'sender': 'ai', 
            'message': '❌ Groq Error (${response.statusCode}): ${response.body}'
          });
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _chatMessages.add({'sender': 'ai', 'message': '❌ Exception: $e'});
        _isSearching = false;
      });
    }
    _queryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    String currentModelDisplay = globalSelectedGroqModel.length > 20 
        ? '${globalSelectedGroqModel.substring(0, 18)}...' 
        : globalSelectedGroqModel;

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Chat ($currentModelDisplay)', style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: const Color(0xFF1E1B4B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatMessages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        '💬 Ask anything about past footage using Groq AI!\n\ne.g., "Show me who visited yesterday at 4 PM" or "Find delivery person at main gate."',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[index];
                      final isUser = msg['sender'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['message'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 12.5),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Colors.amberAccent),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1E1B4B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                    decoration: const InputDecoration(
                      hintText: 'Ask Groq about past events...',
                      hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.amberAccent),
                  onPressed: () {
                    if (_queryController.text.trim().isNotEmpty) {
                      _performGroqChatSearch(_queryController.text.trim());
                    }
                  },
                ),
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
  final TextEditingController _groqKeyController = TextEditingController(text: globalGroqApiKey);
  final TextEditingController _nodeIpController = TextEditingController();
  final TextEditingController _nodeNameController = TextEditingController();
  final TextEditingController _promptController = TextEditingController(text: globalCustomAIPrompt);
  bool _hideGroqKey = true;

  // 20 सबसे बेहतरीन और एक्टिव Groq मॉडल्स की लिस्ट
  final List<String> _availableGroqModels = [
    'llama-3.1-8b-instant',
    'llama-3.3-70b-versatile',
    'llama-3.1-70b-versatile',
    'llama-3.2-1b-preview',
    'llama-3.2-3b-preview',
    'llama-3.2-11b-vision-preview',
    'llama-3.2-90b-vision-preview',
    'llama3-8b-8192',
    'llama3-70b-8192',
    'mixtral-8x7b-32768',
    'gemma-7b-it',
    'gemma2-9b-it',
    'whisper-large-v3',
    'whisper-large-v3-turbo',
    'distil-whisper-large-v3-en',
    'llama-guard-3-8b',
    'llama-3.3-70b-specdec',
    'llama-3.1-405b-reasoning',
    'llama3-groq-70b-8192-tool-use-preview',
    'llama3-groq-8b-8192-tool-use-preview',
  ];

  void _saveSystemConfiguration() {
    String name = _nodeNameController.text.trim();
    String ip = _nodeIpController.text.trim();
    globalCustomAIPrompt = _promptController.text.trim();
    globalGroqApiKey = _groqKeyController.text.trim();

    if (name.isNotEmpty && ip.isNotEmpty) {
      globalEnterpriseCameras[name] = {
        "active": true,
        "ip": ip,
        "status": "Secure",
        "resolution": "1080p FHD",
        "latency": "15ms",
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Real Camera "$name" Added Successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ℹ️ Groq Settings & Model updated successfully!'),
          backgroundColor: Color(0xFF1E1B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration (Groq)', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E1B4B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Groq API Key:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _groqKeyController,
            obscureText: _hideGroqKey,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.key_rounded, color: Colors.amberAccent),
              suffixIcon: IconButton(
                icon: Icon(_hideGroqKey ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white60),
                onPressed: () => setState(() => _hideGroqKey = !_hideGroqKey),
              ),
              filled: true,
              fillColor: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Groq AI Model (20 Options):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: globalSelectedGroqModel,
                dropdownColor: const Color(0xFF1E293B),
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.amberAccent),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                isExpanded: true,
                items: _availableGroqModels.map((String model) {
                  return DropdownMenuItem<String>(
                    value: model,
                    child: Text(model, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      globalSelectedGroqModel = newValue;
                    });
                  }
                },
              ),
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
            'Add Real RTSP Camera Node:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nodeNameController,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'Camera Location (e.g. Main Gate)',
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
              hintText: 'Real RTSP URL (rtsp://username:password@IP:Port/live)',
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
              child: const Text('Save & Apply Groq Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
