import 'package:flutter/material.dart';
import 'web_layout.dart';

class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget> actions;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const WebAppBar({
    super.key,
    this.title,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final canPop = automaticallyImplyLeading && Navigator.canPop(context);
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      bottom: bottom != null ? _ConstrainedBottom(child: bottom!) : null,
      title: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kWebMaxWidth),
          child: Row(
            children: [
              if (canPop)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.maybePop(context),
                )
              else
                const SizedBox(width: 16),
              if (title != null) Expanded(child: title!),
              ...actions,
              if (actions.isNotEmpty) const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConstrainedBottom extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget child;
  const _ConstrainedBottom({required this.child});

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kWebMaxWidth),
        child: child,
      ),
    );
  }
}
