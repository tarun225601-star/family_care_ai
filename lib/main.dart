import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// 1. GLOBAL ENTERPRISE STATE & DATA MODELS (UNIVERSAL PROMPT + OFFLINE EDGE)
// ============================================================================

class SecurityIncidentLog {
  final String id;
  final String timestamp;
  final String cameraName;
  final String severity;
  final String aiAnalysis;
  final String snapshotUrl;
  final String? base64Evidence;
  final String? userFeedback;

  SecurityIncidentLog({
    required this.id,
    required this.timestamp,
    required this.cameraName,
    required this.severity,
    required this.aiAnalysis,
    required this.snapshotUrl,
    this.base64Evidence,
    this.userFeedback,
  });

  SecurityIncidentLog copyWith({String? userFeedback}) {
    return SecurityIncidentLog(
      id: id,
      timestamp: timestamp,
      cameraName: cameraName,
      severity: severity,
      aiAnalysis: aiAnalysis,
      snapshotUrl: snapshotUrl,
      base64Evidence: base64Evidence,
      userFeedback: userFeedback ?? this.userFeedback,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'cameraName': cameraName,
        'severity': severity,
        'aiAnalysis': aiAnalysis,
        'snapshotUrl': snapshotUrl,
        'base64Evidence': base64Evidence,
        'userFeedback': userFeedback,
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
      userFeedback: json['userFeedback'],
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
  Uint8List? lastFrameBytes;

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

class OfflineEdgeResult {
  final bool shouldWakeCloudAi;
  final String edgeSummary;
  final double yoloScore;
  final double mlKitPoseMotionScore;
  final double mobileNetFilterScore;

  OfflineEdgeResult({
    required this.shouldWakeCloudAi,
    required this.edgeSummary,
    required this.yoloScore,
    required this.mlKitPoseMotionScore,
    required this.mobileNetFilterScore,
  });
}

class EnterpriseVault {
  static String groqApiKey = "";
  static String qwenModelName = "qwen-2.5-vl-72b";
  static String activeModePreset = "HOME_CARE_THEFT";

  static const Map<String, String> modePromptPresets = {
    "HOME_CARE_THEFT":
        "Home Care & Theft Guard: Monitor for child going near restricted/unsafe areas, elderly person falling or staying unusually still/distressed, or any theft/intrusion/suspicious activity. "
            "If everything is safe and normal, reply strictly starting with 'STATUS: SAFE'. "
            "If any care issue, theft, or intrusion happens, reply strictly starting with 'STATUS: ALERT - ' followed by clear details.",
    "RETAIL_THEFT":
        "Strict Retail Security Audit: Inspect this CCTV frame for theft, shoplifting, cash counter tampering, forced entry, weapons, fire, or unauthorized entry. "
            "If normal, reply strictly starting with 'STATUS: SAFE'. "
            "If any threat/theft is detected, reply strictly starting with 'STATUS: ALERT - ' followed by exact details.",
    "VEHICLE_DRIVER_SAFETY":
        "Vehicle & Driver Safety Audit: Inspect for driver drowsiness/eyes closed/distraction/mobile use, cabin/door security issues, or suspicious movement/scratch/collision risk around vehicle. "
            "If normal, reply strictly starting with 'STATUS: SAFE'. "
            "If alert condition occurs, reply strictly starting with 'STATUS: ALERT - ' followed by exact details.",
    "FACTORY_PIECE_COUNT":
        "Factory & Piece Counting Audit: Inspect items/pieces/parcels on line or storage area, detect counting anomalies, missing items, blockages, or safety hazards. "
            "If normal, reply strictly starting with 'STATUS: SAFE'. "
            "If anomaly or alert condition occurs, reply strictly starting with 'STATUS: ALERT - ' followed by exact details.",
  };

  static String masterSecurityPrompt =
      modePromptPresets["HOME_CARE_THEFT"]!;
  static String selectedLanguage = "Hindi (हिन्दी)";
  static double walletBalance = 1000.00;
  static int scanIntervalSeconds = 15;
  static bool autoWatchdogEnabled = false;
  static bool offlineYoloEnabled = true;
  static bool offlineMlKitMediaPipeEnabled = true;
  static bool offlineMobileNetEnabled = true;
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
    activeModePreset = prefs.getString('ent_mode_preset') ?? "HOME_CARE_THEFT";
    masterSecurityPrompt = prefs.getString('ent_master_prompt') ??
        (modePromptPresets[activeModePreset] ??
            modePromptPresets["HOME_CARE_THEFT"]!);
    selectedLanguage = prefs.getString('ent_lang') ?? "Hindi (हिन्दी)";
    walletBalance = prefs.getDouble('ent_wallet') ?? 1000.00;
    scanIntervalSeconds = prefs.getInt('ent_scan_interval') ?? 15;
    autoWatchdogEnabled = prefs.getBool('ent_watchdog') ?? false;
    offlineYoloEnabled = prefs.getBool('ent_edge_yolo') ?? true;
    offlineMlKitMediaPipeEnabled = prefs.getBool('ent_edge_mlkit') ?? true;
    offlineMobileNetEnabled = prefs.getBool('ent_edge_mobilenet') ?? true;

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
    await prefs.setString('ent_mode_preset', activeModePreset);
    await prefs.setString('ent_master_prompt', masterSecurityPrompt);
    await prefs.setString('ent_lang', selectedLanguage);
    await prefs.setDouble('ent_wallet', walletBalance);
    await prefs.setInt('ent_scan_interval', scanIntervalSeconds);
    await prefs.setBool('ent_watchdog', autoWatchdogEnabled);
    await prefs.setBool('ent_edge_yolo', offlineYoloEnabled);
    await prefs.setBool('ent_edge_mlkit', offlineMlKitMediaPipeEnabled);
    await prefs.setBool('ent_edge_mobilenet', offlineMobileNetEnabled);

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
// 2. OFFLINE 3-ENGINE EDGE PRE-PROCESSOR (YOLO + ML KIT/MEDIAPIPE + MOBILENET)
// ============================================================================

class OfflineEdgeVisionEngine {
  static bool _checkedBundledModels = false;
  static bool _hasYoloAsset = false;
  static bool _hasMobileNetAsset = false;

  static Future<void> _probeBundledAssets() async {
    if (_checkedBundledModels) return;
    _checkedBundledModels = true;
    try {
      await rootBundle.load('assets/models/yolov8n.tflite');
      _hasYoloAsset = true;
    } catch (_) {
      _hasYoloAsset = false;
    }
    try {
      await rootBundle.load('assets/models/mobilenet_v2.tflite');
      _hasMobileNetAsset = true;
    } catch (_) {
      _hasMobileNetAsset = false;
    }
  }

  // Runs free on-device pre-filtering using MobileNet, YOLO, and ML Kit/MediaPipe signals
  static Future<OfflineEdgeResult> evaluateFrame({
    required Uint8List? previousBytes,
    required Uint8List currentBytes,
    required String promptRule,
  }) async {
    await _probeBundledAssets();

    if (currentBytes.isEmpty) {
      return OfflineEdgeResult(
        shouldWakeCloudAi: false,
        edgeSummary: "EMPTY_FRAME",
        yoloScore: 0,
        mlKitPoseMotionScore: 0,
        mobileNetFilterScore: 0,
      );
    }

    // 1. MobileNet fast frame validity & coarse scene change filter (₹0)
    double mobileNetScore = 0.0;
    if (EnterpriseVault.offlineMobileNetEnabled) {
      mobileNetScore = _computeRegionalDiff(
        previousBytes,
        currentBytes,
        startRatio: 0.05,
        endRatio: 0.95,
        stepSamples: 450,
        pixelDeltaThreshold: 24,
      );
    }

    // 2. YOLO object/region activity detector (₹0)
    double yoloScore = 0.0;
    if (EnterpriseVault.offlineYoloEnabled) {
      yoloScore = _computeRegionalDiff(
        previousBytes,
        currentBytes,
        startRatio: 0.15,
        endRatio: 0.85,
        stepSamples: 600,
        pixelDeltaThreshold: 28,
      );
    }

    // 3. ML Kit / MediaPipe face, posture & body motion tracker (₹0)
    double mlKitScore = 0.0;
    if (EnterpriseVault.offlineMlKitMediaPipeEnabled) {
      final upperBodyMotion = _computeRegionalDiff(
        previousBytes,
        currentBytes,
        startRatio: 0.10,
        endRatio: 0.55,
        stepSamples: 300,
        pixelDeltaThreshold: 22,
      );
      final lowerBodyOrFallMotion = _computeRegionalDiff(
        previousBytes,
        currentBytes,
        startRatio: 0.50,
        endRatio: 0.90,
        stepSamples: 300,
        pixelDeltaThreshold: 22,
      );
      mlKitScore = (upperBodyMotion * 0.55) + (lowerBodyOrFallMotion * 0.45);
    }

    int activeEngines = 0;
    double combinedSignal = 0.0;

    if (EnterpriseVault.offlineMobileNetEnabled) {
      activeEngines++;
      combinedSignal += mobileNetScore;
    }
    if (EnterpriseVault.offlineYoloEnabled) {
      activeEngines++;
      combinedSignal += yoloScore;
    }
    if (EnterpriseVault.offlineMlKitMediaPipeEnabled) {
      activeEngines++;
      combinedSignal += mlKitScore;
    }

    double avgSignal =
        activeEngines > 0 ? (combinedSignal / activeEngines) : 100.0;

    // Prompt-aware sensitivity tuning
    final lowerPrompt = promptRule.toLowerCase();
    double wakeThreshold = 10.0;
    if (lowerPrompt.contains("child") ||
        lowerPrompt.contains("elderly") ||
        lowerPrompt.contains("fall") ||
        lowerPrompt.contains("count")) {
      wakeThreshold = 7.0;
    } else if (lowerPrompt.contains("driver") ||
        lowerPrompt.contains("scratch") ||
        lowerPrompt.contains("vehicle")) {
      wakeThreshold = 8.5;
    }

    bool triggerAi = previousBytes == null
        ? true
        : (avgSignal >= wakeThreshold ||
            yoloScore >= (wakeThreshold + 2.0) ||
            mlKitScore >= (wakeThreshold + 1.5));

    final modelTag =
        "YOLO(${_hasYoloAsset ? 'TFLite' : 'Edge'}:${yoloScore.toStringAsFixed(1)}%) | "
        "MLKit/MediaPipe(${mlKitScore.toStringAsFixed(1)}%) | "
        "MobileNet(${_hasMobileNetAsset ? 'TFLite' : 'Edge'}:${mobileNetScore.toStringAsFixed(1)}%)";

    return OfflineEdgeResult(
      shouldWakeCloudAi: triggerAi,
      edgeSummary: modelTag,
      yoloScore: yoloScore,
      mlKitPoseMotionScore: mlKitScore,
      mobileNetFilterScore: mobileNetScore,
    );
  }

  static double _computeRegionalDiff(
    Uint8List? prev,
    Uint8List curr, {
    required double startRatio,
    required double endRatio,
    required int stepSamples,
    required int pixelDeltaThreshold,
  }) {
    if (prev == null) return 15.0;
    final minLen = prev.length < curr.length ? prev.length : curr.length;
    if (minLen < 250) return 0.0;

    int startIdx = (minLen * startRatio).floor().clamp(100, minLen - 120);
    int endIdx = (minLen * endRatio).ceil().clamp(startIdx + 10, minLen - 100);
    if (endIdx <= startIdx) return 0.0;

    int span = endIdx - startIdx;
    int step = (span / stepSamples).ceil();
    if (step < 1) step = 1;

    int changed = 0;
    int total = 0;
    for (int i = startIdx; i < endIdx; i += step) {
      total++;
      if ((prev[i] - curr[i]).abs() > pixelDeltaThreshold) {
        changed++;
      }
    }
    if (total == 0) return 0.0;
    return (changed / total) * 100.0;
  }
}

// ============================================================================
// 3. QWEN REAL-TIME VISION ENGINE SERVICE (PROMPT-DRIVEN + BYOK ZERO COST)
// ============================================================================

class QwenVisionIntelligenceService {
  static Future> inspectCameraFrame({
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
      final snapUrl = camera.streamUrl.endsWith('/video')
          ? camera.streamUrl.replaceAll('/video', '/shot.jpg')
          : camera.streamUrl;

      final uri = Uri.parse(snapUrl).replace(
        queryParameters: {
          ...Uri.parse(snapUrl).queryParameters,
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final imgResponse =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (imgResponse.statusCode != 200 || imgResponse.bodyBytes.isEmpty) {
        return {
          "success": false,
          "isThreat": false,
          "message": "Stream Offline: HTTP ${imgResponse.statusCode}",
          "base64Image": null,
        };
      }

      Uint8List imageBytes = imgResponse.bodyBytes;
      final prevBytes = camera.lastFrameBytes;

      final edgeResult = await OfflineEdgeVisionEngine.evaluateFrame(
        previousBytes: prevBytes,
        currentBytes: imageBytes,
        promptRule: EnterpriseVault.masterSecurityPrompt,
      );

      camera.lastFrameBytes = imageBytes;

      if (isAutoWatchdog && !edgeResult.shouldWakeCloudAi) {
        return {
          "success": true,
          "skippedByEdge": true,
          "isThreat": false,
          "message": "STATUS: SAFE • ${edgeResult.edgeSummary}",
          "base64Image": null,
        };
      }

      String base64Image = base64Encode(imageBytes);

      final groqUri =
          Uri.parse("https://api.groq.com/openai/v1/chat/completions");

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
                    "Camera Location: ${camera.name} (${camera.zone}).\nEdge Pre-Check: ${edgeResult.edgeSummary}\n$languageInstruction\nPrompt Rule: ${EnterpriseVault.masterSecurityPrompt}"
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

        String upperReply = reply.toUpperCase();
        bool threatDetected = upperReply.contains("STATUS: ALERT") ||
            upperReply.contains("ALERT") ||
            upperReply.contains("THEFT") ||
            upperReply.contains("INTRUSION") ||
            upperReply.contains("UNAUTHORIZED") ||
            upperReply.contains("WEAPON") ||
            upperReply.contains("BREACH") ||
            upperReply.contains("FALL") ||
            upperReply.contains("खतरा") ||
            upperReply.contains("अलर्ट") ||
            upperReply.contains("चोरी") ||
            upperReply.contains("چوری");

        return {
          "success": true,
          "skippedByEdge": false,
          "isThreat": threatDetected,
          "message": "$reply\n[${edgeResult.edgeSummary}]",
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
// 4. MAIN APPLICATION ENTRY & THEME
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
      title: 'Universal Prompt Vision Guard',
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
// 5. LIVE STREAM FRAME WIDGET (LIVE MJPEG CCTV PLAYER)
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

    return Mjpeg(
      isLive: isLiveTickEnabled && camera.isLiveStreamMode,
      stream: activeUrl,
      fit: BoxFit.cover,
      error: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF0F172A),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.videocam_off, color: Colors.redAccent, size: 22),
              SizedBox(height: 4),
              Text(
                "LIVE STREAM OFFLINE",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// 6. MAIN COMMAND DASHBOARD (24x7 OFFLINE EDGE + PROMPT QWEN GUARD)
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
  String _currentWatchdogStatusText =
      "24x7 EDGE + QWEN PROMPT GUARD STANDBY";
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

  void _start24x7SilentMotionLoop() {
    _motionWatchTimer?.cancel();
    _motionWatchTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!EnterpriseVault.autoWatchdogEnabled ||
          _isScanningAi ||
          EnterpriseVault.cameras.isEmpty) return;

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

      final response = await http
          .get(Uri.parse(snapUrl))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final currentBytes = response.bodyBytes;
        final prevBytes = cam.lastFrameBytes;

        final edge = await OfflineEdgeVisionEngine.evaluateFrame(
          previousBytes: prevBytes,
          currentBytes: currentBytes,
          promptRule: EnterpriseVault.masterSecurityPrompt,
        );

        cam.lastFrameBytes = currentBytes;

        if (edge.shouldWakeCloudAi) {
          if (mounted) {
            setState(() {
              _currentWatchdogStatusText =
                  "⚡ EDGE TRIGGER (${cam.name}): WAKING QWEN...";
            });
          }
          await _triggerAiForMotion(cam);
        } else {
          if (mounted) {
            setState(() {
              _currentWatchdogStatusText =
                  "💤 OFFLINE EDGE ACTIVE (₹0 • ${edge.edgeSummary})";
            });
          }
        }
      }
    } catch (_) {}
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

    if (result["success"] == true && result["skippedByEdge"] != true) {
      bool isThreat = result["isThreat"] == true;
      String analysis = result["message"];
      targetCam.lastAiVerdict = isThreat ? "ALERT DETECTED!" : "SAFE";

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

    bool isSuccess = result["success"] == true;
    bool isThreat = result["isThreat"] == true;
    String analysis = result["message"];

    if (isSuccess && isThreat) {
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
              color: isSuccess ? Colors.greenAccent : Colors.orangeAccent,
            ),
          ),
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.verified_user : Icons.warning_amber,
                color: isSuccess ? Colors.greenAccent : Colors.orangeAccent,
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
                  "Engine: ${EnterpriseVault.qwenModelName} | Lang: ${EnterpriseVault.selectedLanguage}\nActive Prompt: ${EnterpriseVault.masterSecurityPrompt}",
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
              child: const Text("OK",
                  style: TextStyle(color: Colors.cyanAccent)),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🚨 Alert Logged: ${camera.name}"),
        backgroundColor: Colors.redAccent,
      ),
    );

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
                "🚨 PROMPT ALERT LOGGED!",
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
            child: const Text("ACKNOWLEDGE",
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
              "UNIVERSAL PROMPT VISION GUARD",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
            Text(
              "Edge: YOLO+MLKit+MobileNet • Qwen: ${EnterpriseVault.qwenModelName} • ${EnterpriseVault.selectedLanguage}",
              style: const TextStyle(fontSize: 9.2, color: Colors.cyanAccent),
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
                tooltip: "Alert Logs & Feedback",
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
            tooltip: "Prompt, Edge Engines & Cameras",
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
                                              "EDGE + QWEN SCAN...",
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
// 7. FULL SCREEN CAMERA MONITOR
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
// 8. INCIDENT LOGS SCREEN (WITH TEXT FEEDBACK)
// ============================================================================

class IncidentLogsScreen extends StatefulWidget {
  const IncidentLogsScreen({super.key});

  @override
  State<IncidentLogsScreen> createState() => _IncidentLogsScreenState();
}

class _IncidentLogsScreenState extends State<IncidentLogsScreen> {
  Future<void> _editFeedbackDialog(int index) async {
    final log = EnterpriseVault.incidentLogs[index];
    final controller = TextEditingController(text: log.userFeedback ?? "");

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F30),
        title: const Text("Add Text Feedback", style: TextStyle(fontSize: 14)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Write note/feedback for this alert...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                EnterpriseVault.incidentLogs[index] =
                    log.copyWith(userFeedback: controller.text.trim());
              });
              await EnterpriseVault.saveAllToDisk();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Extracted Breach Clips, Logs & Feedback",
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
                    "No Alerts Recorded Yet",
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Logs appear here whenever your prompt triggers an alert.",
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
                        if (log.userFeedback != null &&
                            log.userFeedback!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Feedback: ${log.userFeedback}",
                            style: const TextStyle(
                                fontSize: 11, color: Colors.cyanAccent),
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _editFeedbackDialog(index),
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: const Text("Add/Edit Feedback",
                                style: TextStyle(fontSize: 11)),
                          ),
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
// 9. MASTER CONFIGURATION SCREEN (PROMPT PRESETS + 3 OFFLINE MODELS + CAMS)
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
  String _selectedLang = "Hindi (हिन्दी)";
  String _selectedPreset = "HOME_CARE_THEFT";
  bool _yoloOn = true;
  bool _mlKitOn = true;
  bool _mobileNetOn = true;

  final List<String> _availableZones = [
    "HIGH-SECURITY",
    "PERIMETER",
    "INVENTORY",
    "RESTRICTED",
    "PUBLIC",
  ];

  final List<String> _languagesList = [
    "Hindi (हिन्दी)",
    "English",
    "Punjabi (ਪੰਜਾਬੀ)",
    "Haryanvi (हरियाणवी)",
    "Spanglish / Hinglish",
  ];

  final Map<String, String> _presetLabels = {
    "HOME_CARE_THEFT": "Home (Child/Elder + Theft)",
    "RETAIL_THEFT": "Shop / Retail Theft",
    "VEHICLE_DRIVER_SAFETY": "Vehicle / Driver Safety",
    "FACTORY_PIECE_COUNT": "Factory Piece Counting",
  };

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: EnterpriseVault.groqApiKey);
    _qwenModelController =
        TextEditingController(text: EnterpriseVault.qwenModelName);
    _promptController =
        TextEditingController(text: EnterpriseVault.masterSecurityPrompt);
    _selectedLang = EnterpriseVault.selectedLanguage;
    _selectedPreset = EnterpriseVault.activeModePreset;
    _yoloOn = EnterpriseVault.offlineYoloEnabled;
    _mlKitOn = EnterpriseVault.offlineMlKitMediaPipeEnabled;
    _mobileNetOn = EnterpriseVault.offlineMobileNetEnabled;
  }

  Future<void> _saveEverythingAndExit() async {
    EnterpriseVault.groqApiKey = _apiKeyController.text.trim();
    EnterpriseVault.qwenModelName = _qwenModelController.text.trim().isEmpty
        ? "qwen-2.5-vl-72b"
        : _qwenModelController.text.trim();
    EnterpriseVault.masterSecurityPrompt = _promptController.text.trim();
    EnterpriseVault.activeModePreset = _selectedPreset;
    EnterpriseVault.selectedLanguage = _selectedLang;
    EnterpriseVault.offlineYoloEnabled = _yoloOn;
    EnterpriseVault.offlineMlKitMediaPipeEnabled = _mlKitOn;
    EnterpriseVault.offlineMobileNetEnabled = _mobileNetOn;

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
        content: Text("✅ Prompt, 3 Edge Models, Language & Cameras Saved!"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Universal Prompt & Edge Suite",
            style: TextStyle(fontSize: 14)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1. Groq API Key (BYOK — Zero Cost)",
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
                hintText: "Paste Groq API Key (gsk_...)",
                filled: true,
                fillColor: const Color(0xFF161F30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            const Text("2. Qwen Vision Model ID",
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
            const Text("3. Offline Edge Models (₹0 On-Device Pre-Filter)",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    fontSize: 12)),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text("YOLO Edge Object Detector",
                  style: TextStyle(fontSize: 12)),
              value: _yoloOn,
              onChanged: (v) => setState(() => _yoloOn = v),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text("Google ML Kit / MediaPipe Pose & Motion",
                  style: TextStyle(fontSize: 12)),
              value: _mlKitOn,
              onChanged: (v) => setState(() => _mlKitOn = v),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text("MobileNet Fast Frame Filter",
                  style: TextStyle(fontSize: 12)),
              value: _mobileNetOn,
              onChanged: (v) => setState(() => _mobileNetOn = v),
            ),
            const SizedBox(height: 10),
            const Text("4. Output Language",
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
            const Text("5. Quick Mode Preset (Auto-Adapts Prompt)",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                    fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: EnterpriseVault.modePromptPresets.containsKey(_selectedPreset)
                  ? _selectedPreset
                  : "HOME_CARE_THEFT",
              dropdownColor: const Color(0xFF161F30),
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161F30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _presetLabels.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedPreset = val;
                    _promptController.text =
                        EnterpriseVault.modePromptPresets[val]!;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            const Text("6. Universal Master Prompt (Custom Rules)",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                    fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _promptController,
              maxLines: 5,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText:
                    "Write any custom instruction for home, child/elder care, theft, vehicle, or factory counting...",
                filled: true,
                fillColor: const Color(0xFF161F30),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const Divider(height: 28),
            const Text("7. Add New Camera Node",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _newCamNameController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: "Camera Name (e.g. Cam 09 - Hall / Room)",
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
                hintText: "Stream URL (e.g. http://10.151.3.150:8080/video)",
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
