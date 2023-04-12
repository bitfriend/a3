import 'package:flutter/material.dart';

class TagListItem extends StatelessWidget {
  // final Tag tag;
  final String tagTitle;
  final Color tagColor;

  const TagListItem({
    Key? key,
    required this.tagTitle,
    required this.tagColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tagColor),
      ),
      child: Text(
        tagTitle,
      ),
    );
  }
}