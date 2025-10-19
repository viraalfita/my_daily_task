import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class OfflineTaskService {
  static const _k = 'tasks_json';
  final _uuid = const Uuid();

  Future<List<dynamic>> _readAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.cast<dynamic>() : [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeAll(List<dynamic> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, jsonEncode(list));
  }

  Future<List<dynamic>> getTasks() async => _readAll();

  Future<void> addTask(String title, String time, DateTime date) async {
    final list = await _readAll();
    list.add({
      "_id": _uuid.v4(),
      "title": title,
      "time": time,
      "date": date.toIso8601String(),
      "status": "pending",
    });
    await _writeAll(list);
  }

  Future<void> updateTask(
    String id,
    String title,
    String time,
    String status,
  ) async {
    final list = await _readAll();
    final idx = list.indexWhere((e) => e['_id'] == id);
    if (idx == -1) return;
    final curr = Map<String, dynamic>.from(list[idx] as Map);
    curr['title'] = title;
    curr['time'] = time;
    curr['status'] = status;
    list[idx] = curr;
    await _writeAll(list);
  }

  Future<void> deleteTask(String id) async {
    final list = await _readAll();
    list.removeWhere((e) => e['_id'] == id);
    await _writeAll(list);
  }
}
