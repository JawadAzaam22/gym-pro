import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool selected;
}

class AdaptiveNavScaffold extends StatelessWidget {
  const AdaptiveNavScaffold({
    super.key,
    this.appBar,
    required this.body,
    required this.items,
    this.header,
    this.footerItems,
    this.backgroundColor,
    this.wideBreakpoint = 840,
    this.selectedIndex = 0,
    this.drawerKey,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final List<NavItem> items;
  final Widget? header;
  final List<NavItem>? footerItems;
  final Color? backgroundColor;
  final double wideBreakpoint;
  final int selectedIndex;
  final GlobalKey<ScaffoldState>? drawerKey;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= wideBreakpoint;

    if (isWide) {
      return _WideLayout(
        appBar: appBar,
        body: body,
        items: items,
        header: header,
        footerItems: footerItems,
        backgroundColor: backgroundColor,
        selectedIndex: selectedIndex,
      );
    }

    return _NarrowLayout(
      appBar: appBar,
      body: body,
      items: items,
      header: header,
      footerItems: footerItems,
      backgroundColor: backgroundColor,
      drawerKey: drawerKey,
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    this.appBar,
    required this.body,
    required this.items,
    this.header,
    this.footerItems,
    this.backgroundColor,
    this.selectedIndex = 0,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final List<NavItem> items;
  final Widget? header;
  final List<NavItem>? footerItems;
  final Color? backgroundColor;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: Row(
        children: [
          _NavPanel(
            header: header,
            items: items,
            footerItems: footerItems,
            selectedIndex: selectedIndex,
            closeOnTap: false,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    this.appBar,
    required this.body,
    required this.items,
    this.header,
    this.footerItems,
    this.backgroundColor,
    this.drawerKey,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final List<NavItem> items;
  final Widget? header;
  final List<NavItem>? footerItems;
  final Color? backgroundColor;
  final GlobalKey<ScaffoldState>? drawerKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: drawerKey,
      backgroundColor: backgroundColor,
      appBar: appBar,
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: _NavPanel(
          header: header,
          items: items,
          footerItems: footerItems,
          closeOnTap: true,
        ),
      ),
      body: body,
    );
  }
}

class _NavPanel extends StatelessWidget {
  const _NavPanel({
    required this.header,
    required this.items,
    required this.footerItems,
    required this.closeOnTap,
    this.selectedIndex,
  });

  final Widget? header;
  final List<NavItem> items;
  final List<NavItem>? footerItems;
  final bool closeOnTap;
  final int? selectedIndex;

  void _handleTap(BuildContext context, VoidCallback onTap) {
    if (closeOnTap) {
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) onTap();
      });
    } else {
      onTap();
    }
  }

  Widget _buildTile(BuildContext context, NavItem item, int index) {
    final isSelected = selectedIndex != null && selectedIndex == index;
    return ListTile(
      leading: Icon(item.icon, color: isSelected ? AppColors.primary : item.iconColor),
      title: Text(
        item.label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () => _handleTap(context, item.onTap),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: 260,
          color: AppColors.surface,
          child: Column(
            children: [
              if (header != null) header!,
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    ...items.asMap().entries.map(
                      (entry) => _buildTile(context, entry.value, entry.key),
                    ),
                  ],
                ),
              ),
              if (footerItems != null && footerItems!.isNotEmpty) ...[
                const Divider(color: AppColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: footerItems!
                        .map(
                          (item) => ListTile(
                            leading: Icon(item.icon, color: item.iconColor),
                            title: Text(
                              item.label,
                              style: TextStyle(color: item.iconColor ?? AppColors.textSecondary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            onTap: () => _handleTap(context, item.onTap),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
