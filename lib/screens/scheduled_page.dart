import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_home/main.dart';

class ScheduledPage extends StatefulWidget {
  final String electronicType;
  final String roomName;
  final String deviceId;
  final String areaName;

  const ScheduledPage({
    super.key,
    required this.electronicType,
    required this.roomName,
    required this.deviceId,
    required this.areaName,
  });

  @override
  State<ScheduledPage> createState() => _ScheduledPageState();
}

class _ScheduledPageState extends State<ScheduledPage> {
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  final List<String> _selectedDays = [];
  bool _isScheduleEnabled = false;
  bool _isLoading = true;

  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingSchedule();
  }

  Future<void> _loadExistingSchedule() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref(
              'users/$phoneNumber/Infrastructure/${widget.areaName}/${widget.roomName}/Device')
          .child(widget.deviceId)
          .child('schedule')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final scheduleData = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          _isScheduleEnabled = scheduleData['isEnabled'] ?? false;

          // Parse start time
          final startTimeParts =
              (scheduleData['startTime'] as String).split(':');
          _startTime = TimeOfDay(
            hour: int.parse(startTimeParts[0]),
            minute: int.parse(startTimeParts[1]),
          );

          // Parse end time
          final endTimeParts = (scheduleData['endTime'] as String).split(':');
          _endTime = TimeOfDay(
            hour: int.parse(endTimeParts[0]),
            minute: int.parse(endTimeParts[1]),
          );

          // Load selected days
          _selectedDays.clear();
          if (scheduleData['days'] is List) {
            _selectedDays.addAll(
                (scheduleData['days'] as List).map((e) => e.toString()));
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading schedule: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Widget _buildTimeSelector({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF2D3436)),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(String day) {
    final bool isSelected = _selectedDays.contains(day);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(day);
          } else {
            _selectedDays.add(day);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D3436) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D3436) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2D3436).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          day,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _saveSchedule() async {
    if (!_isScheduleEnabled || _selectedDays.isEmpty) return;

    try {
      final scheduleData = {
        'isEnabled': _isScheduleEnabled,
        'startTime': '${_startTime.hour}:${_startTime.minute}',
        'endTime': '${_endTime.hour}:${_endTime.minute}',
        'days': _selectedDays,
      };
      // Save to the Infrastructure path with selected location
      await FirebaseDatabase.instance
          .ref(
              'users/$phoneNumber/Infrastructure/${widget.areaName}/${widget.roomName}/Device')
          .child(widget.deviceId)
          .update({
        'schedule': scheduleData,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule saved successfully'),
            backgroundColor: Color(0xFF2D3436),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSchedule() async {
    try {
      // Delete from both paths
      await Future.wait([
        FirebaseDatabase.instance
            .ref(
                'users/$phoneNumber/Infrastructure/${widget.areaName}/${widget.roomName}/Device')
            .child(widget.deviceId)
            .child('schedule')
            .remove(),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted successfully'),
            backgroundColor: Color(0xFF2D3436),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_isScheduleEnabled) ...[
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.delete),
              label: const Text('Delete Schedule'),
              onPressed: _deleteSchedule,
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D3436),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isScheduleEnabled && _selectedDays.isNotEmpty
                ? _saveSchedule
                : null,
            child: const Text(
              'Save Schedule',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2D3436),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Schedule',
                style: TextStyle(color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2D3436),
                          Colors.blue.shade900,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Schedule Switch
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: SwitchListTile(
                      title: const Text(
                        'Enable Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Schedule for ${widget.electronicType} in ${widget.roomName}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      value: _isScheduleEnabled,
                      onChanged: (value) async {
                        setState(() => _isScheduleEnabled = value);

                        try {
                          // Update schedule enabled state in both paths
                          await Future.wait([
                            FirebaseDatabase.instance
                                .ref(
                                    'users/$phoneNumber/Infrastructure/${widget.areaName}/${widget.roomName}/Device')
                                .child(widget.deviceId)
                                .child('schedule')
                                .update({'isEnabled': value}),
                          ]);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error updating schedule state: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      activeColor: const Color(0xFF2D3436),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Time Selection
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeSelector(
                          title: 'Start Time',
                          time: _startTime,
                          onTap: () => _selectTime(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeSelector(
                          title: 'End Time',
                          time: _endTime,
                          onTap: () => _selectTime(false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Days Selection
                  const Text(
                    'Repeat On',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _weekDays
                          .map((day) => _buildDaySelector(day))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButtons(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
