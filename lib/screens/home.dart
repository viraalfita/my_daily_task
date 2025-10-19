import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../services/offline_task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final OfflineTaskService api = OfflineTaskService();
  List tasks = [];
  String searchQuery = '';
  DateTime selectedDate = DateTime.now();

  String userName = "Vira";
  String? avatarPath;

  // Notification
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();

    // Initialize timezone and notifications
    tz.initializeTimeZones();
    _initializeNotifications();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadProfile();
    loadTasks();
    _fadeController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
  }

  void _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
            if (notificationResponse.payload != null) {
              _handleNotificationTap(notificationResponse.payload!);
            }
          },
    );
  }

  // Handle notification tap
  void _handleNotificationTap(String payload) {
    showAnimatedTopSnackbar("Task reminder: $payload");
  }

  // Schedule notification for a task
  Future<void> _scheduleTaskNotification(
    String taskId,
    String taskTitle,
    String taskTime,
    DateTime taskDate,
  ) async {
    try {
      final timeParts = taskTime.split(' ');
      final timeValue = timeParts[0];
      final period = timeParts.length > 1 ? timeParts[1] : 'AM';

      final timeComponents = timeValue.split(':');
      int hour = int.parse(timeComponents[0]);
      final minute = int.parse(timeComponents[1]);

      if (period.toUpperCase() == 'PM' && hour < 12) {
        hour += 12;
      } else if (period.toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

      final notificationTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        hour,
        minute,
      ).add(const Duration(minutes: 5));

      // Only schedule if notification time is in the future
      if (notificationTime.isAfter(DateTime.now())) {
        final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
          notificationTime,
          tz.local,
        );

        await flutterLocalNotificationsPlugin.zonedSchedule(
          taskId.hashCode, // id unik
          '⏰ Task Reminder', // title
          'Your task "$taskTitle" was due 5 minutes ago!', // body
          scheduledDate, // tz.TZDateTime
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminder_channel',
              'Task Reminders',
              channelDescription: 'Notifications for task reminders',
              importance: Importance.high,
              priority: Priority.high,
              color: Colors.amber,
              enableVibration: true,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: taskTitle,
        );
      }
    } catch (e) {}
  }

  // Cancel notification for a task
  Future<void> _cancelTaskNotification(String taskId) async {
    await flutterLocalNotificationsPlugin.cancel(taskId.hashCode);
  }

  // Check and schedule notifications for pending tasks
  void _scheduleNotificationsForPendingTasks() {
    final pendingTasks = tasks
        .where((task) => task['status'] == 'pending')
        .toList();

    for (final task in pendingTasks) {
      try {
        final taskDate = DateTime.parse(task['date']);
        _scheduleTaskNotification(
          task['_id'],
          task['title'],
          task['time'],
          taskDate,
        );
      } catch (e) {
        print('❌ Error scheduling notification for task ${task['title']}: $e');
      }
    }
  }

  // Cancel all notifications
  Future<void> _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      userName = sp.getString('user_name') ?? 'Vira';
      avatarPath = sp.getString('user_avatar');
    });
  }

  Future<void> _saveProfile(String name, String? imagePath) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('user_name', name);
    if (imagePath != null) await sp.setString('user_avatar', imagePath);
    await _loadProfile();
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: userName);
    String? pickedPath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Update your personal information",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 3),
                      ),
                      child: ClipOval(
                        child: avatarPath != null
                            ? Image.file(File(avatarPath!), fit: BoxFit.cover)
                            : Container(
                                color: Colors.amber[100],
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.amber[600],
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            pickedPath = picked.path;
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Name Field
              Text(
                "Your Name",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    hintText: "Enter your name",
                  ),
                ),
              ),
              const Spacer(),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _saveProfile(nameController.text, pickedPath);
                        if (!mounted) return;
                        Navigator.pop(context);
                        showAnimatedTopSnackbar(
                          "Profile updated successfully! 🎉",
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> loadTasks() async {
    final data = await api.getTasks();
    setState(() {
      tasks = data;
    });

    // Schedule notifications for pending tasks
    _scheduleNotificationsForPendingTasks();
  }

  void showAnimatedTopSnackbar(String message) {
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.elasticOut,
    );

    overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 60,
        left: 20,
        right: 20,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1.5),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.amber[400]!, Colors.amber[600]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        animationController.reverse().then((_) {
                          overlayEntry.remove();
                          animationController.dispose();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    animationController.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (animationController.isCompleted) {
        await animationController.reverse();
        overlayEntry.remove();
        animationController.dispose();
      }
    });
  }

  void addTask(String title, String time) async {
    await api.addTask(title, time, selectedDate);
    loadTasks();

    // Schedule notification for the new task
    final newTask = {
      '_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'time': time,
      'status': 'pending',
      'date': selectedDate.toIso8601String(),
    };

    _scheduleTaskNotification(newTask['_id']!, title, time, selectedDate);

    showAnimatedTopSnackbar("Task added with reminder! ⏰");
  }

  void editTask(String id, String oldTitle, String oldTime, String oldStatus) {
    final titleController = TextEditingController(text: oldTitle);
    final timeController = TextEditingController(text: oldTime);
    String status = oldStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Edit Task",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),

              // Task Input
              Text(
                "Task Title",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    hintText: "What needs to be done?",
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Input
              Text(
                "Time",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          timePickerTheme: TimePickerThemeData(
                            backgroundColor: Colors.white,
                            dialHandColor: Colors.amber,
                            dialBackgroundColor: Colors.amber[100],
                            hourMinuteTextColor: Colors.black,
                            entryModeIconColor: Colors.amber,
                          ),
                          colorScheme: ColorScheme.light(
                            primary: Colors.amber,
                            onPrimary: Colors.black,
                            secondary: Colors.amber,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedTime != null) {
                    final formatted = pickedTime.format(context);
                    timeController.text = formatted;
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.amber[600]),
                      const SizedBox(width: 12),
                      Text(
                        timeController.text.isEmpty
                            ? "Select time"
                            : timeController.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: timeController.text.isEmpty
                              ? Colors.grey[400]
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isNotEmpty &&
                            timeController.text.isNotEmpty) {
                          // Cancel old notification
                          await _cancelTaskNotification(id);

                          await api.updateTask(
                            id,
                            titleController.text,
                            timeController.text,
                            status,
                          );

                          // Schedule new notification if task is still pending
                          if (status == 'pending') {
                            _scheduleTaskNotification(
                              id,
                              titleController.text,
                              timeController.text,
                              selectedDate,
                            );
                          }

                          Navigator.pop(context);
                          loadTasks();
                          showAnimatedTopSnackbar(
                            "Task updated successfully! ✅",
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void deleteTask(String id) async {
    // Cancel notification before deleting task
    await _cancelTaskNotification(id);

    await api.deleteTask(id);
    loadTasks();
    showAnimatedTopSnackbar("Task deleted 🗑️");
  }

  Future<void> toggleTaskStatus(
    String id,
    String title,
    String time,
    String status,
  ) async {
    String newStatus = status == "done" ? "pending" : "done";

    // Cancel notification if task is marked as done
    if (newStatus == "done") {
      await _cancelTaskNotification(id);
    } else {
      // Reschedule notification if task is marked as pending again
      final taskDate = DateTime.parse(
        tasks.firstWhere((task) => task['_id'] == id)['date'],
      );
      _scheduleTaskNotification(id, title, time, taskDate);
    }

    await api.updateTask(id, title, time, newStatus);
    loadTasks();

    if (newStatus == "done") {
      showAnimatedTopSnackbar("Task completed! 🎉");
    } else {
      showAnimatedTopSnackbar("Task marked as pending ⏰");
    }
  }

  List<Map<String, dynamic>> _getFilteredTasks() {
    return tasks
        .where((task) {
          final matchesSearch = task['title'].toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
          final taskDate = DateTime.parse(task['date']);
          final matchesDate =
              taskDate.year == selectedDate.year &&
              taskDate.month == selectedDate.month &&
              taskDate.day == selectedDate.day;
          return matchesSearch && matchesDate;
        })
        .toList()
        .cast<Map<String, dynamic>>();
  }

  void _showAddTaskBottomSheet() {
    final titleController = TextEditingController();
    final timeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "New Task",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),

              // Task Input
              Text(
                "Task Title",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    hintText: "What needs to be done?",
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Input
              Text(
                "Time",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          timePickerTheme: TimePickerThemeData(
                            backgroundColor: Colors.white,
                            dialHandColor: Colors.amber,
                            dialBackgroundColor: Colors.amber[100],
                            hourMinuteTextColor: Colors.black,
                            entryModeIconColor: Colors.amber,
                          ),
                          colorScheme: ColorScheme.light(
                            primary: Colors.amber,
                            onPrimary: Colors.black,
                            secondary: Colors.amber,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedTime != null) {
                    final formatted = pickedTime.format(context);
                    timeController.text = formatted;
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.amber[600]),
                      const SizedBox(width: 12),
                      Text(
                        timeController.text.isEmpty
                            ? "Select time"
                            : timeController.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: timeController.text.isEmpty
                              ? Colors.grey[400]
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Notification Info
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Colors.amber[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You'll get a reminder 5 minutes after the task time if it's not completed",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        timeController.text.isNotEmpty) {
                      addTask(titleController.text, timeController.text);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Add Task with Reminder",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: FadeTransition(
        opacity: _fadeController,
        child: Padding(
          padding: const EdgeInsets.only(top: 60, right: 20, left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Profile
              Row(
                children: [
                  GestureDetector(
                    onTap: _editProfile,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.amber[400]!, Colors.amber[600]!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.transparent,
                              backgroundImage: avatarPath != null
                                  ? FileImage(File(avatarPath!))
                                  : null,
                              child: avatarPath == null
                                  ? Icon(
                                      Icons.person,
                                      size: 28,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 12,
                                color: Colors.amber[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getGreeting(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Notification icon with badge
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_none,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            _showNotificationSettings();
                          },
                        ),
                      ),
                      // Badge for pending notifications
                      if (getPendingTasksCount() > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              getPendingTasksCount().toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Date Selector
              Container(
                height: 90,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.amber[50]!, Colors.amber[100]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    DateTime date = DateTime.now().add(
                      Duration(days: index - 3),
                    );
                    bool isSelected = date.day == selectedDate.day;
                    bool isToday = date.day == DateTime.now().day;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                      child: Container(
                        width: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.amber[400]!,
                                    Colors.amber[600]!,
                                  ],
                                )
                              : null,
                          color: isToday && !isSelected ? Colors.white : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : isToday
                              ? [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${date.day}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                    ? Colors.amber[600]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getDayAbbreviation(date.weekday),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                    ? Colors.amber[600]
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Tasks Header
              Row(
                children: [
                  Text(
                    "Today's Tasks",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${filteredTasks.length}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Swipe to complete",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Task List
              Expanded(
                child: filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No tasks for today",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap the + button to add a new task!",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          final isDone = task['status'] == "done";

                          return Dismissible(
                            key: Key(task['_id']),
                            direction: DismissDirection.horizontal,
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.green.withOpacity(0.1),
                                    Colors.green.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 20),
                                  Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Complete",
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 20),
                                ],
                              ),
                            ),
                            secondaryBackground: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Colors.red.withOpacity(0.1),
                                    Colors.red.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 20),
                                  Icon(Icons.delete, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Delete",
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.delete, color: Colors.red),
                                  const SizedBox(width: 20),
                                ],
                              ),
                            ),
                            onDismissed: (direction) {
                              if (direction == DismissDirection.startToEnd) {
                                toggleTaskStatus(
                                  task['_id'],
                                  task['title'],
                                  task['time'],
                                  task['status'],
                                );
                              } else {
                                deleteTask(task['_id']);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDone ? Colors.grey[50] : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: isDone
                                    ? null
                                    : Border.all(
                                        color: Colors.grey[100]!,
                                        width: 1,
                                      ),
                                boxShadow: isDone
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 60,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? Colors.grey[200]
                                              : Colors.amber[50],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          task['time'],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDone
                                                ? Colors.grey[600]
                                                : Colors.amber[700],
                                          ),
                                        ),
                                      ),
                                      if (!isDone)
                                        Positioned(
                                          top: -2,
                                          right: -2,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: const BoxDecoration(
                                              color: Colors.amber,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.notifications_active,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),

                                  // Task Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task['title'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            decoration: isDone
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: isDone
                                                ? Colors.grey[500]
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (isDone) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            "Completed",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            "Reminder set for 5 minutes after",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.amber[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Actions
                                  if (!isDone) ...[
                                    IconButton(
                                      onPressed: () => editTask(
                                        task['_id'],
                                        task['title'],
                                        task['time'],
                                        task['status'],
                                      ),
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.amber[600],
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                  IconButton(
                                    onPressed: () => deleteTask(task['_id']),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.grey[500],
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      // FLOATING ACTION BUTTON
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: _showAddTaskBottomSheet,
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  int getPendingTasksCount() {
    return tasks.where((task) => task['status'] == 'pending').length;
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 320,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Notification Settings",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                "You have ${getPendingTasksCount()} pending tasks with reminders", // PERBAIKAN: panggil fungsi dengan benar
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: Icon(Icons.clear_all, color: Colors.red),
                      title: const Text("Clear All Notifications"),
                      subtitle: const Text("Cancel all scheduled reminders"),
                      onTap: () {
                        _cancelAllNotifications();
                        Navigator.pop(context);
                        showAnimatedTopSnackbar("All notifications cleared");
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String getGreeting() {
    final hour = DateTime.now().toUtc().add(Duration(hours: 7)).hour;

    if (hour >= 5 && hour < 12) {
      return "Good morning,";
    } else if (hour >= 12 && hour < 17) {
      return "Good afternoon,";
    } else if (hour >= 17 && hour < 21) {
      return "Good evening,";
    } else {
      return "Good night,";
    }
  }
}
