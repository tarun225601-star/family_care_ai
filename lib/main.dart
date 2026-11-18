import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// 1. GLOBAL ENTERPRISE STATE & DATA MODELS (ONLY QWEN ENGINE)
// ============================================================================

class SecurityIncidentLog {
  final String id;
  final String timestamp;
  final String cameraName;
  final String severity;
  final String aiAnalysis;
  final String snapshotUrl;
  final String? base64Evidence;

  SecurityIncidentLog({
    required this.id,
    required this.timestamp,
    required this.cameraName,
    required this.severity,
    required this.aiAnalysis,
    required this.snapshotUrl,
    this.base64Evidence,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'cameraName': cameraName,
        'severity': severity,
        'aiAnalysis': aiAnalysis,
        'snapshotUrl': snapshotUrl,
        'base64Evidence': base64Evidence,
      };

  factory SecurityIncidentLog.fromJson(Map<String, dynamic> json) {
    return SecurityIncidentLog(
      id: json['id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      cameraName: json['cameraName'] ?? '',
      severity: json['severity'] ?? 'INFO',
      aiAnalysis: json['aiAnalysis'] ?? '',
      snapshotUrl: json['snapshotUrl'] ?? '',
      base64Evidence: json['base64Evidence'],
    );
  }
}

class CameraNodeConfig {
  String id;
  String name;
  String streamUrl;
  String zone;
  bool isAiArmed;
  bool isLiveStreamMode;
  String lastStatus;
  String lastAiVerdict;
  Uint8List? lastFrameBytes; // Local motion tracking buffer

  CameraNodeConfig({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.zone = "ZONE-A",
    this.isAiArmed = true,
    this.isLiveStreamMode = true,
    this.lastStatus = "ONLINE",
    this.lastAiVerdict = "CLEAR",
    this.lastFrameBytes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'streamUrl': streamUrl,
        'zone': zone,
        'isAiArmed': isAiArmed,
        'isLiveStreamMode': isLiveStreamMode,
        'lastStatus': lastStatus,
        'lastAiVerdict': lastAiVerdict,
      };

  factory CameraNodeConfig.fromJson(Map<String, dynamic> json) {
    return CameraNodeConfig(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unnamed Cam',
      streamUrl: json['streamUrl'] ?? '',
      zone: json['zone'] ?? 'ZONE-A',
      isAiArmed: json['isAiArmed'] ?? true,
      isLiveStreamMode: json['isLiveStreamMode'] ?? true,
      lastStatus: json['lastStatus'] ?? 'ONLINE',
      lastAiVerdict: json['lastAiVerdict'] ?? 'CLEAR',
    );
  }
}

class EnterpriseVault {
  static String groqApiKey = "";
  static String qwenModelName = "qwen-2.5-vl-72b";
  static String masterSecurityPrompt =
      "Strict Security Audit: Inspect this CCTV frame ONLY for theft, shoplifting, forced entry, weapons, fire, or unauthorized person in restricted area. "
      "If everything is normal, reply strictly starting with 'STATUS: SAFE'. "
      "If any theft, intrusion, or threat is detected, reply strictly starting with 'STATUS: ALERT - ' followed by exact details of what is happening.";
  static String selectedLanguage = "English"; // Default language for logs & AI reply
  static double walletBalance = 1000.00;
  static int scanIntervalSeconds = 15;
  static bool autoWatchdogEnabled = false;
  static List<CameraNodeConfig> cameras = [];
  static List<SecurityIncidentLog> incidentLogs = [];

  static List<CameraNodeConfig> getDefaultEightCameras() {
    return [
      CameraNodeConfig(
        id: "CAM_01",
        name: "Cam 01 - Main Entrance",
        streamUrl: "https://picsum.photos/seed/gate01/800/450",
        zone: "PERIMETER",
      ),
      CameraNodeConfig(
        id: "CAM_02",
        name: "Cam 02 - Cash Counter",
        streamUrl: "https://picsum.photos/seed/cash02/800/450",
        zone: "HIGH-SECURITY",
      ),
      CameraNodeConfig(
        id: "CAM_03",
        name: "Cam 03 - Warehouse Bay",
        streamUrl: "https://picsum.photos/seed/store03/800/450",
        zone: "INVENTORY",
      ),
      CameraNodeConfig(
        id: "CAM_04",
        name: "Cam 04 - Outer Wall",
        streamUrl: "https://picsum.photos/seed/wall04/800/450",
        zone: "PERIMETER",
      ),
      CameraNodeConfig(
        id: "CAM_05",
        name: "Cam 05 - Server Vault",
        streamUrl: "https://picsum.photos/seed/vault05/800/450",
        zone: "RESTRICTED",
      ),
      CameraNodeConfig(
        id: "CAM_06",
        name: "Cam 06 - Parking Lot",
        streamUrl: "https://picsum.photos/seed/park06/800/450",
        zone: "EXTERIOR",
      ),
      CameraNodeConfig(
        id: "CAM_07",
        name: "Cam 07 - Reception",
        streamUrl: "https://picsum.photos/seed/lobby07/800/450",
        zone: "PUBLIC",
      ),
      CameraNodeConfig(
        id: "CAM_08",
        name: "Cam 08 - Rear Exit",
        streamUrl: "https://picsum.photos/seed/exit08/800/450",
        zone: "HIGH-SECURITY",
      ),
    ];
  }

  static Future<void> loadAllFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    groqApiKey = prefs.getString('ent_groq_key') ?? "";
    qwenModelName = prefs.getString('ent_qwen_model') ?? "qwen-2.5-vl-72b";
    masterSecurityPrompt =
        prefs.getString('ent_master_prompt') ?? masterSecurityPrompt;
    selectedLanguage = prefs.getString('ent_lang') ?? "English";
    walletBalance = prefs.getDouble('ent_wallet') ?? 1000.00;
    scanIntervalSeconds = prefs.getInt('ent_scan_interval') ?? 15;
    autoWatchdogEnabled = prefs.getBool('ent_watchdog') ?? false;

    String? camJson = prefs.getString('ent_cameras_list');
    if (camJson != null && camJson.isNotEmpty) {
      try {
        List<dynamic> decoded = jsonDecode(camJson);
        cameras = decoded.map((e) => CameraNodeConfig.fromJson(e)).toList();
      } catch (_) {
        cameras = getDefaultEightCameras();
      }
    } else {
      cameras = getDefaultEightCameras();
    }

    String? logJson = prefs.getString('ent_incident_logs');
    if (logJson != null && logJson.isNotEmpty) {
      try {
        List<dynamic> decoded = jsonDecode(logJson);
        incidentLogs =
            decoded.map((e) => SecurityIncidentLog.fromJson(e)).toList();
      } catch (_) {
        incidentLogs = [];
      }
    }
  }

  static Future<void> saveAllToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ent_groq_key', groqApiKey);
    await prefs.setString('ent_qwen_model', qwenModelName);
    await prefs.setString('ent_master_prompt', masterSecurityPrompt);
    await prefs.setString('ent_lang', selectedLanguage);
    await prefs.setDouble('ent_wallet', walletBalance);
    await prefs.setInt('ent_scan_interval', scanIntervalSeconds);
    await prefs.setBool('ent_watchdog', autoWatchdogEnabled);

    String encodedCams = jsonEncode(cameras.map((c) => c.toJson()).toList());
    await prefs.setString('ent_cameras_list', encodedCams);

    if (incidentLogs.length > 50) {
      incidentLogs = incidentLogs.sublist(0, 50);
    }
    String encodedLogs =
        jsonEncode(incidentLogs.map((l) => l.toJson()).toList());
    await prefs.setString('ent_incident_logs', encodedLogs);
  }
}

// ============================================================================
// 2. QWEN REAL-TIME VISION ENGINE SERVICE (WITH MULTI-LANGUAGE SUPPORT)
// ============================================================================

class QwenVisionIntelligenceService {
  static Future inspectCameraFrame({
    required CameraNodeConfig camera,
    required bool isAutoWatchdog,
  }) async {
    if (EnterpriseVault.groqApiKey.trim().isEmpty ||
        !EnterpriseVault.groqApiKey.startsWith("gsk_")) {
      return {
        "success": false,
        "isThreat": false,
        "message":
            "Invalid or Missing Groq API Key (gsk_...). Configure in Settings.",
        "base64Image": null,
      };
    }

    try {
            String cleanUrl = camera.streamUrl.replaceAll('/video', '');
      if (!cleanUrl.endsWith('/shot.jpg')) {
        cleanUrl = cleanUrl.endsWith('/') ? '${cleanUrl}shot.jpg' : '$cleanUrl/shot.jpg';
      }

      final uri = Uri.parse(cleanUrl).replace(
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );


      final imgResponse =
          await http.get(uri).timeout(const Duration(seconds: 60));

      if (imgResponse.statusCode != 200 || imgResponse.bodyBytes.isNotEmpty == false) {
        return {
          "success": false,
          "isThreat": false,
          "message": "Stream Offline: HTTP ${imgResponse.statusCode}",
          "base64Image": null,
        };
      }

      Uint8List imageBytes = imgResponse.bodyBytes;
      camera.lastFrameBytes = imageBytes; // Update frame buffer for motion
      String base64Image = base64Encode(imageBytes);

      final groqUri =
          Uri.parse("https://api.groq.com/openai/v1/chat/completions");

      // Injecting Language preference into the prompt instruction
      String languageInstruction =
          "CRITICAL: Reply and write your complete analysis strictly in the following language: ${EnterpriseVault.selectedLanguage}.";

      final payload = {
        "model": EnterpriseVault.qwenModelName.trim(),
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text":
                    "Camera Location: ${camera.name} (${camera.zone}).\n$languageInstruction\nInstruction: ${EnterpriseVault.masterSecurityPrompt}"
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image",
                }
              }
            ]
          }
        ],
        "temperature": 0.1,
        "max_tokens": 250,
      };

      final aiResponse = await http
          .post(
            groqUri,
            headers: {
              "Authorization": "Bearer ${EnterpriseVault.groqApiKey.trim()}",
              "Content-Type": "application/json",
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (aiResponse.statusCode == 200) {
        final data = jsonDecode(aiResponse.body);
        String reply =
            data['choices'][0]['message']['content']?.toString().trim() ??
                "No response";

        if (EnterpriseVault.walletBalance >= 0.25) {
          EnterpriseVault.walletBalance -= 0.25;
        }

        String upperReply = reply.toUpperCase();
        bool threatDetected = upperReply.contains("STATUS: ALERT") ||
            upperReply.contains("THEFT") ||
            upperReply.contains("INTRUSION") ||
            upperReply.contains("UNAUTHORIZED") ||
            upperReply.contains("WEAPON") ||
            upperReply.contains("BREACH") ||
            upperReply.contains("खतरा") || // Hindi threat indicator
            upperReply.contains("چوری"); // Urdu/Punjabi threat indicator

        return {
          "success": true,
          "isThreat": threatDetected,
          "message": reply,
          "base64Image": base64Image,
        };
      } else {
        final errData = jsonDecode(aiResponse.body);
        String errMsg = errData['error']?['message'] ?? aiResponse.body;
        return {
          "success": false,
          "isThreat": false,
          "message": "Qwen API Error (${aiResponse.statusCode}): $errMsg",
          "base64Image": null,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "isThreat": false,
        "message": "Network/Timeout Exception: $e",
        "base64Image": null,
      };
    }
  }
}

