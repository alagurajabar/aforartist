import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/firebase_service.dart';
import '../../models/project.dart';
import '../admin/admin_dashboard_view.dart';
import '../ar_camera/ar_camera_view.dart';
import '../project/sketch_editor_view.dart';
import '../widgets/glass_container.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Project> _projects = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _refreshProjects();
  }

  Future<void> _refreshProjects() async {
    setState(() => _isLoading = true);
    final projects = await DatabaseService.instance.getAllProjects();
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SketchEditorView(initialImage: image),
        ),
      ).then((_) => _refreshProjects());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<void> _deleteProject(String id) async {
    await DatabaseService.instance.deleteProject(id);
    _refreshProjects();
  }

  @override
  Widget build(BuildContext context) {
    final billing = Provider.of<BillingService>(context);
    final user = FirebaseService.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Block
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TraceAR Studio",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontFamily: GoogleFonts.outfit().fontFamily,
                          ),
                        ),
                        Text(
                          user != null ? "Welcome back, ${user.email}" : "Guest Creator",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    // Settings/Admin button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onSelected: (val) async {
                        if (val == 'admin') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminDashboardView()),
                          );
                        } else if (val == 'logout') {
                          await FirebaseService.instance.logout();
                          setState(() {});
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'admin',
                          child: Text("Admin Dashboard"),
                        ),
                        if (user != null)
                          const PopupMenuItem(
                            value: 'logout',
                            child: Text("Logout"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Upload Action Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: GlassContainer(
                          borderRadius: 16,
                          child: Column(
                            children: const [
                              Icon(Icons.photo_library, size: 36, color: AppTheme.accentCyan),
                              SizedBox(height: 8),
                              Text("Gallery Import", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickImage(ImageSource.camera),
                        child: GlassContainer(
                          borderRadius: 16,
                          child: Column(
                            children: const [
                              Icon(Icons.camera_alt, size: 36, color: AppTheme.accentBlue),
                              SizedBox(height: 8),
                              Text("Camera Snap", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Projects Section Label
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Your Tracing Projects", style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.sync, color: AppTheme.accentCyan),
                      onPressed: () async {
                        await FirebaseService.instance.syncLocalProjectsToCloud();
                        await FirebaseService.instance.downloadProjectsFromCloud();
                        _refreshProjects();
                      },
                    ),
                  ],
                ),
              ),

              // Projects List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _projects.isEmpty
                        ? const Center(
                            child: Text(
                              "No tracing templates found.\nClick Gallery or Camera above to begin.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _projects.length,
                            itemBuilder: (context, index) {
                              final proj = _projects[index];
                              return Dismissible(
                                key: Key(proj.id),
                                background: Container(
                                  color: AppTheme.errorRed,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) => _deleteProject(proj.id),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: GlassContainer(
                                    borderRadius: 14,
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(proj.localImagePath),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      title: Text(proj.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                        "Dimensions: ${proj.widthCm.toInt()}x${proj.heightCm.toInt()} cm",
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                                            onPressed: () => _deleteProject(proj.id),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.play_arrow, color: AppTheme.accentNeonGreen),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ARCameraView(project: proj),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
