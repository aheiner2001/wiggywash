import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uuid/uuid.dart';

import '../models/profile.dart';
import '../models/submission.dart';
import '../models/worker.dart';

/// The app's single data seam.
///
/// The user **profile** (name + role) always lives on the device
/// (`shared_preferences` / localStorage). **Submissions** sync through Firestore
/// when Firebase is available, giving the manager a live cross-device feed; if
/// Firebase can't initialize, the store transparently falls back to local
/// storage so the app keeps working.
class Store extends ChangeNotifier {
  Store._();
  static final Store instance = Store._();

  static const _kProfile = 'ww_profile';
  static const _kSubmissions = 'ww_submissions';
  static const _kWorkers = 'ww_workers';
  static const _kCollection = 'submissions';
  static const _kWorkersCollection = 'workers';

  SharedPreferences? _prefs;
  Profile? _profile;
  List<Submission> _submissions = [];
  List<Worker> _workers = [];

  bool _cloud = false;
  CollectionReference<Map<String, dynamic>>? _col;
  CollectionReference<Map<String, dynamic>>? _workersCol;

  /// Whether submissions are syncing through Firestore (vs local-only).
  bool get isCloud => _cloud;

  Profile? get profile => _profile;
  List<Submission> get submissions => List.unmodifiable(_submissions);
  List<Worker> get workers {
    final list = List<Worker>.from(_workers);
    list.sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(list);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadProfile();

    _cloud = Firebase.apps.isNotEmpty;
    if (_cloud) {
      _col = FirebaseFirestore.instance.collection(_kCollection);
      _workersCol = FirebaseFirestore.instance.collection(_kWorkersCollection);
      // Live feed: every add/delete/reset on any device flows back here.
      _col!
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .listen(_onSnapshot, onError: (Object e) {
        debugPrint('Firestore listen error: $e');
      });
      _workersCol!.orderBy('name').snapshots().listen(_onWorkersSnapshot,
          onError: (Object e) {
        debugPrint('Firestore workers listen error: $e');
      });
    } else {
      _loadSubmissions();
      _loadWorkers();
    }
  }

