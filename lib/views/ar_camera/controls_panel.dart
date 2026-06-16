import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../widgets/glass_container.dart';

class ARControlsPanel extends StatelessWidget {
  final double opacity;
  final ValueChanged<double> onOpacityChanged;
  final bool isLocked;
  final ValueChanged<bool> onLockChanged;
  final bool flipX;
  final VoidCallback onFlipXToggle;
  final bool flipY;
  final VoidCallback onFlipYToggle;
  final double widthCm;
  final double heightCm;
  final void Function(double, double) onDimensionsChanged;
  final bool gridEnabled;
  final ValueChanged<bool> onGridToggle;
  final int gridSize;
  final ValueChanged<int> onGridSizeChanged;
  final bool centerGuideEnabled;
  final ValueChanged<bool> onCenterGuideToggle;
  final bool safeMarginEnabled;
  final ValueChanged<bool> onSafeMarginToggle;
  final bool symmetryEnabled;
  final ValueChanged<bool> onSymmetryToggle;
  final bool useARMode;
  final bool isVRMode;
  final VoidCallback onVRToggle;
  final VoidCallback? onVRSplitPressed;
  final bool isAnchored;
  final VoidCallback? onAnchorPressed;
  final VoidCallback? onReleaseAnchorPressed;
  final double arDistance;
  final ValueChanged<double> onARDistanceChanged;
  final double arHeight;
  final ValueChanged<double> onARHeightChanged;
  final double arHorizontal;
  final ValueChanged<double> onARHorizontalChanged;
  final VoidCallback onHidePressed;
  final VoidCallback? onPermissionPressed;
  final VoidCallback? onSettingsPressed;

  const ARControlsPanel({
    Key? key,
    required this.opacity,
    required this.onOpacityChanged,
    required this.isLocked,
    required this.onLockChanged,
    required this.flipX,
    required this.onFlipXToggle,
    required this.flipY,
    required this.onFlipYToggle,
    required this.widthCm,
    required this.heightCm,
    required this.onDimensionsChanged,
    required this.gridEnabled,
    required this.onGridToggle,
    required this.gridSize,
    required this.onGridSizeChanged,
    required this.centerGuideEnabled,
    required this.onCenterGuideToggle,
    required this.safeMarginEnabled,
    required this.onSafeMarginToggle,
    required this.symmetryEnabled,
    required this.onSymmetryToggle,
    required this.useARMode,
    required this.isAnchored,
    required this.arDistance,
    required this.arHeight,
    required this.arHorizontal,
    required this.onARDistanceChanged,
    required this.onARHeightChanged,
    required this.onARHorizontalChanged,
    required this.onHidePressed,
    required this.isVRMode,
    required this.onVRToggle,
    this.onVRSplitPressed,
    this.onPermissionPressed,
    this.onSettingsPressed,
    this.onAnchorPressed,
    this.onReleaseAnchorPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController widthController =
        TextEditingController(text: widthCm.toStringAsFixed(1));
    final TextEditingController heightController =
        TextEditingController(text: heightCm.toStringAsFixed(1));

    return GlassContainer(
      borderRadius: 20,
      backgroundColor: Colors.black.withOpacity(0.55),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Lock, Flip, Grid, Settings, Permission, VR Mode, Split, Hide Panel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Lock / Unlock Button
                IconButton(
                  icon: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    color: isLocked ? AppTheme.accentNeonGreen : Colors.white,
                  ),
                  onPressed: () => onLockChanged(!isLocked),
                  tooltip: "Lock Position",
                ),
                // Flip X
                IconButton(
                  icon: Icon(Icons.flip,
                      color: flipX ? AppTheme.accentBlue : Colors.white),
                  onPressed: onFlipXToggle,
                  tooltip: "Flip Horizontally",
                ),
                // Flip Y
                IconButton(
                  icon: RotatedBox(
                    quarterTurns: 1,
                    child: Icon(Icons.flip,
                        color: flipY ? AppTheme.accentBlue : Colors.white),
                  ),
                  onPressed: onFlipYToggle,
                  tooltip: "Flip Vertically",
                ),
                // Grid Toggle
                IconButton(
                  icon: Icon(Icons.grid_on,
                      color: gridEnabled ? AppTheme.accentCyan : Colors.white),
                  onPressed: () => onGridToggle(!gridEnabled),
                  tooltip: "Toggle Grid",
                ),
                // Settings button
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: onSettingsPressed ?? () {},
                  tooltip: "Settings",
                ),
                // Permission button
                IconButton(
                  icon: const Icon(Icons.security, color: Colors.white),
                  onPressed: onPermissionPressed ?? () {},
                  tooltip: "Permissions",
                ),
                // VR Mode Toggle (single view)
                IconButton(
                  icon: Icon(Icons.vrpano,
                      color: isVRMode ? AppTheme.accentBlue : Colors.white),
                  onPressed: onVRToggle,
                  tooltip: "VR Mode",
                ),
                // VR Split Screen button
                IconButton(
                  icon: const Icon(Icons.view_week, color: Colors.white),
                  onPressed: onVRSplitPressed ?? () {},
                  tooltip: "Split‑Screen VR",
                ),
                // Hide Panel Button
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                  onPressed: onHidePressed,
                  tooltip: "Hide Settings",
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.glassBorder, height: 16),