// ============================================================================
// 3. MAIN APPLICATION ENTRY & THEME
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnterpriseVault.loadAllFromDisk();
  runApp(const EnterpriseCctvApp());
}

class EnterpriseCctvApp extends StatelessWidget {
  const EnterpriseCctvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCTV Qwen AI Command Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090D16),
        primaryColor: Colors.cyanAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111827),
          elevation: 2,
        ),
        cardColor: const Color(0xFF161F30),
      ),
      home: const MainCommandDashboard(),
    );
  }
}

// ============================================================================
// 4. LIVE STREAM FRAME WIDGET (LIVE MJPEG CCTV PLAYER)
// ============================================================================

class LiveCctvFeedRenderer extends StatelessWidget {
  final CameraNodeConfig camera;
  final bool isLiveTickEnabled;

  const LiveCctvFeedRenderer({
    super.key,
    required this.camera,
    required this.isLiveTickEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final activeUrl = camera.streamUrl.trim();
    if (activeUrl.isEmpty) {
      return const Center(
        child: Text("NO URL CONFIGURED",
            style: TextStyle(color: Colors.redAccent, fontSize: 10)),
      );
    }

        // वीडियो स्ट्रीम (Mjpeg) की बजाय ताज़ा स्नैपशॉट दिखाने का विजेट
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          activeUrl.replaceAll('/video', '').endsWith('/shot.jpg') 
              ? activeUrl.replaceAll('/video', '') 
              : '${activeUrl.replaceAll('/video', '')}/shot.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.videocam_off, size: 40, color: Colors.redAccent),
                  SizedBox(height: 8),
                  Text("Snapshot Stream Offline", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );

// ============================================================================
// 5. MAIN COMMAND DASHBOARD (24x7 MOTION-TRIGGERED SILENT GUARD)
// ============================================================================

class MainCommandDashboard extends StatefulWidget {
  const MainCommandDashboard({super.key});

  @override
  State<MainCommandDashboard> createState() => _MainCommandDashboardState();
}

class _MainCommandDashboardState extends State<MainCommandDashboard> {
  Timer? _motionWatchTimer;
  bool _isScanningAi = false;
  bool _liveVideoStreamActive = true;
  String _currentWatchdogStatusText = "24x7 SILENT AI GUARD STANDBY";
  final Set<String> _scanningCameraIds = {};

  @override
  void initState() {
    super.initState();
    _start24x7SilentMotionLoop();
  }

  @override
  void dispose() {
    _motionWatchTimer?.cancel();
    super.dispose();
  }

  // 24x7 Silent Motion Check (No API Cost until physical movement occurs)
  void _start24x7SilentMotionLoop() {
    _motionWatchTimer?.cancel();
    _motionWatchTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!EnterpriseVault.autoWatchdogEnabled || _isScanningAi || EnterpriseVault.cameras.isEmpty) return;

      List<CameraNodeConfig> armedCameras =
          EnterpriseVault.cameras.where((c) => c.isAiArmed).toList();
      if (armedCameras.isEmpty) return;

      for (var cam in armedCameras) {
        await _checkMotionAndWakeAi(cam);
      }
    });
  }

