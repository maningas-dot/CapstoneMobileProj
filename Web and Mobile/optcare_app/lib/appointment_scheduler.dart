import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';

class AppointmentSchedulerScreen extends StatefulWidget {
  final dynamic patientId;
  final Future<void> Function() onScheduled;

  const AppointmentSchedulerScreen({
    super.key,
    required this.patientId,
    required this.onScheduled,
  });

  @override
  State<AppointmentSchedulerScreen> createState() =>
      _AppointmentSchedulerScreenState();
}

class _AppointmentSchedulerScreenState
    extends State<AppointmentSchedulerScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final _providerController = TextEditingController();
  final _appointmentTypeController = TextEditingController();
  bool _creatingAppointment = false;

  Future<void> _pickTime() async {
    final selection = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (selection != null && mounted) {
      setState(() => _selectedTime = selection);
    }
  }

  String _toMysqlTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _createAppointment() async {
    if (_providerController.text.trim().isEmpty ||
        _appointmentTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill provider and appointment type'),
        ),
      );
      return;
    }

    setState(() => _creatingAppointment = true);
    try {
      final uri = Uri.parse('$apiBaseUrl/create_appointment.php');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'patient_id': widget.patientId,
              'patient_name': 'Mobile User',
              'appointment_date': _selectedDate
                  .toIso8601String()
                  .split('T')
                  .first,
              'appointment_time': _toMysqlTime(_selectedTime),
              'provider': _providerController.text.trim(),
              'appointment_type': _appointmentTypeController.text.trim(),
              'status': 'Requested',
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = response.body.trim();
      Map<String, dynamic> data = {};
      if (body.isNotEmpty && !body.startsWith('<')) {
        data = jsonDecode(body) as Map<String, dynamic>;
      }
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Appointment scheduled',
            ),
          ),
        );
        _providerController.clear();
        _appointmentTypeController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Could not schedule appointment',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to schedule appointment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingAppointment = false);
        widget.onScheduled();
      }
    }
  }

  @override
  void dispose() {
    _providerController.dispose();
    _appointmentTypeController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F76FF), Color(0xFF409CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          const Text(
            'Pick a date on the calendar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          currentDate: DateTime.now(),
          onDateChanged: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select appointment time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: const Text('Choose'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F76FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Appointment details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _providerController,
              decoration: const InputDecoration(
                labelText: 'Provider',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _appointmentTypeController,
              decoration: const InputDecoration(
                labelText: 'Appointment type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _creatingAppointment ? null : _createAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F76FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _creatingAppointment
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Confirm Appointment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Scheduler'),
        backgroundColor: const Color(0xFF0F76FF),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCalendarCard(),
              const SizedBox(height: 16),
              _buildTimeCard(),
              const SizedBox(height: 16),
              _buildInputCard(),
              const SizedBox(height: 24),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }
}