          // Row 2: Transparency Slider
          Row(
            children: [
              const Icon(Icons.opacity, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: opacity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: onOpacityChanged,
                ),
              ),
              Text(
                "${(opacity * 100).round()}%",
                style: const TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Row 3: Physical Dimensions (Exact Scale Projection)
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widthController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Width (cm)",
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onSubmitted: (val) {
                    final w = double.tryParse(val) ?? widthCm;
                    onDimensionsChanged(w, heightCm);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: heightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Height (cm)",
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onSubmitted: (val) {
                    final h = double.tryParse(val) ?? heightCm;
                    onDimensionsChanged(widthCm, h);
                  },
                ),
              ),
            ],
          ),

          // Grid/Guides details expansion
          if (gridEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Grid Divisions:",
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: gridSize.toDouble(),
                    min: 2,
                    max: 10,
                    divisions: 8,
                    onChanged: (val) => onGridSizeChanged(val.round()),
                  ),
                ),
                Text("$gridSize",
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12)),
              ],
            ),
          ],

          const SizedBox(height: 8),
          // Additional Professional Guides toggles
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildGuideChip(
                    "Center", centerGuideEnabled, onCenterGuideToggle),
                const SizedBox(width: 8),
                _buildGuideChip(
                    "Margins", safeMarginEnabled, onSafeMarginToggle),
                const SizedBox(width: 8),
                _buildGuideChip(
                    "Symmetry", symmetryEnabled, onSymmetryToggle),
              ],
            ),
          ),

          // 3D AR Calibration controls (using ScrollDials)
          if (useARMode) ...[
            const Divider(color: AppTheme.glassBorder, height: 16),
            // Row 1: Lock, Flip, Grid, and Collapse Panel
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text("AR Calibration Dial",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  if (isAnchored)
                    TextButton.icon(
                      icon: const Icon(Icons.refresh,
                          size: 16, color: Colors.redAccent),
                      label: const Text("Reset",
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 12)),
                      onPressed: onReleaseAnchorPressed,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Horizontal Dial
            ScrollDial(
              label: "Horizontal",
              value: arHorizontal,
              min: -3.0,
              max: 3.0,
              onChanged: onARHorizontalChanged,
            ),
            const SizedBox(height: 8),
            // Height Dial
            ScrollDial(
              label: "Height",
              value: arHeight,
              min: -3.0,
              max: 3.0,
              onChanged: onARHeightChanged,
            ),
            const SizedBox(height: 8),
            // Distance Dial
            ScrollDial(
              label: "Distance",
              value: arDistance,
              min: -5.0,
              max: 5.0,
              onChanged: onARDistanceChanged,
            ),
            if (!isAnchored) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.pin_drop, color: Colors.white),
                label: const Text("Lock Stencil in Space",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onAnchorPressed,
              ),
            ]
          ],
        ],
      ),
    );
  }

  Widget _buildGuideChip(
      String label, bool active, ValueChanged<bool> onToggle) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: active,
      selectedColor: AppTheme.accentBlue.withOpacity(0.7),
      backgroundColor: Colors.transparent,
      onSelected: onToggle,
      visualDensity: VisualDensity.compact,
    );
  }
}

class ScrollDial extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String label;

  const ScrollDial({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
  }) : super(key: key);

  @override
  State<ScrollDial> createState() => _ScrollDialState();
}

class _ScrollDialState extends State<ScrollDial> {
  double _dragStartX = 0.0;
  double _dragStartValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _dragStartX = details.localPosition.dx;
        _dragStartValue = widget.value;
      },
      onHorizontalDragUpdate: (details) {
        final deltaX = details.localPosition.dx - _dragStartX;
        // Sensitivity: 1 pixel drag = 0.002 meters (2 millimeters)
        // Provides extremely fine-grained adjustment, resolving the hypersensitivity
        const sensitivity = 0.002;
        final newValue = (_dragStartValue + deltaX * sensitivity)
            .clamp(widget.min, widget.max);
        widget.onChanged(newValue);
      },
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rolling cylinder tick marks
            Positioned.fill(
              child: CustomPaint(
                painter: DialTicksPainter(
                  value: widget.value,
                  min: widget.min,
                  max: widget.max,
                ),
              ),
            ),
            // Center alignment line
            Container(
              width: 1.5,
              height: 20,
              color: AppTheme.accentCyan,
            ),
            // Axis Label
            Positioned(
              left: 10,
              child: Text(
                widget.label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
            // Real-time value display
            Positioned(
              right: 10,
              child: Text(
                "${widget.value >= 0 ? '+' : ''}${widget.value.toStringAsFixed(2)}m",
                style: const TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DialTicksPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;

  DialTicksPainter({
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0;

    const tickSpacing = 8.0;
    final range = max - min;
    // Map value to offset pixel shift
    final progress = range == 0 ? 0.5 : (value - min) / range;
    const totalTicksWidth = 600.0;
    final offset = progress * totalTicksWidth;

    final midX = size.width / 2;
    final numTicks = (size.width / tickSpacing).ceil() + 4;

    for (int i = -numTicks; i <= numTicks; i++) {
      final tickX = midX + i * tickSpacing - (offset % tickSpacing);
      final distFromCenter = (tickX - midX).abs();
      final edgeFade =
          (1.0 - (distFromCenter / (size.width / 2))).clamp(0.0, 1.0);

      paint.color = Colors.white.withOpacity(0.18 * edgeFade);

      final isMajor = i % 5 == 0;
      final tickHeight = isMajor ? 12.0 : 6.0;

      canvas.drawLine(
        Offset(tickX, (size.height - tickHeight) / 2),
        Offset(tickX, (size.height + tickHeight) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DialTicksPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
