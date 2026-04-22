import 'package:flutter/material.dart';

class AvailabilitySelector extends StatelessWidget {
  final Map<String, bool> dayEnabled;
  final Map<String, TimeOfDay?> dayStart;
  final Map<String, TimeOfDay?> dayEnd;
  final Function(String day, bool enabled, TimeOfDay? start, TimeOfDay? end)
  onChanged;

  AvailabilitySelector({
    super.key,
    required this.dayEnabled,
    required this.dayStart,
    required this.dayEnd,
    required this.onChanged,
  });

  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Working Hours",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._weekdays.map((day) => _buildDayTile(context, day)),
      ],
    );
  }

  Widget _buildDayTile(BuildContext context, String day) {
    return ExpansionTile(
      leading: Checkbox(
        value: dayEnabled[day],
        onChanged: (v) => onChanged(day, v!, dayStart[day], dayEnd[day]),
      ),
      title: Text(day),
      subtitle: Text(
        dayEnabled[day]!
            ? "${dayStart[day]?.format(context) ?? '--'} to ${dayEnd[day]?.format(context) ?? '--'}"
            : "Unavailable",
      ),
      children: [
        if (dayEnabled[day]!)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text("Set Start"),
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: dayStart[day] ?? TimeOfDay.now(),
                    );
                    if (t != null) onChanged(day, true, t, dayEnd[day]);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Set End"),
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: dayEnd[day] ?? TimeOfDay.now(),
                    );
                    if (t != null) onChanged(day, true, dayStart[day], t);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
