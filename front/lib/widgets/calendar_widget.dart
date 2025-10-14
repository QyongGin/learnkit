import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';

class CalendarWidget extends StatefulWidget {
  final Function(DateTime) onDaySelected;
  final Function(DateTime) onDayLongPressed; // 길게 누르면 일정 추가
  final Map<DateTime, List<Schedule>> schedules;

  const CalendarWidget({
    super.key,
    required this.onDaySelected,
    required this.onDayLongPressed,
    required this.schedules,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  List<Schedule> _getSchedulesForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return widget.schedules[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        locale: 'ko_KR',
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black87),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.black87),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF6366F1),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Color(0xFF00FF00),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          weekendTextStyle: const TextStyle(color: Colors.red),
          outsideDaysVisible: false,
        ),
        eventLoader: _getSchedulesForDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDaySelected(selectedDay);
        },
        onDayLongPressed: (selectedDay, focusedDay) {
          widget.onDayLongPressed(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }
}

/// 선택된 날짜의 스케줄 목록을 표시하는 위젯
class ScheduleListWidget extends StatelessWidget {
  final DateTime selectedDate;
  final List<Schedule> schedules;
  final Function(Schedule)? onScheduleTap; // 일정 탭하면 수정 화면으로
  final VoidCallback? onAddSchedule; // 일정 추가 버튼 콜백
  final Function(Schedule)? onToggleComplete; // 완료 토글 콜백

  const ScheduleListWidget({
    super.key,
    required this.selectedDate,
    required this.schedules,
    this.onScheduleTap,
    this.onAddSchedule,
    this.onToggleComplete,
  });

  String _formatDate(DateTime date) {
    final formatter = DateFormat('M월 d일 (E)', 'ko_KR');
    return formatter.format(date);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final formatter = DateFormat('HH:mm');
    return formatter.format(time);
  }

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                '${_formatDate(selectedDate)}\n일정이 없습니다',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              if (onAddSchedule != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onAddSchedule,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    '일정 추가',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // 날짜 옆에 + 버튼 추가
              if (onAddSchedule != null)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    onPressed: onAddSchedule,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    tooltip: '일정 추가',
                  ),
                ),
            ],
          ),
        ),
        ...schedules.map((schedule) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Checkbox(
              value: schedule.isCompleted,
              activeColor: const Color(0xFF00FF00),
              onChanged: (bool? value) {
                onToggleComplete?.call(schedule);
              },
            ),
            title: Text(
              schedule.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: schedule.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: schedule.isCompleted ? Colors.grey : Colors.black87,
              ),
            ),
            subtitle: schedule.startTime != null
                ? Text(
                    '${_formatTime(schedule.startTime)} ${schedule.endTime != null ? "- ${_formatTime(schedule.endTime)}" : ""}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  )
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () {
                onScheduleTap?.call(schedule);
              },
            ),
            onTap: () {
              onScheduleTap?.call(schedule);
            },
          ),
        )),
      ],
    );
  }
}
