class Project {
  final String id;
  final String name;
  final String localImagePath;
  final String? cloudImageUrl;
  final double widthCm;
  final double heightCm;
  final double opacity;
  final double rotation;
  final bool flipX;
  final bool flipY;
  final bool isLocked;
  final bool gridEnabled;
  final int gridSize;
  final int createdAt;
  final int updatedAt;
  final bool isSynced;

  Project({
    required this.id,
    required this.name,
    required this.localImagePath,
    this.cloudImageUrl,
    this.widthCm = 30.0,
    this.heightCm = 20.0,
    this.opacity = 0.5,
    this.rotation = 0.0,
    this.flipX = false,
    this.flipY = false,
    this.isLocked = false,
    this.gridEnabled = false,
    this.gridSize = 5,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Project copyWith({
    String? name,
    String? localImagePath,
    String? cloudImageUrl,
    double? widthCm,
    double? heightCm,
    double? opacity,
    double? rotation,
    bool? flipX,
    bool? flipY,
    bool? isLocked,
    bool? gridEnabled,
    int? gridSize,
    int? updatedAt,
    bool? isSynced,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      localImagePath: localImagePath ?? this.localImagePath,
      cloudImageUrl: cloudImageUrl ?? this.cloudImageUrl,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
      isLocked: isLocked ?? this.isLocked,
      gridEnabled: gridEnabled ?? this.gridEnabled,
      gridSize: gridSize ?? this.gridSize,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'localImagePath': localImagePath,
      'cloudImageUrl': cloudImageUrl,
      'widthCm': widthCm,
      'heightCm': heightCm,
      'opacity': opacity,
      'rotation': rotation,
      'flipX': flipX ? 1 : 0,
      'flipY': flipY ? 1 : 0,
      'isLocked': isLocked ? 1 : 0,
      'gridEnabled': gridEnabled ? 1 : 0,
      'gridSize': gridSize,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      localImagePath: map['localImagePath'] as String,
      cloudImageUrl: map['cloudImageUrl'] as String?,
      widthCm: (map['widthCm'] as num).toDouble(),
      heightCm: (map['heightCm'] as num).toDouble(),
      opacity: (map['opacity'] as num).toDouble(),
      rotation: (map['rotation'] as num).toDouble(),
      flipX: map['flipX'] == 1,
      flipY: map['flipY'] == 1,
      isLocked: map['isLocked'] == 1,
      gridEnabled: map['gridEnabled'] == 1,
      gridSize: map['gridSize'] as int,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
      isSynced: map['isSynced'] == 1,
    );
  }
}
