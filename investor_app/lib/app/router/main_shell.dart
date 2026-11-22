import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/investor_repository.dart';
import '../../features/menu/side_menu.dart';

/// Bottom tabs + the "push-aside" side menu from the design: the current
/// screen shrinks and slides right while the green menu shows behind it.
///
/// Smoothness: only a translate/scale/clip runs per frame; the screen itself
/// sits in a RepaintBoundary so it is never re-built or re-painted while
/// animating. The widget tree shape never changes, so tab state is kept.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
  late final Animation<double> _t =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

  static const _slide = 0.64; // how far the screen moves (fraction of width)
  static const _shrink = 0.28; // 1 → 0.72 scale

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => ref.read(sideMenuOpenProvider.notifier).state = false;

  void _onTab(int index) {
    widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(sideMenuOpenProvider, (_, open) => open ? _controller.forward() : _controller.reverse());
    final open = ref.watch(sideMenuOpenProvider);
    final width = MediaQuery.sizeOf(context).width;

    final screen = RepaintBoundary(
      child: Scaffold(
        body: widget.shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.shell.currentIndex,
          onDestinationSelected: _onTab,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'হোম'),
            NavigationDestination(icon: Icon(Icons.pie_chart_outline_rounded), selectedIcon: Icon(Icons.pie_chart_rounded), label: 'পোর্টফোলিও'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'লেনদেন'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'রিপোর্ট'),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: !open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && open) _close();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !open,
              child: ExcludeSemantics(
                excluding: !open,
                child: SideMenu(animation: _t, onClose: _close),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _t,
            child: screen,
            builder: (context, child) {
              final t = _t.value;
              return Transform.translate(
                offset: Offset(width * _slide * t, 0),
                child: Transform.scale(
                  scale: 1 - _shrink * t,
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    clipBehavior: t == 0 ? Clip.none : Clip.antiAlias,
                    borderRadius: BorderRadius.circular(36 * t),
                    child: IgnorePointer(ignoring: t > 0, child: child),
                  ),
                ),
              );
            },
          ),
          if (open)
            Positioned(
              left: width * _slide,
              top: 0,
              bottom: 0,
              right: 0,
              child: Semantics(
                button: true,
                label: 'মেনু বন্ধ করুন',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  onHorizontalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) < -100) _close();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
