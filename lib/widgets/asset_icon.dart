import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An icon that prefers a design-exported image and falls back to a Material
/// glyph while that image is missing from the bundle.
///
/// The header's message and bell icons are 3D renders in Figma, like the
/// `nav_*` glyphs, but were never part of the asset export. This lets the
/// screens reference them by their final path today: drop
/// `assets/images/icon_messages.png` and `icon_notifications.png` in (at 3x —
/// roughly 72px for a 24pt icon) and restart, and the real artwork appears
/// with no code change. Until then the Material glyph stands in, and nothing
/// throws or spams the console over the absent file.
class AssetIcon extends StatefulWidget {
  const AssetIcon({
    super.key,
    required this.asset,
    required this.fallback,
    required this.size,
    this.color,
  });

  /// Where the exported artwork will live.
  final String asset;

  /// Drawn until [asset] exists in the bundle.
  final IconData fallback;

  /// Height of the glyph. The image keeps its own aspect ratio within it.
  final double size;

  /// Tint for the fallback glyph. The image asset is drawn as authored.
  final Color? color;

  @override
  State<AssetIcon> createState() => _AssetIconState();
}

class _AssetIconState extends State<AssetIcon> {
  /// One lookup per asset for the life of the process — the bundle cannot
  /// gain files while the app is running.
  static final Map<String, bool> _present = {};

  bool? _available;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(AssetIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.asset != oldWidget.asset) _resolve();
  }

  Future<void> _resolve() async {
    final cached = _present[widget.asset];
    if (cached != null) {
      setState(() => _available = cached);
      return;
    }
    var found = false;
    try {
      await rootBundle.load(widget.asset);
      found = true;
    } catch (_) {
      found = false;
    }
    _present[widget.asset] = found;
    if (mounted) setState(() => _available = found);
  }

  @override
  Widget build(BuildContext context) {
    if (_available != true) {
      return Icon(widget.fallback, size: widget.size, color: widget.color);
    }
    return Image.asset(
      widget.asset,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, _, _) =>
          Icon(widget.fallback, size: widget.size, color: widget.color),
    );
  }
}
