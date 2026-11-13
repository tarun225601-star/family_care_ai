import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// ============================================================================
// 1. GLOBAL ENTERPRISE STATE & CONFIGURATION CONSTANTS
// ============================================================================

Map<String, dynamic> globalEnterpriseCameras = {};

String globalCustomAIPrompt =
    "Scan this video frame carefully for the Family Care Security Hub. "
    "Detect any security threat such as unauthorized intruders, forced entry, "
    "smoke, fire, hazardous objects, unattended children near dangerous zones, "
    "or any bullying/misbehavior in school premises.";

String globalGroqApiKey = "";

// Default Active Models
String activeChatModel = "qwen/qwen3.8-27b";
String activeVisionModel = "llama-3.2-11b-vision-preview";

// Dual-Mode Operation State (Day: Hourly Smart Audit | Night: Instant Alert)
String activeSecurityScheduleMode = "Auto Hybrid (Day Audit + Night Alert)";
int autoScanIntervalSeconds = 15; // Demo Camera Auto-Scan Interval

List> globalEnterpriseLogs = [
  {
    "time": "System Boot",
    "camera": "Master Hub",
    "event": "🛡️ Enterprise Security Hub Initialized Successfully in Hybrid Mode.",
    "videoPath": "N/A",
    "level": "Info"
  }
];

List<CameraDescription> globalAvailableCameras = [];

// ============================================================================
// 2. MAIN APPLICATION ENTRY POINT & THEME CONFIGURATION
// ============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    globalAvailableCameras = await availableCameras();
  } catch (e) {
    debugPrint("Hardware Camera Discovery Error: $e");
  }
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
  State<EnterpriseDashboardScreen> createState() =>
      _EnterpriseDashboardScreenState();
}

class _EnterpriseDashboardScreenState extends State<EnterpriseDashboardScreen> {
  double walletBalance = 2450.00;
  bool isSystemArmed = true;
  bool isAnalyzingAI = false;

  // --- RTSP VLC CONTROLLERS (FOR REAL CCTV CAMERAS) ---
  final Map<String, VlcPlayerController> _vlcControllers = {};

