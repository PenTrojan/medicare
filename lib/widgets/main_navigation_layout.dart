import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:medicare/themes/app_colors.dart';

// ==========================================
// 1. Navigation Configuration Model
// ==========================================
class NavigationItemConfig {
  final IconData icon;
  final String label;
  final Widget Function(void Function(int mainTab, int? innerTab) goToTab)
  pageBuilder;

  const NavigationItemConfig({
    required this.icon,
    required this.label,
    required this.pageBuilder,
  });
}

// ==========================================
// 2. Keep-Alive Wrapper (Preserves State)
// ==========================================
// This ensures that when you slide away from a tab, it doesn't
// delete your scroll position or active forms!
class KeepAlivePage extends StatefulWidget {
  final Widget child;
  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // The magic line that saves state

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ==========================================
// 3. The Main Layout Shell
// ==========================================
class MainNavigationLayout extends StatefulWidget {
  final List<NavigationItemConfig> items;
  final int initialIndex;

  const MainNavigationLayout({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationLayout> createState() => _MainNavigationLayoutState();
}

class _MainNavigationLayoutState extends State<MainNavigationLayout> {
  late int _selectedIndex;
  late PageController _pageController;
  int _innerTabTarget = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Triggered by buttons INSIDE the pages (like your Dashboard stat cards)
  void _handleTabRequest(int mainTab, int? innerTab) {
    if (innerTab != null) {
      _innerTabTarget = innerTab;
    }
    _animateToTab(mainTab);
  }

  // Triggered by tapping the bottom navigation bar directly
  void _animateToTab(int index) {
    if (_selectedIndex == index) return;

    setState(() => _selectedIndex = index);

    // Smoothly slides the screen content
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuint,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculates the X-axis position for the gliding bubble (-1.0 is far left, 1.0 is far right)
    final double bubbleAlignmentX =
        -1.0 + (_selectedIndex * (2.0 / (widget.items.length - 1)));

    return Scaffold(
      extendBody: true, // Content scrolls behind the translucent bar
      // PageView provides the native, buttery-smooth horizontal sliding
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disables finger-swiping so it only slides on button tap
        children: widget.items
            .map(
              (item) =>
                  KeepAlivePage(child: item.pageBuilder(_handleTabRequest)),
            )
            .toList(),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Container(
            height: 64, // Fixed height for our custom bar
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 16.0,
                  sigmaY: 16.0,
                ), // Frosted glass blur
                child: Container(
                  color: Colors.white.withOpacity(
                    0.15,
                  ), // Translucent white tint
                  child: Stack(
                    children: [
                      // --- THE GLIDING BUBBLE ---
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutQuint,
                        alignment: Alignment(bubbleAlignmentX, 0),
                        child: FractionallySizedBox(
                          widthFactor:
                              1.0 / widget.items.length, // Divides width evenly
                          child: Center(
                            child: Container(
                              height: 40,
                              width: 56, // The shape of the pill
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // --- THE ICONS ---
                      Row(
                        children: widget.items.asMap().entries.map((entry) {
                          final int idx = entry.key;
                          final NavigationItemConfig item = entry.value;
                          final bool isSelected = _selectedIndex == idx;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _animateToTab(idx),
                              behavior: HitTestBehavior
                                  .opaque, // Ensures the whole box is clickable, not just the icon
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary.withOpacity(
                                            0.6,
                                          ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 26,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary.withOpacity(
                                            0.6,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