  Future<void> _checkMotionAndWakeAi(CameraNodeConfig cam) async {
    try {
      final snapUrl = cam.streamUrl.endsWith('/video')
          ? cam.streamUrl.replaceAll('/video', '/shot.jpg')
          : cam.streamUrl;

      final response =
          await http.get(Uri.parse(snapUrl)).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final currentBytes = response.bodyBytes;

        if (cam.lastFrameBytes == null) {
          cam.lastFrameBytes = currentBytes;
          return;
        }

        // Local pixel difference check (Zero API Cost)
        double diffPercent = _calculateFrameDifference(cam.lastFrameBytes!, currentBytes);
        cam.lastFrameBytes = currentBytes;

        // If motion exceeds 12% threshold, wake up Qwen AI
        if (diffPercent >= 5.0) {
          if (mounted) {
            setState(() {
              _currentWatchdogStatusText = "⚡ MOTION: ${cam.name} -> WAKING QWEN...";
            });
          }
          await _triggerAiForMotion(cam);
        } else {
          if (mounted) {
            setState(() {
              _currentWatchdogStatusText = "💤 24x7 GUARD ACTIVE (NO MOTION)";
            });
          }
        }
      }
    } catch (_) {}
  }

  double _calculateFrameDifference(Uint8List prev, Uint8List curr) {
    int minLen = prev.length < curr.length ? prev.length : curr.length;
    if (minLen == 0) return 0.0;
    int step = (minLen / 500).ceil();
    if (step < 1) step = 1;

    int changedSamples = 0;
    int totalSamples = 0;

    for (int i = 100; i < minLen - 100; i += step) {
      totalSamples++;
      if ((prev[i] - curr[i]).abs() > 25) {
        changedSamples++;
      }
    }
    if (totalSamples == 0) return 0.0;
    return (changedSamples / totalSamples) * 100.0;
  }

  Future<void> _triggerAiForMotion(CameraNodeConfig targetCam) async {
    if (_isScanningAi) return;
    _isScanningAi = true;

    if (mounted) {
      setState(() {
        _scanningCameraIds.add(targetCam.id);
      });
    }

    final result = await QwenVisionIntelligenceService.inspectCameraFrame(
      camera: targetCam,
      isAutoWatchdog: true,
    );

    if (mounted) {
      setState(() {
        _scanningCameraIds.remove(targetCam.id);
        _isScanningAi = false;
        _currentWatchdogStatusText =
            "Qwen Checked: ${targetCam.name} (${DateTime.now().toString().substring(11, 19)})";
      });
    }

    if (result["success"] == true) {
      bool isThreat = result["isThreat"] == true;
      String analysis = result["message"];
      targetCam.lastAiVerdict = isThreat ? "BREACH DETECTED!" : "SAFE";

      if (isThreat) {
        _handleSecurityBreachDetected(
          camera: targetCam,
          analysis: analysis,
          base64Clip: result["base64Image"],
        );
      }
      await EnterpriseVault.saveAllToDisk();
    }
  }

  Future<void> _manualInspectCamera(CameraNodeConfig camera) async {
    if (_scanningCameraIds.contains(camera.id)) return;

    setState(() {
      _scanningCameraIds.add(camera.id);
    });

    final result = await QwenVisionIntelligenceService.inspectCameraFrame(
      camera: camera,
      isAutoWatchdog: false,
    );

    if (!mounted) return;
    setState(() {
      _scanningCameraIds.remove(camera.id);
    });

    bool isThreat = result["isThreat"] == true;
    String analysis = result["message"];

    if (result["success"] == true && isThreat) {
      _handleSecurityBreachDetected(
        camera: camera,
        analysis: analysis,
        base64Clip: result["base64Image"],
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161F30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: result["success"] == true
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
            ),
          ),
          title: Row(
            children: [
              Icon(
                result["success"] == true
                    ? Icons.verified_user
                    : Icons.warning_amber,
                color: result["success"] == true
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Qwen Vision: ${camera.name}",
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Engine: ${EnterpriseVault.qwenModelName} | Lang: ${EnterpriseVault.selectedLanguage}\nActive Rule: ${EnterpriseVault.masterSecurityPrompt}",
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                ),
                const Divider(height: 16),
                Text(
                  analysis,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
      );
    }
    await EnterpriseVault.saveAllToDisk();
  }

  void _handleSecurityBreachDetected({
    required CameraNodeConfig camera,
    required String analysis,
    required String? base64Clip,
  }) {
    // 📳 HEAVY HAPTIC VIBRATION FEEDBACK & ALARM
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticFeedback.heavyImpact();
    });

    final newLog = SecurityIncidentLog(
      id: "INC-${DateTime.now().millisecondsSinceEpoch}",
      timestamp: DateTime.now().toString().substring(0, 19),
      cameraName: "${camera.name} [${camera.zone}]",
      severity: "CRITICAL",
      aiAnalysis: analysis,
      snapshotUrl: camera.streamUrl,
      base64Evidence: base64Clip,
    );

    setState(() {
      camera.lastAiVerdict = "ALERT LOGGED";
      EnterpriseVault.incidentLogs.insert(0, newLog);
    });

    EnterpriseVault.saveAllToDisk();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B0B0E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        title: Row(
          children: const [
            Icon(Icons.emergency_share, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "🚨 QWEN BREACH EVIDENCE EXTRACTED!",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Camera: ${camera.name}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              Text("Time: ${newLog.timestamp}",
                  style: const TextStyle(fontSize: 10, color: Colors.white70)),
              const SizedBox(height: 8),
              if (base64Clip != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(base64Clip),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  analysis,
                  style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ACKNOWLEDGE & VIEW LOGS",
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _openFullScreenCamera(CameraNodeConfig camera) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenCameraMonitor(
          camera: camera,
          onManualScan: () => _manualInspectCamera(camera),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    int threatCount = EnterpriseVault.incidentLogs
        .where((l) => l.severity == "CRITICAL")
        .length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CCTV QWEN COMMAND CENTER",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
            Text(
              "Model: ${EnterpriseVault.qwenModelName} • Lang: ${EnterpriseVault.selectedLanguage}",
              style: const TextStyle(fontSize: 9.5, color: Colors.cyanAccent),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _liveVideoStreamActive ? Icons.videocam : Icons.videocam_off,
              color: _liveVideoStreamActive ? Colors.greenAccent : Colors.grey,
              size: 20,
            ),
            tooltip: "Toggle Live Stream Mode",
            onPressed: () {
              setState(() {
                _liveVideoStreamActive = !_liveVideoStreamActive;
              });
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.security_update_warning,
                    color: Colors.amberAccent, size: 20),
                tooltip: "Extracted Breach Clips & Logs",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const IncidentLogsScreen()),
                  );
                  setState(() {});
                },
              ),
              if (threatCount > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$threatCount",
                      style: const TextStyle(
                          fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.cyanAccent, size: 20),
            tooltip: "Master Cloud & Qwen Suite",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MasterConfigurationScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF111827),
            child: Row(
              children: [
                Icon(
                  EnterpriseVault.autoWatchdogEnabled
                      ? Icons.radar
                      : Icons.shield_outlined,
                  color: EnterpriseVault.autoWatchdogEnabled
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "GUARD: $_currentWatchdogStatusText",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: EnterpriseVault.autoWatchdogEnabled
                          ? Colors.greenAccent
                          : Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  height: 26,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EnterpriseVault.autoWatchdogEnabled
                          ? Colors.redAccent
                          : Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () async {
                      setState(() {
                        EnterpriseVault.autoWatchdogEnabled =
                            !EnterpriseVault.autoWatchdogEnabled;
                      });
                      await EnterpriseVault.saveAllToDisk();
                    },
                    child: Text(
                      EnterpriseVault.autoWatchdogEnabled
                          ? "PAUSE GUARD"
                          : "ARM 24x7 GUARD",
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: EnterpriseVault.cameras.isEmpty
                ? const Center(
                    child: Text("No Cameras Added. Open Settings to Add.",
                        style: TextStyle(color: Colors.white54)))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.86,
                    ),
                    itemCount: EnterpriseVault.cameras.length,
                    itemBuilder: (context, index) {
                      final cam = EnterpriseVault.cameras[index];
                      final isScanning = _scanningCameraIds.contains(cam.id);

                      return GestureDetector(
                        onTap: () => _openFullScreenCamera(cam),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF161F30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isScanning
                                  ? Colors.amberAccent
                                  : (cam.lastAiVerdict == "ALERT LOGGED"
                                      ? Colors.redAccent
                                      : Colors.cyanAccent.withOpacity(0.35)),
                              width: isScanning ? 1.8 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 5),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cam.name,
                                        style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "LIVE ●",
                                        style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    LiveCctvFeedRenderer(
                                      camera: cam,
                                      isLiveTickEnabled:
                                          _liveVideoStreamActive,
                                    ),
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        color: Colors.black54,
                                        child: Text(
                                          cam.zone,
                                          style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.cyanAccent),
                                        ),
                                      ),
                                    ),
                                    if (isScanning)
                                      Container(
                                        color: Colors.black54,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.amberAccent,
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              "WAKING QWEN...",
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.amberAccent,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        color: Colors.black54,
                                        child: Text(
                                          "REC • ${DateTime.now().toString().substring(11, 19)}",
                                          style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.white70),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isScanning
                                        ? Colors.amber[800]
                                        : Colors.cyan[800],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(7),
                                        bottomRight: Radius.circular(7),
                                      ),
                                    ),
                                  ),
                                  onPressed: isScanning
                                      ? null
                                      : () => _manualInspectCamera(cam),
                                  icon: const Icon(Icons.document_scanner,
                                      size: 12),
                                  label: Text(
                                    isScanning
                                        ? "SCANNING..."
                                        : "QWEN VISION AUDIT",
                                    style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. FULL SCREEN CAMERA MONITOR
// ============================================================================

class FullScreenCameraMonitor extends StatefulWidget {
  final CameraNodeConfig camera;
  final VoidCallback onManualScan;

  const FullScreenCameraMonitor({
    super.key,
    required this.camera,
    required this.onManualScan,
  });

  @override
  State<FullScreenCameraMonitor> createState() =>
      _FullScreenCameraMonitorState();
}

class _FullScreenCameraMonitorState extends State<FullScreenCameraMonitor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.camera.name, style: const TextStyle(fontSize: 14)),
        actions: [
          Switch(
            value: widget.camera.isAiArmed,
            activeColor: Colors.greenAccent,
            onChanged: (val) async {
              setState(() {
                widget.camera.isAiArmed = val;
              });
              await EnterpriseVault.saveAllToDisk();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: LiveCctvFeedRenderer(
                    camera: widget.camera,
                    isLiveTickEnabled: true,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF111827),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Stream Endpoint: ${widget.camera.streamUrl}",
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: widget.onManualScan,
                        icon: const Icon(Icons.visibility),
                        label: const Text("RUN QWEN VISION AUDIT NOW",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
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
// 7. INCIDENT LOGS SCREEN
// ============================================================================

class IncidentLogsScreen extends StatefulWidget {
  const IncidentLogsScreen({super.key});

  @override
  State<IncidentLogsScreen> createState() => _IncidentLogsScreenState();
}

class _IncidentLogsScreenState extends State<IncidentLogsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Extracted Breach Clips & Logs",
            style: TextStyle(fontSize: 14)),
        actions: [
          if (EnterpriseVault.incidentLogs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: "Clear All Logs",
              onPressed: () async {
                setState(() {
                  EnterpriseVault.incidentLogs.clear();
                });
                await EnterpriseVault.saveAllToDisk();
              },
            ),
        ],
      ),
      body: EnterpriseVault.incidentLogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.verified_user,
                      size: 48, color: Colors.greenAccent),
                  SizedBox(height: 12),
                  Text(
                    "No Theft or Security Breaches Recorded",
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Qwen only logs clips when your prompt rules are violated.",
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: EnterpriseVault.incidentLogs.length,
              itemBuilder: (context, index) {
                final log = EnterpriseVault.incidentLogs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.cameraName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                  fontSize: 12),
                            ),
                            Text(
                              log.timestamp,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (log.base64Evidence != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(log.base64Evidence!),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          log.aiAnalysis,
                          style: const TextStyle(
                              fontSize: 11.5, color: Colors.amberAccent),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// 8. MASTER CONFIGURATION SCREEN (WITH LANGUAGE SELECTOR)
// ============================================================================

class MasterConfigurationScreen extends StatefulWidget {
  const MasterConfigurationScreen({super.key});

  @override
  State<MasterConfigurationScreen> createState() =>
      _MasterConfigurationScreenState();
}

class _MasterConfigurationScreenState extends State<MasterConfigurationScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _qwenModelController;
  late TextEditingController _promptController;
  final TextEditingController _newCamNameController = TextEditingController();
  final TextEditingController _newCamUrlController = TextEditingController();
  String _selectedZone = "HIGH-SECURITY";
  String _selectedLang = "English";

  final List<String> _availableZones = [
    "HIGH-SECURITY",
    "PERIMETER",
    "INVENTORY",
    "RESTRICTED",
    "PUBLIC",
  ];

  final List<String> _languagesList = [
    "English",
    "Hindi (हिन्दी)",
    "Punjabi (ਪੰਜਾਬੀ)",
    "Haryanvi (हरियाणवी)",
    "Spanglish / Hinglish",
  ];

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: EnterpriseVault.groqApiKey);
    _qwenModelController =
        TextEditingController(text: EnterpriseVault.qwenModelName);
    _promptController =
        TextEditingController(text: EnterpriseVault.masterSecurityPrompt);
    _selectedLang = EnterpriseVault.selectedLanguage;
  }

  Future<void> _saveEverythingAndExit() async {
    EnterpriseVault.groqApiKey = _apiKeyController.text.trim();
    EnterpriseVault.qwenModelName = _qwenModelController.text.trim().isEmpty
        ? "qwen-2.5-vl-72b"
        : _qwenModelController.text.trim();
    EnterpriseVault.masterSecurityPrompt = _promptController.text.trim();
    EnterpriseVault.selectedLanguage = _selectedLang;

    String camName = _newCamNameController.text.trim();
    String camUrl = _newCamUrlController.text.trim();

    if (camName.isNotEmpty && camUrl.isNotEmpty) {
      EnterpriseVault.cameras.add(
        CameraNodeConfig(
          id: "CAM_${DateTime.now().millisecondsSinceEpoch}",
          name: camName,
          streamUrl: camUrl,
          zone: _selectedZone,
        ),
      );
    }

    await EnterpriseVault.saveAllToDisk();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Qwen Model, Rules, Language & Cameras Saved!"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enterprise Cloud & Qwen Suite",
            style: TextStyle(fontSize: 14)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1. Groq API Key (gsk_...)",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: "Paste your Groq API Key here",
                filled: true,
                fillColor: const Color(0xFF161F30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            const Text("2. Qwen Model ID (Vision Preview + Chat)",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _qwenModelController,
              style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
              decoration: InputDecoration(
                hintText: "e.g. qwen-2.5-vl-72b",
                filled: true,
                fillColor: const Color(0xFF161F30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            const Text("3. AI Log Output Language (Hindi, Punjabi, English...)",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                    fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedLang,
              dropdownColor: const Color(0xFF161F30),
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161F30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _languagesList
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLang = val);
              },
            ),
            const SizedBox(height: 14),
            const Text(
                "4. Master Trigger Prompt (Defines When to Extract Clip)",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                    fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _promptController,
              maxLines: 4,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText:
                    "Specify exact theft/intrusion conditions to trigger clip extraction...",
                filled: true,
                fillColor: const Color(0xFF161F30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const Divider(height: 28),
            const Text("5. Add New Cloud CCTV Stream Node",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _newCamNameController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: "Camera Name (e.g. Cam 09 - Vault)",
                filled: true,
                fillColor: const Color(0xFF161F30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newCamUrlController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: "Live Snapshot / MJPEG Stream URL (https://...)",
                filled: true,
                fillColor: const Color(0xFF161F30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedZone,
              dropdownColor: const Color(0xFF161F30),
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                labelText: "Security Zone",
                filled: true,
                fillColor: const Color(0xFF161F30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _availableZones
                  .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedZone = val);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _saveEverythingAndExit,
              icon: const Icon(Icons.save_alt),
              label: const Text(
                "SAVE ALL SETTINGS & CAMERAS",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Active Camera Nodes (${EnterpriseVault.cameras.length})",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      EnterpriseVault.cameras =
                          EnterpriseVault.getDefaultEightCameras();
                    });
                    await EnterpriseVault.saveAllToDisk();
                  },
                  child: const Text("Reset 8 Default Cams",
                      style:
                          TextStyle(color: Colors.amberAccent, fontSize: 11)),
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: EnterpriseVault.cameras.length,
              itemBuilder: (context, index) {
                final c = EnterpriseVault.cameras[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.videocam,
                      color: Colors.cyanAccent, size: 18),
                  title: Text(c.name, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(c.streamUrl,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 18),
                    onPressed: () async {
                      setState(() {
                        EnterpriseVault.cameras.removeAt(index);
                      });
                      await EnterpriseVault.saveAllToDisk();
                    },
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
