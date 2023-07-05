import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent;
import 'package:flutter/material.dart';

class EventItem extends StatelessWidget {
  final CalendarEvent event;
  const EventItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(event.title()),
        subtitle: Text(
          formatDt(event),
        ),
        onTap: () => {},
      ),
    );
  }
}
