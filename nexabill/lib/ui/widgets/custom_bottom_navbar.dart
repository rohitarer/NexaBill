import 'package:flutter/material.dart';
import 'package:nexabill/core/theme.dart';

class CustomBottomNavBarItem {
  final IconData icon;
  final String label;
  final bool showBadge;

  CustomBottomNavBarItem({
    required this.icon,
    required this.label,
    this.showBadge = false,
  });
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<CustomBottomNavBarItem> items;
  final ValueChanged<int> onTap;
  final bool showLabels;
  final Color? unselectedColor;
  final Color? backgroundColor;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.showLabels = true,
    this.unselectedColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor =
        AppTheme.secondaryColor; // 🔥 Use theme's secondary color
    final unselectedColor = this.unselectedColor ?? theme.iconTheme.color;
    final backgroundColor =
        this.backgroundColor ??
        (theme.brightness == Brightness.dark
            ? Colors.black26
            : Colors.grey.shade200);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        color: backgroundColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.translucent,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / items.length - 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              item.icon,
                              key: ValueKey(isSelected),
                              color:
                                  isSelected ? selectedColor : unselectedColor,
                              size: isSelected ? 28 : 24,
                            ),
                          ),
                          if (item.showBadge)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (showLabels)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isSelected ? selectedColor : unselectedColor,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                            child: Text(
                              item.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