  // --- IN-APP DEMO CAMERA & AUTO-SCAN CONTROLLERS ---
  CameraController? _demoCameraController;
  bool _isDemoCameraInitialized = false;
  bool _isDemoCameraEnabled = true;
  int _selectedCameraIndex = 0;
  Timer? _autoScanTimer;
  String _lastDemoScanStatus = "Waiting for first auto-scan cycle...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRTSPStreams();
      _initializeInAppDemoCamera();
    });
  }

  // --------------------------------------------------------------------------
  // A. IN-APP DEMO CAMERA INITIALIZATION & ZERO-CLICK AUTO-SCANNER
  // --------------------------------------------------------------------------
  Future<void> _initializeInAppDemoCamera() async {
    _autoScanTimer?.cancel();
    if (_demoCameraController != null) {
      try {
        await _demoCameraController!.dispose();
      } catch (_) {}
      _demoCameraController = null;
    }

    if (!_isDemoCameraEnabled) {
      if (mounted) {
        setState(() {
          _isDemoCameraInitialized = false;
        });
      }
      return;
    }

    if (globalAvailableCameras.isEmpty) {
      try {
        globalAvailableCameras = await availableCameras();
      } catch (e) {
        debugPrint("Camera lookup error: $e");
      }
    }

    if (globalAvailableCameras.isEmpty) {
      if (mounted) {
        setState(() {
          _lastDemoScanStatus = "No built-in hardware camera found on device.";
        });
      }
      return;
    }

    if (_selectedCameraIndex >= globalAvailableCameras.length) {
      _selectedCameraIndex = 0;
    }

    _demoCameraController = CameraController(
      globalAvailableCameras[_selectedCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _demoCameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isDemoCameraInitialized = true;
        _lastDemoScanStatus = "Camera Active • Auto-Scanning every ${autoScanIntervalSeconds}s";
      });

      // Start immediate scan after 3 seconds of boot, then periodic auto-scan
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && isSystemArmed && _isDemoCameraEnabled && !isAnalyzingAI) {
          triggerDemoCameraAutoScan();
        }
      });

      _startAutoScanTimer();
    } catch (e) {
      debugPrint("Demo Camera Init Error: $e");
      if (mounted) {
        setState(() {
          _isDemoCameraInitialized = false;
          _lastDemoScanStatus = "Camera Error: $e";
        });
      }
    }
  }

  void _startAutoScanTimer() {
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(
      Duration(seconds: autoScanIntervalSeconds),
      (timer) {
        if (mounted &&
            isSystemArmed &&
            _isDemoCameraEnabled &&
            _isDemoCameraInitialized &&
            !isAnalyzingAI) {
          triggerDemoCameraAutoScan();
        }
      },
    );
  }

  void _switchDemoCameraLens() {
    if (globalAvailableCameras.length < 2) {
      _showAppSnackBar('Only 1 camera lens detected on this device.', Colors.amber);
      return;
    }
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % globalAvailableCameras.length;
      _isDemoCameraInitialized = false;
    });
    _initializeInAppDemoCamera();
  }

  // 👁️ ZERO-CLICK AUTO VISION SCANNER FOR IN-APP DEMO CAMERA
  Future<void> triggerDemoCameraAutoScan() async {
    if (!_isDemoCameraInitialized ||
        _demoCameraController == null ||
        !_demoCameraController!.value.isInitialized) {
      return;
    }

    if (_demoCameraController!.value.isTakingPicture) {
      return;
    }

    if (walletBalance < 0.75) {
      setState(() {
        _lastDemoScanStatus = "Paused: Insufficient Wallet Credits";
      });
      return;
    }

    if (globalGroqApiKey.trim().isEmpty) {
      setState(() {
        _lastDemoScanStatus = "Waiting for Groq API Key in Settings (⚙️)";
      });
      return;
    }

    if (mounted) {
      setState(() {
        isAnalyzingAI = true;
        _lastDemoScanStatus = "Capturing frame & scanning with Groq Vision...";
      });
    }

    try {
      XFile imageFile = await _demoCameraController!.takePicture();
      List<int> imageBytes = await imageFile.readAsBytes();

      if (imageBytes.isEmpty) {
        throw Exception("Empty frame captured from demo camera.");
      }

      String base64Image = base64Encode(imageBytes);
      String aiTextResponse = await _sendFrameToGroqVisionAPI(base64Image);

      String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
      String localSavedPath =
          "/storage/emulated/0/DCIM/FamilyCare_AutoDemo_$timeStamp.jpg";

      bool isThreatDetected = _detectThreatKeywords(aiTextResponse);

      if (mounted) {
        setState(() {
          walletBalance -= 0.75;
          _lastDemoScanStatus =
              "Last Scan (${_getCurrentFormattedTime()}): ${isThreatDetected ? 'THREAT ALERT' : 'Clear'}";
          globalEnterpriseLogs.insert(0, {
            "time": _getCurrentFormattedTime(),
            "camera": "In-App Demo Cam",
            "event": "🤖 Auto-Guard Scan: $aiTextResponse",
            "videoPath": localSavedPath,
            "level": isThreatDetected ? "High" : "Info"
          });
        });
      }
    } catch (e) {
      debugPrint("Demo Auto-Scan Error: $e");
      if (mounted) {
        setState(() {
          _lastDemoScanStatus = "Scan Retry Scheduled (${_getCurrentFormattedTime()})";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzingAI = false;
        });
      }
    }
  }

  // --------------------------------------------------------------------------
  // B. REAL CCTV RTSP STREAMS INITIALIZATION & SCANNER (VLC ENGINE INTACT)
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
          debugPrint("RTSP Stream Connection Error for $camName: $e");
        }
      }
    });
    if (mounted) setState(() {});
  }

  // 👁️ AI VISION SCANNER FOR RTSP CCTV NODES
  Future<void> triggerGroqVisionScan(String cameraName) async {
    if (walletBalance < 0.75) {
      _showAppSnackBar(
          '⚠️ Insufficient Wallet Balance! Please Top-Up ₹500.', Colors.orange);
      return;
    }

    if (globalGroqApiKey.trim().isEmpty) {
      _showAppSnackBar(
          '⚠️ Please enter your API Key in Settings (⚙️)!', Colors.redAccent);
      return;
    }

    setState(() {
      isAnalyzingAI = true;
    });

    try {
      VlcPlayerController? controller = _vlcControllers[cameraName];
      if (controller == null || !controller.value.isInitialized) {
        throw Exception(
            "Camera stream '$cameraName' is offline or uninitialized.");
      }

      var imageBytes = await controller.takeSnapshot();
      if (imageBytes.isEmpty) {
        throw Exception(
            "Failed to capture image frame snapshot from RTSP feed.");
      }

      String base64Image = base64Encode(imageBytes);
      String aiTextResponse = await _sendFrameToGroqVisionAPI(base64Image);

      String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
      String localSavedPath =
          "/storage/emulated/0/DCIM/FamilyCare_RTSP_$timeStamp.jpg";

      setState(() {
        walletBalance -= 0.75;
        globalEnterpriseLogs.insert(0, {
          "time": _getCurrentFormattedTime(),
          "camera": cameraName,
          "event": "🤖 CCTV Vision Scan: $aiTextResponse",
          "videoPath": localSavedPath,
          "level": "High"
        });
      });

      _showAppSnackBar(
          '🚨 RTSP AI Vision Scan Completed Successfully!', Colors.green);
    } catch (e) {
      _showAppSnackBar('❌ AI Scan Failed: $e', Colors.red, durationSeconds: 6);
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzingAI = false;
        });
      }
    }
  }

  // --------------------------------------------------------------------------
  // C. SHARED GROQ VISION API ENGINE & HELPER UTILITIES
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
          "No Threats Detected in Frame.";
    } else {
      throw Exception("Server Error (${response.statusCode}): ${response.body}");
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
        lower.contains("alert");
  }

  String _getCurrentOperationalShift() {
    int hour = DateTime.now().hour;
    if (hour >= 7 && hour < 20) {
      return "DAY MODE (Smart Hourly Audit)";
    } else {
      return "NIGHT MODE (Instant Motion Guard)";
    }
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    _demoCameraController?.dispose();
    for (var controller in _vlcControllers.values) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  void handleWalletTopUp() {
    setState(() {
      walletBalance += 500.0;
    });
    _showAppSnackBar(
        '✅ Successfully Added ₹500.00 to AI Credits Wallet.', Colors.lightBlue);
  }

  void toggleSystemArming() {
    setState(() {
      isSystemArmed = !isSystemArmed;
    });
    _showAppSnackBar(
      isSystemArmed
          ? '🔒 Security System ARMED & Auto-Scan Active'
          : '🔓 Security System Disarmed',
      isSystemArmed ? Colors.green : Colors.amber,
    );
  }

  String _getCurrentFormattedTime() {
    DateTime now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  }

  void _showAppSnackBar(String text, Color bg, {int durationSeconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: bg,
        duration: Duration(seconds: durationSeconds),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // D. UI BUILDER (DASHBOARD + IN-APP DEMO CAMERA + RTSP GRID + LOGS)
  // --------------------------------------------------------------------------
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Family Care VIP Command Center',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  Text(
                      isSystemArmed
                          ? 'ARMED • ${_getCurrentOperationalShift()}'
                          : 'STATUS: DISARMED',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isSystemArmed
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
                isSystemArmed
                    ? Icons.lock_outlined
                    : Icons.lock_open_rounded,
                color: isSystemArmed ? Colors.greenAccent : Colors.amberAccent),
            onPressed: toggleSystemArming,
            tooltip: 'Arm/Disarm System',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AiVideoChatSearchScreen()));
            },
            tooltip: 'AI Intelligence Chat',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EnterpriseSettingsScreen()));
              _initializeRTSPStreams();
              _startAutoScanTimer();
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
          await _initializeInAppDemoCamera();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. ENTERPRISE WALLET & SYSTEM METRICS BANNER ---
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                isAnalyzingAI
                                    ? 'AI SCANNING IN PROGRESS...'
                                    : 'ACTIVE AI CREDITS WALLET',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('₹${walletBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: handleWalletTopUp,
                          icon: const Icon(Icons.add_card_rounded,
                              color: Color(0xFF1E1B4B), size: 18),
                          label: const Text('Top-Up ₹500',
                              style: TextStyle(
                                  color: Color(0xFF1E1B4B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricChip(
                            Icons.videocam_rounded,
                            "${globalEnterpriseCameras.length + (_isDemoCameraEnabled ? 1 : 0)} Nodes",
                            "Active Feeds"),
                        _buildMetricChip(Icons.security_rounded,
                            "${globalEnterpriseLogs.length} Events", "Logged"),
                        _buildMetricChip(
                            Icons.memory_rounded,
                            activeVisionModel
                                .split('/')
                                .last
                                .split('-')
                                .first
                                .toUpperCase(),
                            "Vision Engine"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // --- 2. IN-APP AUTO-SCAN DEMO CAMERA SECTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.camera_enhance_rounded,
                          color: Colors.amberAccent, size: 18),
                      SizedBox(width: 6),
                      Text('Live Demo Camera (Zero-Click Auto Guard)',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.cameraswitch_rounded,
                            color: Colors.cyanAccent, size: 20),
                        tooltip: 'Switch Front/Back Camera',
                        onPressed: _switchDemoCameraLens,
                      ),
                      Switch(
                        value: _isDemoCameraEnabled,
                        activeColor: Colors.greenAccent,
                        onChanged: (val) {
                          setState(() {
                            _isDemoCameraEnabled = val;
                          });
                          _initializeInAppDemoCamera();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isAnalyzingAI
                          ? Colors.amberAccent
                          : Colors.greenAccent.withOpacity(0.5),
                      width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: !_isDemoCameraEnabled
                      ? const Center(
                          child: Text(
                            'Demo Camera Turned Off (Toggle switch above to start)',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        )
                      : _isDemoCameraInitialized &&
                              _demoCameraController != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(_demoCameraController!),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.75),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.fiber_manual_record,
                                            color: isAnalyzingAI
                                                ? Colors.amberAccent
                                                : Colors.redAccent,
                                            size: 10),
                                        const SizedBox(width: 5),
                                        Text(
                                            isAnalyzingAI
                                                ? 'AI SCANNING FRAME...'
                                                : 'AUTO-SCAN ACTIVE (${autoScanIntervalSeconds}s)',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    color: Colors.black.withOpacity(0.75),
                                    child: Text(
                                      _lastDemoScanStatus,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                      color: Colors.amberAccent),
                                  SizedBox(height: 10),
                                  Text('Starting Built-in Demo Camera...',
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 24),

              // --- 3. RTSP CAMERA NODES GRID (REAL CCTV SYSTEM INTACT) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Real CCTV RTSP Camera Nodes Grid',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('${globalEnterpriseCameras.length} RTSP Streams',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
              const SizedBox(height: 12),

              globalEnterpriseCameras.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        children: [
                          Icon(Icons.videocam_off_rounded,
                              size: 40, color: Colors.white38),
                          SizedBox(height: 10),
                          Text('No External CCTV RTSP Nodes Added Yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          SizedBox(height: 4),
                          Text(
                              'Tap Settings (⚙️) on top right to add CP Plus / Hikvision RTSP links anytime.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 16 / 13,
                      ),
                      itemCount: globalEnterpriseCameras.length,
                      itemBuilder: (context, index) {
                        String camName =
                            globalEnterpriseCameras.keys.elementAt(index);
                        VlcPlayerController? controller =
                            _vlcControllers[camName];
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
                                          placeholder:
                                              const CircularProgressIndicator(
                                                  color: Colors.amberAccent))
                                      : const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                                strokeWidth: 2),
                                            SizedBox(height: 8),
                                            Text('Connecting RTSP...',
                                                style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 10)),
                                          ],
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.fiber_manual_record,
                                          color: Colors.redAccent, size: 10),
                                      const SizedBox(width: 4),
                                      Text(camName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: isAnalyzingAI
                                      ? null
                                      : () => triggerGroqVisionScan(camName),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Colors.redAccent,
                                        Colors.deepOrange
                                      ]),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black45,
                                            blurRadius: 4)
                                      ],
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.remove_red_eye_rounded,
                                            color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('AI SCAN',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800)),
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

              // --- 4. ENTERPRISE THREAT INTELLIGENCE LOGS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enterprise Threat Intelligence Logs',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        globalEnterpriseLogs.clear();
                      });
                    },
                    child: const Text('Clear All',
                        style:
                            TextStyle(color: Colors.redAccent, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              globalEnterpriseLogs.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Text('No security logs recorded yet.',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
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
                                color: isHigh
                                    ? Colors.redAccent.withOpacity(0.6)
                                    : Colors.white10,
                                width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                          isHigh
                                              ? Icons.warning_amber_rounded
                                              : Icons.shield_outlined,
                                          color: isHigh
                                              ? Colors.redAccent
                                              : Colors.cyanAccent,
                                          size: 14),
                                      const SizedBox(width: 6),
                                      Text(log["camera"] ?? "Node",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ],
                                  ),
                                  Text(log["time"] ?? "",
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(log["event"] ?? "",
                                  style: TextStyle(
                                      color: isHigh
                                          ? Colors.red.shade100
                                          : Colors.white70,
                                      fontSize: 12)),
                              if (log["videoPath"] != null &&
                                  log["videoPath"] != "N/A") ...[
                                const SizedBox(height: 4),
                                Text("Evidence: ${log["videoPath"]}",
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 9)),
                              ]
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

  Widget _buildMetricChip(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: Colors.amberAccent, size: 20),
        const SizedBox(height: 4),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        Text(subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}

// ============================================================================
// 4. AI VIDEO & LOG INTELLIGENCE CHAT SEARCH SCREEN
// ============================================================================

class AiVideoChatSearchScreen extends StatefulWidget {
  const AiVideoChatSearchScreen({super.key});

  @override
  State<AiVideoChatSearchScreen> createState() =>
      _AiVideoChatSearchScreenState();
}

class _AiVideoChatSearchScreenState extends State<AiVideoChatSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List> _chatHistory = [
    {
      "role": "assistant",
      "content":
          "Hello! Ask me anything about your captured security logs, school monitoring reports, or suspicious activity timestamps."
    }
  ];
  bool _isSending = false;

  Future<void> _askSecurityAI() async {
    String userQuery = _queryController.text.trim();
    if (userQuery.isEmpty) return;

    if (globalGroqApiKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ Please add Groq API Key in Settings first!'),
            backgroundColor: Colors.redAccent),
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
              "content":
                  "You are the Family Care Enterprise Security Analyst AI. Answer user questions based on these security logs: $logsContext"
            },
            {"role": "user", "content": userQuery}
          ],
          "max_tokens": 500
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply =
            data['choices']?[0]['message']?['content'] ?? "No response.";
        setState(() {
          _chatHistory.add({"role": "assistant", "content": reply});
        });
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _chatHistory
            .add({"role": "assistant", "content": "Failed to fetch AI reply: $e"});
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
        title: const Text('AI Security Log Assistant',
            style: TextStyle(fontSize: 15)),
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
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF312E81)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(msg["content"] ?? "",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                );
              },
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Colors.amberAccent),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask about threats, time logs, or alerts...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      padding: const EdgeInsets.all(12)),
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
// 5. ENTERPRISE SETTINGS SCREEN (BYOK API KEY, PROMPT, RTSP NODES & TIMER)
// ============================================================================