  void _onWorkersSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    _workers = snap.docs.map(_workerFromDoc).where((w) => w.name.isNotEmpty).toList();
    notifyListeners();
  }

  Worker _workerFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawPin = data['pin'] as String?;
    return Worker(
      id: doc.id,
      name: data['name'] as String? ?? '',
      pin: rawPin != null && rawPin.trim().isNotEmpty ? rawPin.trim() : null,
    );
  }

  Map<String, dynamic> _workerToDoc(Worker worker) => {
        'name': worker.name,
        if (worker.pin != null && worker.pin!.isNotEmpty) 'pin': worker.pin,
      };

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    _submissions = snap.docs.map(_fromDoc).toList();
    notifyListeners();
  }

  Submission _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final ts = data['submittedAt'];
    return Submission(
      id: doc.id,
      employeeName: data['employeeName'] as String? ?? 'Unknown',
      baGoal: (data['baGoal'] as num?)?.toDouble() ?? 0,
      counts: ((data['counts'] as Map?) ?? {})
          .map((k, v) => MapEntry(k as String, (v as num).toInt())),
      submittedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> _toDoc(Submission s) => {
        'employeeName': s.employeeName,
        'baGoal': s.baGoal,
        'counts': s.counts,
        'submittedAt': Timestamp.fromDate(s.submittedAt),
      };

  // ---- Profile ----------------------------------------------------------

  void _loadProfile() {
    final raw = _prefs?.getString(_kProfile);
    if (raw == null) return;
    try {
      _profile = Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _profile = null;
    }
  }

  Future<void> saveProfile(Profile profile) async {
    _profile = profile;
    await _prefs?.setString(_kProfile, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> clearProfile() async {
    _profile = null;
    await _prefs?.remove(_kProfile);
    notifyListeners();
  }

  // ---- Workers (manager roster) -----------------------------------------

  void _loadWorkers() {
    final raw = _prefs?.getString(_kWorkers);
    if (raw == null) {
      _workers = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _workers = list
          .map((e) => Worker.fromJson(e as Map<String, dynamic>))
          .where((w) => w.name.isNotEmpty)
          .toList();
    } catch (_) {
      _workers = [];
    }
  }

  Future<void> _persistWorkers() async {
    final raw = jsonEncode(_workers.map((w) => w.toJson()).toList());
    await _prefs?.setString(_kWorkers, raw);
  }

  bool hasWorkerName(String name) =>
      _workers.any((w) => w.name.toLowerCase() == name.trim().toLowerCase());

  Future<String?> addWorker(String name, {String? pin}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Name cannot be empty';
    if (hasWorkerName(trimmed)) return '$trimmed is already on the team';

    final cleanedPin = pin?.trim();
    final worker = Worker(
      id: const Uuid().v4(),
      name: trimmed,
      pin: cleanedPin != null && cleanedPin.isNotEmpty ? cleanedPin : null,
    );

    try {
      if (_cloud) {
        await _workersCol!.doc(worker.id).set(_workerToDoc(worker));
        return null;
      }
      _workers.add(worker);
      await _persistWorkers();
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('addWorker error: $e');
      return 'Could not add worker. Check your connection and Firestore rules.';
    }
  }

  Future<String?> updateWorker(
    String id, {
    String? pin,
    bool clearPin = false,
  }) async {
    final cleanedPin =
        clearPin ? null : (pin?.trim().isNotEmpty == true ? pin!.trim() : null);

    try {
      if (_cloud) {
        if (cleanedPin == null) {
          await _workersCol!.doc(id).update({'pin': FieldValue.delete()});
        } else {
          await _workersCol!.doc(id).update({'pin': cleanedPin});
        }
        return null;
      }

      final index = _workers.indexWhere((w) => w.id == id);
      if (index < 0) return 'Worker not found';
      final current = _workers[index];
      _workers[index] = current.copyWith(pin: cleanedPin, clearPin: clearPin);
      await _persistWorkers();
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('updateWorker error: $e');
      return 'Could not update entry code. Check Firestore rules.';
    }
  }

  Future<String?> removeWorker(String id) async {
    try {
      if (_cloud) {
        await _workersCol!.doc(id).delete();
        return null;
      }
      final removed = _workers.where((w) => w.id == id).length;
      if (removed == 0) return 'Worker not found';
      _workers.removeWhere((w) => w.id == id);
      await _persistWorkers();
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('removeWorker error: $e');
      return 'Could not remove worker. Check Firestore rules allow delete on workers.';
    }
  }

  // ---- Submissions ------------------------------------------------------

  void _loadSubmissions() {
    final raw = _prefs?.getString(_kSubmissions);
    if (raw == null) {
      _submissions = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _submissions = list
          .map((e) => Submission.fromJson(e as Map<String, dynamic>))
          .toList();
      _sort();
    } catch (_) {
      _submissions = [];
    }
  }

  Future<void> _persistSubmissions() async {
    final raw = jsonEncode(_submissions.map((s) => s.toJson()).toList());
    await _prefs?.setString(_kSubmissions, raw);
  }

  void _sort() =>
      _submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  Future<void> addSubmission(Submission submission) async {
    if (_cloud) {
      // The snapshot listener updates _submissions and notifies.
      await _col!.doc(submission.id).set(_toDoc(submission));
      return;
    }
    _submissions.add(submission);
    _sort();
    await _persistSubmissions();
    notifyListeners();
  }

  Future<void> deleteSubmission(String id) async {
    if (_cloud) {
      await _col!.doc(id).delete();
      return;
    }
    _submissions.removeWhere((s) => s.id == id);
    await _persistSubmissions();
    notifyListeners();
  }

  /// Removes all submissions on a given calendar day (manager "reset day").
  Future<void> resetDay(DateTime day) async {
    if (_cloud) {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final snap = await _col!
          .where('submittedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('submittedAt', isLessThan: Timestamp.fromDate(end))
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      return;
    }
    _submissions.removeWhere((s) => _isSameDay(s.submittedAt, day));
    await _persistSubmissions();
    notifyListeners();
  }

  List<Submission> submissionsOn(DateTime day) =>
      _submissions.where((s) => _isSameDay(s.submittedAt, day)).toList();

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
