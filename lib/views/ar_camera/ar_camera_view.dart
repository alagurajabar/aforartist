import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../core/constants/theme.dart';
import '../../models/project.dart';
import '../widgets/glass_container.dart';
import 'controls_panel.dart';
import '../settings/settings_view.dart';

class ARCameraView extends StatefulWidget {
  final Project project;
  const ARCameraView({Key? key, required this.project}) : super(key: key);

  @override
  _ARCameraViewState createState() => _ARCameraViewState();
}

class _ARCameraViewState extends State<ARCameraView> {
  // Mode Selection: AR Anchored vs 2D Overlay
  bool _useARMode = false; // Default to 2D Stencil overlay for maximum testability

  // 2D Stencil Transformations (Figma/Adobe Style)
  double _opacity = 0.5;
  double _scale = 1.0;
  double _rotation = 0.0;
  Offset _position = Offset.zero;
  bool _isLocked = false;
  bool _flipX = false;
  bool _flipY = false;

  // Gesture baseline tracking for smooth pinch-zoom
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _lastFocalPoint = Offset.zero;

  // Sensor state variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;
  double _accX = 0.0, _accY = 0.0, _accZ = 0.0;
  double _gyroX = 0.0, _gyroY = 0.0, _gyroZ = 0.0;
  double _widthCm = 30.0;
  double _heightCm = 20.0;
  
  // AR positioning variables
  double arHorizontal = 0.0;
  double arHeight = 0.0;
  double arDistance = -0.5; // Default to 50cm in front of camera
  bool _showSettings = true;
  bool _isVRMode = false;
  bool _isVRSplit = false; // New flag for split-screen VR

  // Grid & Professional Guides
  bool _gridEnabled = false;
  int _gridSize = 5;
  bool _centerGuideEnabled = false;
  bool _safeMarginEnabled = false;
  bool _symmetryEnabled = false;

  // AR Managers
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;
  List<ARAnchor> _anchors = [];
  List<ARNode> _nodes = [];

  // Camera controller for 2D overlay mode
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _opacity = widget.project.opacity;
    _widthCm = widget.project.widthCm;
    _heightCm = widget.project.heightCm;
    _flipX = widget.project.flipX;
    _flipY = widget.project.flipY;
    _isLocked = widget.project.isLocked;
    _gridEnabled = widget.project.gridEnabled;
    _gridSize = widget.project.gridSize;

    // Initialize camera for 2D overlay mode
    _initCamera();

