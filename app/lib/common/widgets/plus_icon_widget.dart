import 'package:flutter/material.dart';

class PlusIconWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const PlusIconWidget({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(95),
          borderRadius: const BorderRadius.all(Radius.circular(100)),
        ),
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}
