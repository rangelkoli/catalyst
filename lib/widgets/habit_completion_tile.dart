import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class HabitCompletionTile extends StatefulWidget {
  final Habit habit;
  final FirestoreService firestore;
  final String userId;
  final VoidCallback? onEdit;

  const HabitCompletionTile({
    super.key,
    required this.habit,
    required this.firestore,
    required this.userId,
    this.onEdit,
  });

  @override
  State<HabitCompletionTile> createState() => _HabitCompletionTileState();
}

class _HabitCompletionTileState extends State<HabitCompletionTile> {
  bool expanded = false;
  DateTime displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<DateTime> getLast7Days() {
    final now = DateTime.now();
    return List.generate(
      7,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i)),
    );
  }

  List<DateTime> getMonthDays(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0);
    return List.generate(
      last.day,
      (i) => DateTime(month.year, month.month, i + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last7Days = getLast7Days();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        onTap: () => setState(() => expanded = !expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.habit.desc,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Habit',
                      onPressed: widget.onEdit,
                    ),
                  if (widget.onEdit != null)
                    IconButton(
                      icon: Icon(
                        widget.habit.sharedWithFriends
                            ? Icons.share
                            : Icons.share_outlined,
                        color:
                            widget.habit.sharedWithFriends ? Colors.blue : null,
                      ),
                      tooltip:
                          widget.habit.sharedWithFriends
                              ? 'Unshare with Friends'
                              : 'Share with Friends',
                      onPressed: () async {
                        final newValue = !widget.habit.sharedWithFriends;
                        await widget.firestore.setHabitSharedWithFriends(
                          widget.habit.id,
                          newValue,
                        );
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              newValue
                                  ? 'Habit shared with friends!'
                                  : 'Habit unshared.',
                            ),
                          ),
                        );
                      },
                    ),
                  if (widget.onEdit == null)
                    Icon(
                      widget.habit.sharedWithFriends
                          ? Icons.share
                          : Icons.share_outlined,
                      color:
                          widget.habit.sharedWithFriends ? Colors.blue : null,
                    ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              if (widget.habit.whenWhere.isNotEmpty)
                Text(
                  'When/Where: ${widget.habit.whenWhere}',
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 8),
              StreamBuilder<List<String>>(
                stream: widget.firestore.habitCompletionsStream(
                  userId: widget.userId,
                  habitId: widget.habit.id,
                ),
                builder: (context, snap) {
                  final completions = snap.data ?? [];
                  // Calculate streak
                  int streak = 0;
                  DateTime day = DateTime.now();
                  while (completions.contains(
                    DateFormat('yyyy-MM-dd').format(day),
                  )) {
                    streak++;
                    day = day.subtract(const Duration(days: 1));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (streak > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 4),
                              Text(
                                '$streak-day streak',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children:
                            last7Days.map((day) {
                              final ymd = DateFormat('yyyy-MM-dd').format(day);
                              final isToday =
                                  DateTime.now().difference(day).inDays == 0;
                              final completed = completions.contains(ymd);
                              final indicator = Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      completed
                                          ? Colors.green
                                          : (isToday
                                              ? Colors.grey[300]
                                              : Colors.grey[100]),
                                  border: Border.all(
                                    color:
                                        isToday
                                            ? Colors.blue
                                            : Colors.grey.shade400,
                                    width: isToday ? 2 : 1,
                                  ),
                                ),
                                child:
                                    completed
                                        ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                        : Text(
                                          DateFormat(
                                            'E',
                                          ).format(day).substring(0, 1),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isToday
                                                    ? Colors.blue
                                                    : Colors.black,
                                          ),
                                        ),
                              );
                              if (isToday && !completed) {
                                return FocusableActionDetector(
                                  autofocus: false,
                                  enabled: true,
                                  descendantsAreFocusable: false,
                                  onShowFocusHighlight: (focused) {},
                                  onShowHoverHighlight: (hovering) {},
                                  actions: {
                                    ActivateIntent:
                                        CallbackAction<ActivateIntent>(
                                          onInvoke: (intent) {
                                            widget.firestore.completeHabit(
                                              userId: widget.userId,
                                              habitId: widget.habit.id,
                                              date: day,
                                            );
                                            return null;
                                          },
                                        ),
                                  },
                                  child: GestureDetector(
                                    onTap:
                                        () => widget.firestore.completeHabit(
                                          userId: widget.userId,
                                          habitId: widget.habit.id,
                                          date: day,
                                        ),
                                    child: indicator,
                                  ),
                                );
                              } else {
                                return indicator;
                              }
                            }).toList(),
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_double_arrow_left,
                              ),
                              tooltip: 'Previous Year',
                              onPressed:
                                  () => setState(() {
                                    displayedMonth = DateTime(
                                      displayedMonth.year - 1,
                                      displayedMonth.month,
                                    );
                                  }),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_left),
                              tooltip: 'Previous Month',
                              onPressed:
                                  () => setState(() {
                                    displayedMonth = DateTime(
                                      displayedMonth.year,
                                      displayedMonth.month - 1,
                                    );
                                  }),
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(displayedMonth),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_right),
                              tooltip: 'Next Month',
                              onPressed:
                                  () => setState(() {
                                    displayedMonth = DateTime(
                                      displayedMonth.year,
                                      displayedMonth.month + 1,
                                    );
                                  }),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_double_arrow_right,
                              ),
                              tooltip: 'Next Year',
                              onPressed:
                                  () => setState(() {
                                    displayedMonth = DateTime(
                                      displayedMonth.year + 1,
                                      displayedMonth.month,
                                    );
                                  }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                                childAspectRatio: 1,
                              ),
                          itemCount: getMonthDays(displayedMonth).length,
                          itemBuilder: (context, idx) {
                            final day = getMonthDays(displayedMonth)[idx];
                            final ymd = DateFormat('yyyy-MM-dd').format(day);
                            final completed = completions.contains(ymd);
                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: completed ? Colors.green : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color:
                                      completed ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