        // Initialize sensor listeners
    _accelerometerSub = accelerometerEvents.listen((event) {
      setState(() {
        _accX = event.x;
        _accY = event.y;
        _accZ = event.z;
      });
    });
    _gyroscopeSub = gyroscopeEvents.listen((event) {
      setState(() {
        _gyroX = event.x;
        _gyroY = event.y;
        _gyroZ = event.z;
      });
      _applyARCalibration();
    });
    _prepareARModel();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _cameraReady = true;
          });
        }
      }
    } catch (e) {
      // Camera unavailable - show fallback
      debugPrint('Camera init failed: $e');
    }
  }

  Future<void> _prepareARModel() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final gltfFile = File('${docDir.path}/flat_plane.gltf');

      // Build binary mesh buffer
      final meshBytes = BytesBuilder();

      // Indices (6 unsigned 16-bit integers = 12 bytes)
      final indicesData = ByteData(12);
      indicesData.setUint16(0, 0, Endian.little);
      indicesData.setUint16(2, 1, Endian.little);
      indicesData.setUint16(4, 2, Endian.little);
      indicesData.setUint16(6, 0, Endian.little);
      indicesData.setUint16(8, 2, Endian.little);
      indicesData.setUint16(10, 3, Endian.little);
      meshBytes.add(indicesData.buffer.asUint8List());

      // Positions (4 vertices * 3 floats * 4 bytes = 48 bytes)
      // Vertices on XY plane (Z=0) so the quad stands VERTICAL like a wall
      final positionsData = ByteData(48);
      positionsData.setFloat32(0, -0.5, Endian.little);  // v0.x
      positionsData.setFloat32(4, -0.5, Endian.little);  // v0.y (bottom)
      positionsData.setFloat32(8, 0.0, Endian.little);   // v0.z
      positionsData.setFloat32(12, 0.5, Endian.little);  // v1.x
      positionsData.setFloat32(16, -0.5, Endian.little); // v1.y (bottom)
      positionsData.setFloat32(20, 0.0, Endian.little);  // v1.z
      positionsData.setFloat32(24, 0.5, Endian.little);  // v2.x
      positionsData.setFloat32(28, 0.5, Endian.little);  // v2.y (top)
      positionsData.setFloat32(32, 0.0, Endian.little);  // v2.z
      positionsData.setFloat32(36, -0.5, Endian.little); // v3.x
      positionsData.setFloat32(40, 0.5, Endian.little);  // v3.y (top)
      positionsData.setFloat32(44, 0.0, Endian.little);  // v3.z
      meshBytes.add(positionsData.buffer.asUint8List());

      // TexCoords (4 vertices * 2 floats * 4 bytes = 32 bytes)
      final texCoordsData = ByteData(32);
      texCoordsData.setFloat32(0, 0.0, Endian.little);
      texCoordsData.setFloat32(4, 1.0, Endian.little);
      texCoordsData.setFloat32(8, 1.0, Endian.little);
      texCoordsData.setFloat32(12, 1.0, Endian.little);
      texCoordsData.setFloat32(16, 1.0, Endian.little);
      texCoordsData.setFloat32(20, 0.0, Endian.little);
      texCoordsData.setFloat32(24, 0.0, Endian.little);
      texCoordsData.setFloat32(28, 0.0, Endian.little);
      meshBytes.add(texCoordsData.buffer.asUint8List());

      final meshBinaryBytes = meshBytes.toBytes();

      // 1. Write flat_plane.bin
      final binFile = File('${docDir.path}/flat_plane.bin');
      await binFile.writeAsBytes(meshBinaryBytes);

      // 2. Copy the source image file to stencil_texture.png
      final sourceFile = File(widget.project.localImagePath);
      final textureFile = File('${docDir.path}/stencil_texture.png');
      if (await sourceFile.exists()) {
        await sourceFile.copy(textureFile.path);
      }

      // Write the GLTF file with relative references to flat_plane.bin and stencil_texture.png
      final gltfContent = '''{
  "asset": {
    "version": "2.0"
  },
  "extensionsUsed": ["KHR_materials_unlit"],
  "scenes": [
    {
      "nodes": [0]
    }
  ],
  "nodes": [
    {
      "mesh": 0
    }
  ],
  "meshes": [
    {
      "primitives": [
        {
          "attributes": {
            "POSITION": 1,
            "TEXCOORD_0": 2
          },
          "indices": 0,
          "material": 0
        }
      ]
    }
  ],
  "materials": [
    {
      "pbrMetallicRoughness": {
        "baseColorTexture": {
          "index": 0
        },
        "metallicFactor": 0.0,
        "roughnessFactor": 1.0
      },
      "extensions": {
        "KHR_materials_unlit": {}
      },
      "alphaMode": "BLEND",
      "doubleSided": true
    }
  ],
  "textures": [
    {
      "sampler": 0,
      "source": 0
    }
  ],
  "images": [
    {
      "uri": "stencil_texture.png"
    }
  ],
  "samplers": [
    {
      "magFilter": 9729,
      "minFilter": 9987
    }
  ],
  "buffers": [
    {
      "uri": "flat_plane.bin",
      "byteLength": 92
    }
  ],
  "bufferViews": [
    {
      "buffer": 0,
      "byteOffset": 0,
      "byteLength": 12,
      "target": 34963
    },
    {
      "buffer": 0,
      "byteOffset": 12,
      "byteLength": 48,
      "target": 34962
    },
    {
      "buffer": 0,
      "byteOffset": 60,
      "byteLength": 32,
      "target": 34962
    }
  ],
  "accessors": [
    {
      "bufferView": 0,
      "byteOffset": 0,
      "componentType": 5123,
      "count": 6,
      "type": "SCALAR"
    },
    {
      "bufferView": 1,
      "byteOffset": 0,
      "componentType": 5126,
      "count": 4,
      "type": "VEC3",
      "max": [0.5, 0.5, 0.0],
      "min": [-0.5, -0.5, 0.0]
    },
    {
      "bufferView": 2,
      "byteOffset": 0,
      "componentType": 5126,
      "count": 4,
      "type": "VEC2"
    }
  ]
}''';
      await gltfFile.writeAsString(gltfContent);

      if (mounted) {
        setState(() {
          _modelReady = true;
        });
        _addNodeAutomatically();
      }
    } catch (e) {
      debugPrint('Failed to prepare AR model: $e');
    }
  }

  // Automatically place the AR node in front of the camera (without requiring plane detection tap)
  Future<void> _addNodeAutomatically() async {
    if (_arObjectManager == null || !_modelReady || _nodes.isNotEmpty) return;

    // Create a vertical quad node representing the wall stencil
    // Scale: X = width, Y = height, Z = 1 (flat plane on XY)
    final node = ARNode(
      type: NodeType.fileSystemAppFolderGLTF2,
      uri: "flat_plane.gltf",
      scale: vector.Vector3(_widthCm / 100.0, _heightCm / 100.0, 1.0),
      position: vector.Vector3(arHorizontal, arHeight, arDistance),
      rotation: vector.Vector4(0.0, 0.0, 0.0, 0.0),
    );

    final didAddNode = await _arObjectManager!.addNode(node);
    if (didAddNode != null && didAddNode) {
      if (mounted) {
        setState(() {
          _nodes.add(node);
        });
      }
    }
  }

  // Handle AR Session Creation
  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    _arAnchorManager = arAnchorManager;

    _arSessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: true,
    );
    _arObjectManager!.onInitialize();

    // Setup plane tap handler
    _arSessionManager!.onPlaneOrPointTap = _onPlaneTap;
    
    // Attempt automatic node placement
    _addNodeAutomatically();
  }

  // Handle taps on detected planes to anchor the virtual stencil
  Future<void> _onPlaneTap(List<ARHitTestResult> hitTestResults) async {
    if (_isLocked || hitTestResults.isEmpty || !_modelReady) return;

    // Remove existing anchors
    for (var anchor in _anchors) {
      _arAnchorManager!.removeAnchor(anchor);
    }
    _anchors.clear();
    _nodes.clear();

    final hit = hitTestResults.first;
    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    
    final didAddAnchor = await _arAnchorManager!.addAnchor(anchor);
    if (didAddAnchor != null && didAddAnchor) {
      _anchors.add(anchor);

      // Create a vertical quad node for wall stencil
      // Scale: X = width, Y = height, Z = 1 (flat plane on XY)
      final node = ARNode(
        type: NodeType.fileSystemAppFolderGLTF2,
        uri: "flat_plane.gltf",
        scale: vector.Vector3(_widthCm / 100.0, _heightCm / 100.0, 1.0),
        // Apply initial calibration offsets
        position: vector.Vector3(arHorizontal, arHeight, arDistance),
        rotation: vector.Vector4(0.0, 0.0, 0.0, 0.0),
      );

      final didAddNode = await _arObjectManager!.addNode(node, planeAnchor: anchor);
      if (didAddNode != null && didAddNode) {
        _nodes.add(node);
      }
    }
  }

  // Update physical dimensions dynamically
  void _updateDimensions(double w, double h) {
    setState(() {
      _widthCm = w;
      _heightCm = h;
    });

    if (_useARMode && _nodes.isNotEmpty) {
      // Modify AR Node scale (1 unit = 1 meter)
      final scaleVector = vector.Vector3(_widthCm / 100.0, 1.0, _heightCm / 100.0);
      for (var node in _nodes) {
        node.scale = scaleVector;
        _arObjectManager!.removeNode(node);
        _arObjectManager!.addNode(node); // Reload node to apply new scale
      }
    }
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    _cameraController?.dispose();
    // Cleanup sensor listeners
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Live Feed Camera (AR or 2D)
          _useARMode
              ? (_isVRMode
                  ? Row(
                      children: [
                        Expanded(
                          child: ARView(
                            onARViewCreated: _onARViewCreated,
                            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
                          ),
                        ),
                        Expanded(
                          child: ARView(
                            onARViewCreated: _onARViewCreated,
                            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
                          ),
                        ),
                      ],
                    )
                  : ARView(
                      onARViewCreated: _onARViewCreated,
                      planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
                    ))
              : Positioned.fill(
                  child: _cameraReady && _cameraController != null
                      ? CameraPreview(_cameraController!)
                      : Container(
                          color: Colors.black,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white54),
                                SizedBox(height: 12),
                                Text(
                                  "Starting camera...",
                                  style: TextStyle(color: Colors.white54, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

          // 2. Interactive 2D Stencil Overlay (fallback/manual tracing mode)
          if (!_useARMode)
            Positioned.fill(
              child: GestureDetector(
                onScaleStart: (details) {
                  if (_isLocked) return;
                  _baseScale = _scale;
                  _baseRotation = _rotation;
                  _lastFocalPoint = details.focalPoint;
                },
                onScaleUpdate: (details) {
                  if (_isLocked) return;
                  setState(() {
                    _scale = (_baseScale * details.scale).clamp(0.2, 5.0);
                    _rotation = _baseRotation + details.rotation;
                    _position += details.focalPoint - _lastFocalPoint;
                    _lastFocalPoint = details.focalPoint;
                  });
                },
                child: Stack(
                  children: [
                    Positioned(
                      left: MediaQuery.of(context).size.width / 2 + _position.dx - (_widthCm * _scale * 5) / 2,
                      top: MediaQuery.of(context).size.height / 2 + _position.dy - (_heightCm * _scale * 5) / 2,
                      width: _widthCm * _scale * 5,
                      height: _heightCm * _scale * 5,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..rotateZ(_rotation)
                          ..scale(_flipX ? -1.0 : 1.0, _flipY ? -1.0 : 1.0),
                        child: Opacity(
                          opacity: _opacity,
                          child: Stack(
                            children: [
                              Image.file(
                                File(widget.project.localImagePath),
                                fit: BoxFit.fill,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              // Visual guides inside stencil boundaries
                              if (_gridEnabled)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: GridPainter(divisions: _gridSize),
                                  ),
                                ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: RulerPainter(widthCm: _widthCm, heightCm: _heightCm),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Screen overlays (Guides outside stencil)
          if (_centerGuideEnabled)
            const Positioned.fill(
              child: IgnorePointer(
                child: CenterGuideOverlay(),
              ),
            ),
          if (_safeMarginEnabled)
            const Positioned.fill(
              child: IgnorePointer(
                child: SafeMarginOverlay(),
              ),
            ),
          if (_symmetryEnabled)
            const Positioned.fill(
              child: IgnorePointer(
                child: SymmetryOverlay(),
              ),
            ),

          // 4. Header Bar
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  widget.project.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
                // Toggle mode button
                ChoiceChip(
                  label: Text(_useARMode ? "3D AR Anchor" : "2D Screen Overlay", style: const TextStyle(fontSize: 12)),
                  selected: _useARMode,
                  selectedColor: AppTheme.accentBlue,
                  backgroundColor: AppTheme.surface.withOpacity(0.8),
                  onSelected: (val) {
                    setState(() {
                      _useARMode = val;
                    });
                  },
                ),
              ],
            ),
          ),

          // 5. Floating Controls Panel (with show/hide toggle)
          if (_showSettings)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: ARControlsPanel(
                opacity: _opacity,
                onOpacityChanged: (val) => setState(() => _opacity = val),
                isLocked: _isLocked,
                onLockChanged: (val) => setState(() => _isLocked = val),
                flipX: _flipX,
                onFlipXToggle: () => setState(() => _flipX = !_flipX),
                flipY: _flipY,
                onFlipYToggle: () => setState(() => _flipY = !_flipY),
                widthCm: _widthCm,
                heightCm: _heightCm,
                onDimensionsChanged: _updateDimensions,
                gridEnabled: _gridEnabled,
                onGridToggle: (val) => setState(() => _gridEnabled = val),
                gridSize: _gridSize,
                onGridSizeChanged: (val) => setState(() => _gridSize = val),
                centerGuideEnabled: _centerGuideEnabled,
                onCenterGuideToggle: (val) => setState(() => _centerGuideEnabled = val),
                safeMarginEnabled: _safeMarginEnabled,
                onSafeMarginToggle: (val) => setState(() => _safeMarginEnabled = val),
                symmetryEnabled: _symmetryEnabled,
                onSymmetryToggle: (val) => setState(() => _symmetryEnabled = val),
                useARMode: _useARMode,
                isAnchored: _anchors.isNotEmpty,
                arDistance: arDistance,
                arHeight: arHeight,
                arHorizontal: arHorizontal,
                onARDistanceChanged: _onARDistanceChanged,
                onARHeightChanged: _onARHeightChanged,
                onARHorizontalChanged: _onARHorizontalChanged,
                onHidePressed: () => setState(() => _showSettings = false),
                isVRMode: _isVRMode,
                onVRToggle: _toggleVRMode,
                onSettingsPressed: _openSettings,
                onAnchorPressed: _addNodeAutomatically,
                onReleaseAnchorPressed: _releaseAnchors,
              ),
            ),
          // Show settings button (visible when panel is hidden)
          if (!_showSettings)
            Positioned(
              bottom: 30,
              right: 16,
              child: FloatingActionButton.small(
                backgroundColor: AppTheme.accentBlue.withOpacity(0.8),
                onPressed: () => setState(() => _showSettings = true),
                child: const Icon(Icons.tune, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
  // Apply AR calibration offsets — remove and re-add nodes with updated position
  void _applyARCalibration() async {
    if (!_useARMode || _nodes.isEmpty || _arObjectManager == null) return;
    
    // Remove all existing nodes
    final oldNodes = List<ARNode>.from(_nodes);
    for (var node in oldNodes) {
      await _arObjectManager!.removeNode(node);
    }
    _nodes.clear();
    
    // Re-add with updated position
    final newNode = ARNode(
      type: NodeType.fileSystemAppFolderGLTF2,
      uri: "flat_plane.gltf",
      scale: vector.Vector3(_widthCm / 100.0, _heightCm / 100.0, 1.0),
      position: vector.Vector3(arHorizontal, arHeight, arDistance),
      rotation: vector.Vector4(0.0, 0.0, 0.0, 0.0),
    );
    
    final didAdd = await _arObjectManager!.addNode(newNode);
    if (didAdd != null && didAdd) {
      if (mounted) {
        setState(() {
          _nodes.add(newNode);
        });
      }
    }
  }

  // Release all anchors and nodes
  void _releaseAnchors() async {
    for (var anchor in _anchors) {
      _arAnchorManager?.removeAnchor(anchor);
    }
    for (var node in _nodes) {
      await _arObjectManager?.removeNode(node);
    }
    setState(() {
      _anchors.clear();
      _nodes.clear();
      arHorizontal = 0.0;
      arHeight = 0.0;
      arDistance = -0.5;
    });
  }

  // Sensor callback handlers for AR calibration
  void _onARDistanceChanged(double val) {
    setState(() {
      arDistance = val;
    });
    _applyARCalibration();
  }

  void _onARHeightChanged(double val) {
    setState(() {
      arHeight = val;
    });
    _applyARCalibration();
  }

  void _onARHorizontalChanged(double val) {
    setState(() {
      arHorizontal = val;
    });
    _applyARCalibration();
  }



  // Open Settings screen
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsView()),
    );
  }

  // Toggle simple VR Mode (single-view stereo effect)
  void _toggleVRMode() {
    setState(() {
      _isVRMode = !_isVRMode;
    });
  }

  // Toggle VR Split Screen Mode
  void _toggleVRSplitMode() {
    setState(() {
      _isVRSplit = !_isVRSplit;
      _isVRMode = true; // ensure VR mode enabled
    });
  }


}

// -------------------------------------------------------------
// CUSTOM PAINTERS FOR STENCIL OVERLAYS AND PROESSIONAL GUIDES
// -------------------------------------------------------------

class GridPainter extends CustomPainter {
  final int divisions;
  GridPainter({required this.divisions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentBlue.withOpacity(0.5)
      ..strokeWidth = 1.0;

    // Vertical lines
    final dx = size.width / divisions;
    for (int i = 1; i < divisions; i++) {
      canvas.drawLine(Offset(dx * i, 0), Offset(dx * i, size.height), paint);
    }

    // Horizontal lines
    final dy = size.height / divisions;
    for (int i = 1; i < divisions; i++) {
      canvas.drawLine(Offset(0, dy * i), Offset(size.width, dy * i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => oldDelegate.divisions != divisions;
}

class RulerPainter extends CustomPainter {
  final double widthCm;
  final double heightCm;
  RulerPainter({required this.widthCm, required this.heightCm});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final tickPaint = Paint()
      ..color = AppTheme.accentCyan.withOpacity(0.8)
      ..strokeWidth = 1.0;

    // Draw bounds border
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // Draw cm tick marks along horizontal and vertical borders
    final double pixelsPerCmX = size.width / widthCm;
    for (double i = 0; i <= widthCm; i += 1.0) {
      final x = i * pixelsPerCmX;
      final isMajor = i % 5 == 0;
      final tickLen = isMajor ? 12.0 : 6.0;
      
      // Top ruler
      canvas.drawLine(Offset(x, 0), Offset(x, tickLen), tickPaint);
      // Bottom ruler
      canvas.drawLine(Offset(x, size.height), Offset(x, size.height - tickLen), tickPaint);
    }

    final double pixelsPerCmY = size.height / heightCm;
    for (double i = 0; i <= heightCm; i += 1.0) {
      final y = i * pixelsPerCmY;
      final isMajor = i % 5 == 0;
      final tickLen = isMajor ? 12.0 : 6.0;

      // Left ruler
      canvas.drawLine(Offset(0, y), Offset(tickLen, y), tickPaint);
      // Right ruler
      canvas.drawLine(Offset(size.width, y), Offset(size.width - tickLen, y), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) =>
      oldDelegate.widthCm != widthCm || oldDelegate.heightCm != heightCm;
}

class CenterGuideOverlay extends StatelessWidget {
  const CenterGuideOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayLinePainter(
        color: AppTheme.accentCyan.withOpacity(0.6),
        isCross: true,
      ),
    );
  }
}

class SafeMarginOverlay extends StatelessWidget {
  const SafeMarginOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayLinePainter(
        color: AppTheme.errorRed.withOpacity(0.4),
        isMargin: true,
      ),
    );
  }
}

class SymmetryOverlay extends StatelessWidget {
  const SymmetryOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayLinePainter(
        color: AppTheme.accentNeonGreen.withOpacity(0.4),
        isSymmetry: true,
      ),
    );
  }
}

class _OverlayLinePainter extends CustomPainter {
  final Color color;
  final bool isCross;
  final bool isMargin;
  final bool isSymmetry;

  _OverlayLinePainter({
    required this.color,
    this.isCross = false,
    this.isMargin = false,
    this.isSymmetry = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    if (isCross) {
      // Draw center cross
      canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    }

    if (isMargin) {
      // Draw 5% safe margin borders
      final marginX = size.width * 0.05;
      final marginY = size.height * 0.05;
      final rect = Rect.fromLTRB(marginX, marginY, size.width - marginX, size.height - marginY);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.5;
      canvas.drawRect(rect, paint);
    }

    if (isSymmetry) {
      // Draw diagonal symmetry guide lines
      canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayLinePainter oldDelegate) => false;
}
