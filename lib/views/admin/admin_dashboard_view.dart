import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../widgets/glass_container.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({Key? key}) : super(key: key);

  @override
  _AdminDashboardViewState createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  // Mock Metrics Data
  final int totalUsers = 12450;
  final int activeSubscribers = 1432;
  final double monthlyRevenue = 7160.00;
  final int totalProjects = 43210;
  final int totalSketchConversions = 18940;
  final int totalBgRemovals = 12400;

  // Mock User List for User Management
  final List<Map<String, dynamic>> mockUsers = [
    {"email": "artist101@gmail.com", "tier": "Premium", "projects": 42, "status": "Active"},
    {"email": "ink_and_skin@tattoo.org", "tier": "Premium", "projects": 128, "status": "Active"},
    {"email": "muralist_john@yahoo.com", "tier": "Free", "projects": 4, "status": "Active"},
    {"email": "hobbyist_alice@icloud.com", "tier": "Free", "projects": 1, "status": "Inactive"},
    {"email": "architect_build@studio.co", "tier": "Premium", "projects": 94, "status": "Active"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Operations Center"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkBackgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section: Overview Stats Grid
              Text("Key Performance Indicators", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard("Total Creators", totalUsers.toString(), Icons.people, AppTheme.accentBlue),
                  _buildStatCard("Monthly Revenue", "\$${monthlyRevenue.toStringAsFixed(2)}", Icons.monetization_on, AppTheme.accentNeonGreen),
                  _buildStatCard("Active Subs", activeSubscribers.toString(), Icons.card_membership, AppTheme.accentCyan),
                  _buildStatCard("Saved Projects", totalProjects.toString(), Icons.folder_open, Colors.amber),
                ],
              ),
              const SizedBox(height: 24),

              // Section: AI Usage Metrics
              Text("AI Processing Analytics", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      child: Column(
                        children: [
                          const Icon(Icons.brush, color: AppTheme.accentBlue),
                          const SizedBox(height: 8),
                          const Text("Sketch Filters Run", style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(totalSketchConversions.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassContainer(
                      child: Column(
                        children: [
                          const Icon(Icons.photo_filter, color: AppTheme.accentCyan),
                          const SizedBox(height: 8),
                          const Text("BG Removals Run", style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(totalBgRemovals.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Revenue Trends (Visual Sparklines/Mocks)
              Text("Revenue Trends (Last 6 Months)", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GlassContainer(
                height: 160,
                child: CustomPaint(
                  painter: SparklinePainter(),
                ),
              ),
              const SizedBox(height: 24),

              // Section: User and Subscription database management
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("User Management", style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () {},
                    child: const Text("View All", style: TextStyle(color: AppTheme.accentCyan)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mockUsers.length,
                itemBuilder: (context, index) {
                  final u = mockUsers[index];
                  final isPremium = u["tier"] == "Premium";
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u["email"], style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("Projects Saved: ${u["projects"]}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPremium ? AppTheme.accentBlue.withOpacity(0.2) : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPremium ? AppTheme.accentBlue : Colors.white30,
                                  ),
                                ),
                                child: Text(
                                  u["tier"],
                                  style: TextStyle(
                                    color: isPremium ? AppTheme.accentCyan : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
                                onPressed: () {
                                  // Edit user tier modal helper
                                  _showEditUserModal(index);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildStatCard(String label, String val, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              const Icon(Icons.trending_up, color: AppTheme.accentNeonGreen, size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditUserModal(int index) {
    final user = mockUsers[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Manage Account", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(user["email"], style: const TextStyle(color: Colors.white70)),
              const Divider(color: AppTheme.glassBorder, height: 24),
              ListTile(
                title: const Text("Set to Premium Tier"),
                trailing: const Icon(Icons.star, color: Colors.amber),
                onTap: () {
                  setState(() {
                    mockUsers[index]["tier"] = "Premium";
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Set to Free Tier"),
                trailing: const Icon(Icons.money_off, color: Colors.white54),
                onTap: () {
                  setState(() {
                    mockUsers[index]["tier"] = "Free";
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Deactivate Account", style: TextStyle(color: AppTheme.errorRed)),
                trailing: const Icon(Icons.block, color: AppTheme.errorRed),
                onTap: () {
                  setState(() {
                    mockUsers[index]["status"] = "Inactive";
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// Sparkline Painter for revenue graphs
class SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    // Last 6 months revenues: Jan to Jun
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.4, size.height * 0.55),
      Offset(size.width * 0.6, size.height * 0.6),
      Offset(size.width * 0.8, size.height * 0.35),
      Offset(size.width, size.height * 0.15),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var point in points) {
      path.lineTo(point.dx, point.dy);
    }

    // Draw line
    canvas.drawPath(path, paint);

    // Draw grid reference bounds
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;
    
    for (int i = 1; i < 4; i++) {
      final y = size.height * 0.25 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => false;
}
