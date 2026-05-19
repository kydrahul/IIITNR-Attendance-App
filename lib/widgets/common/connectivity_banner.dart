import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';

/// A widget that wraps [child] and overlays a red "No Internet" banner
/// at the top of the screen whenever the device goes offline.
///
/// Place this at the root of your widget tree (wrapping MaterialApp's child)
/// so every screen shows the banner automatically.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  final _service = ConnectivityService();
  late bool _isOnline;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _isOnline = _service.isOnline;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    // Show banner immediately if already offline.
    if (!_isOnline) _animController.forward();

    _service.onChanged.listen((online) {
      if (!mounted) return;
      setState(() => _isOnline = online);
      if (!online) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Banner slides in from the top.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnim,
            child: _OfflineBanner(isOnline: _isOnline),
          ),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final bool isOnline;

  const _OfflineBanner({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Material(
      color: Colors.transparent,
      child: Container(
        color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        padding: EdgeInsets.only(
          top: topPadding + 6,
          bottom: 8,
          left: 16,
          right: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isOnline ? 'Back online' : 'No internet connection',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