class EnterpriseSettingsScreen extends StatefulWidget {
  const EnterpriseSettingsScreen({super.key});

  @override
  State<EnterpriseSettingsScreen> createState() =>
      _EnterpriseSettingsScreenState();
}

class _EnterpriseSettingsScreenState extends State<EnterpriseSettingsScreen> {
  final TextEditingController _apiKeyController =
      TextEditingController(text: globalGroqApiKey);
  final TextEditingController _promptController =
      TextEditingController(text: globalCustomAIPrompt);
  final TextEditingController _camNameController = TextEditingController();
  final TextEditingController _camIpController = TextEditingController();
  int _selectedInterval = autoScanIntervalSeconds;

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
      SnackBar(
          content: Text('✅ RTSP Node "$name" Added!'),
          backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Hub Settings & BYOK',
            style: TextStyle(fontSize: 15)),
        backgroundColor: const Color(0xFF1E1B4B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('1. Groq API Key (BYOK Model)',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
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
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          const Text('2. Auto-Scan Interval (Demo Camera Seconds)',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedInterval,
            dropdownColor: const Color(0xFF1E293B),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
            items: const [
              DropdownMenuItem(value: 10, child: Text('Every 10 Seconds (Fast Demo)')),
              DropdownMenuItem(value: 15, child: Text('Every 15 Seconds (Recommended)')),
              DropdownMenuItem(value: 30, child: Text('Every 30 Seconds (Battery Saver)')),
              DropdownMenuItem(value: 60, child: Text('Every 60 Seconds (1 Minute)')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedInterval = val;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          const Text('3. Custom AI Security & School Audit Prompt',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          const Text('4. Add Real CCTV RTSP Camera Stream (VLC Engine)',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 8),
          TextField(
            controller: _camNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Camera Name (e.g., Main Gate / Class 10A)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
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
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
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
            label: const Text('Add RTSP Camera Node',
                style: TextStyle(color: Colors.cyanAccent)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              globalGroqApiKey = _apiKeyController.text.trim();
              globalCustomAIPrompt = _promptController.text.trim();
              autoScanIntervalSeconds = _selectedInterval;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✅ All Enterprise Settings Saved!'),
                    backgroundColor: Colors.green),
              );
            },
            child: const Text('Save All Configuration',
                style: TextStyle(
                    color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
