import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/theme.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/image_processor.dart';
import '../../models/project.dart';
import '../ar_camera/ar_camera_view.dart';
import '../widgets/glass_container.dart';

class SketchEditorView extends StatefulWidget {
  final XFile initialImage;
  const SketchEditorView({Key? key, required this.initialImage}) : super(key: key);

  @override
  _SketchEditorViewState createState() => _SketchEditorViewState();
}

class _SketchEditorViewState extends State<SketchEditorView> {
  final _nameController = TextEditingController(text: "Untitled Stencil");
  SketchFilter _selectedFilter = SketchFilter.none;
  double _intensity = 0.5;
  bool _removeBg = false;
  double _bgTolerance = 0.15;
  
  bool _isProcessing = false;
  String? _previewPath;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _previewPath = widget.initialImage.path;
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final outPath = '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png';

      final params = ImageProcessorParams(
        inputPath: widget.initialImage.path,
        outputPath: outPath,
        filter: _selectedFilter,
        intensity: _intensity,
        removeBackground: _removeBg,
        bgTolerance: _bgTolerance,
      );

      final resultPath = await ImageProcessor.processImage(params);

      setState(() {
        _previewPath = resultPath;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMsg = "Processing failed. Try another format.";
      });
      print(e);
    }
  }

  Future<void> _launchAR() async {
    if (_previewPath == null) return;

    // Create a permanent project directory in app storage
    final appDir = await getApplicationDocumentsDirectory();
    final projectId = const Uuid().v4();
    final permanentPath = '${appDir.path}/$projectId.png';
    
    // Copy the processed image there
    await File(_previewPath!).copy(permanentPath);

    final project = Project(
      id: projectId,
      name: _nameController.text.isNotEmpty ? _nameController.text : "Untitled Project",
      localImagePath: permanentPath,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Save in Database
    await DatabaseService.instance.createProject(project);

    // Trigger Cloud Sync in background
    FirebaseService.instance.syncLocalProjectsToCloud();

    if (!mounted) return;
    
    // Open AR View
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ARCameraView(project: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI Sketch Editor", style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkBackgroundGradient,
        ),
        child: Column(
          children: [
            // Preview Window
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: GlassContainer(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_previewPath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_previewPath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        if (_isProcessing)
                          const GlassContainer(
                            blur: 10,
                            borderRadius: 12,
                            child: CircularProgressIndicator(
                              color: AppTheme.accentBlue,
                            ),
                          ),
                        if (_errorMsg != null)
                          Text(
                            _errorMsg!,
                            style: const TextStyle(color: AppTheme.errorRed),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Controls Panel
            GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.black.withOpacity(0.4),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Project Name
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Project Name",
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Filter Selection
                    Text("Select Style Filter", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: SketchFilter.values.map((filter) {
                          final label = filter.toString().split('.').last;
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              selectedColor: AppTheme.accentBlue,
                              backgroundColor: AppTheme.surface,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                  _applyFilters();
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Intensity Slider
                    if (_selectedFilter != SketchFilter.none) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Filter Intensity", style: Theme.of(context).textTheme.bodyMedium),
                          Text("${(_intensity * 100).round()}%", style: const TextStyle(color: AppTheme.accentCyan)),
                        ],
                      ),
                      Slider(
                        value: _intensity,
                        onChanged: (val) {
                          setState(() {
                            _intensity = val;
                          });
                        },
                        onChangeEnd: (val) => _applyFilters(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Background Removal Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Remove Background (Color Key)", style: Theme.of(context).textTheme.bodyLarge),
                        Switch(
                          value: _removeBg,
                          activeColor: AppTheme.accentBlue,
                          onChanged: (val) {
                            setState(() {
                              _removeBg = val;
                            });
                            _applyFilters();
                          },
                        ),
                      ],
                    ),

                    if (_removeBg) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Chroma-Key Tolerance", style: Theme.of(context).textTheme.bodyMedium),
                          Text("${(_bgTolerance * 100).round()}%", style: const TextStyle(color: AppTheme.accentCyan)),
                        ],
                      ),
                      Slider(
                        value: _bgTolerance,
                        onChanged: (val) {
                          setState(() {
                            _bgTolerance = val;
                          });
                        },
                        onChangeEnd: (val) => _applyFilters(),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Process & Launch Buttons
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _launchAR,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppTheme.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            "Launch AR Tracing",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
