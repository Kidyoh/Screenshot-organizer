import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/tokens.dart';
import 'pressable.dart';

class NavDestination {
  const NavDestination(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating dark pill navigation; the current tab grows into a labelled pill.
class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelect,
  });

  final List<NavDestination> destinations;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: t.navBar,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.5 : 0.22),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, d) in destinations.indexed)
            _NavItem(
              destination: d,
              selected: i == selected,
              onTap: () {
                if (i != selected) HapticFeedback.selectionClick();
                onSelect(i);
              },
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected, required this.onTap});

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 15),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              size: 23,
              color: selected ? const Color(0xFF16151A) : Colors.white.withValues(alpha: 0.62),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(destination.label,
                          style: context.text.labelLarge
                              ?.copyWith(color: const Color(0xFF16151A))),
                    )
                  : const SizedBox.shrink(),
            ),
          ]),
        ),
      ),
    );
  }
}

class DockAction {
  const DockAction(this.icon, this.label, this.onTap, {this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

/// Floating action bar shown while screenshots are selected.
class SelectionDock extends StatelessWidget {
  const SelectionDock({super.key, required this.actions});
  final List<DockAction> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: t.navBar,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.5 : 0.22),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final a in actions)
            Expanded(
              child: Semantics(
                button: true,
                label: a.label,
                excludeSemantics: true,
                child: Tooltip(
                  message: a.label,
                  child: Pressable(
                    onTap: a.onTap,
                    scale: 0.9,
                    child: SizedBox(
                      height: 70,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(a.icon,
                              size: 23, color: a.danger ? Brand.coral : Colors.white),
                          const SizedBox(height: 4),
                          Text(a.label,
                              style: context.text.labelMedium?.copyWith(
                                  fontSize: 11.5,
                                  color: a.danger
                                      ? Brand.coral
                                      : Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
