import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thakkalitimer/DBHelper.dart';
import 'package:thakkalitimer/model/TimerModel.dart';

class TimerProvider extends ChangeNotifier {
  final TimerModel _timerModel = TimerModel();
  TimerModel get timerModel => _timerModel;

  fetchAllSessions({bool notify = true}) async {
    if (_timerModel.timerReference == null) return [];

    QuerySnapshot value =
        await DBHelper.fetchAllSessionsForTimer(_timerModel.timerReference!);
    _timerModel.sessions.clear();
    _timerModel.sessions.addAll(value.docs);
    _timerModel.totalCompletedSessions = completedSessionsForUser();
    if (notify) notifyListeners();
    return value.docs;
  }

  completedSessionsForUser() {
    int count = 0;
    //iterate using for each _timermodel.sessions and find the session belong to current userid, and return the count
    for (var session in _timerModel.sessions) {
      Map<String, dynamic> data = session.data() as Map<String, dynamic>;
      if (data['userid'] == FirebaseAuth.instance.currentUser!.uid &&
          data['status'] == 0) {
        count = count + 1;
      }
    }
    return count;
  }

  fetchTimers({bool notify = true, bool setDefault = true}) async {
    QuerySnapshot? value = await DBHelper.fetchAllTimersForCurrentUser();
    if (value != null) {
      _timerModel.timers.clear();
      _timerModel.timers.addAll(value.docs);
      if (_timerModel.timerReference == null &&
          value.docs.isNotEmpty &&
          setDefault) {
        initializeTimer(value.docs[0]);
      }
      if (notify) notifyListeners();
    }
  }

  fetchInvitedTimers({bool notify = true}) async {
    List<DocumentSnapshot>? invitedTimers =
        await DBHelper.fetchAllTimersFromSessions();
    if (invitedTimers != null) {
      _timerModel.invitedTimers.clear();
      _timerModel.invitedTimers.addAll(invitedTimers);
      if (notify) notifyListeners();
    }
  }

  void initializeTimer(DocumentSnapshot value) {
    _timerModel.timerReference = value.reference;
    _timerModel.isOwnTimer = true;
    if (value.data() != null) {
      setTimerReference(
          value.reference,
          (value.data() as Map<String, dynamic>)['name'],
          (value.data() as Map<String, dynamic>)['owner']);
    }
  }

  Future<DocumentSnapshot?> fetchInvitedTimerById(String timerId,
      {bool notify = true}) async {
    DocumentSnapshot? value = await DBHelper.fetchTimer(timerId);
    print(value);
    if (value != null) {
      _timerModel.timerReference = value?.reference;
      if (value?.data() != null) {
        _timerModel.timerName = (value?.data() as Map<String, dynamic>)['name'];
        _timerModel.isOwnTimer = false;
        _timerModel.ownerName =
            (value?.data() as Map<String, dynamic>)['owner'];
        if (!_timerModel.invitedTimers
                .map((e) => e.id)
                .toSet()
                .contains(value.id) &&
            !timerModel.timers.map((e) => e.id).toSet().contains(value.id)) {
          timerModel.invitedTimers.add(value!);
        }
      }
      if (notify) notifyListeners();
      return value;
    }
  }

  checkAndFetchTimers(String? timerId) async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        if (_timerModel.timers == null || _timerModel.timers.isEmpty) {
          await fetchTimers(notify: false, setDefault: timerId == null);
        }

        if (_timerModel.invitedTimers == null ||
            _timerModel.invitedTimers.isEmpty) {
          await fetchInvitedTimers(notify: false);
        }
      }

      if (timerId != null) {
        DocumentSnapshot? invitedTimer =
            await fetchInvitedTimerById(timerId, notify: false);
      }

      notifyListeners();
    } catch (error) {
      print(error);
    }
  }

  void setTimerReference(DocumentReference? newTimerReference,
      String? timerName, String? ownerName) async {
    _timerModel.timerReference = newTimerReference;
    _timerModel.timerName = timerName;
    _timerModel.ownerName = ownerName;
    _timerModel.selectedScreen = 1;
    await fetchAllSessions(notify: false);
    notifyListeners(); // Notify consumers of state change
  }

  void clearTimerReference({bool notify = true}) {
    _timerModel.timerReference = null;
    _timerModel.timerName = null;
    _timerModel.ownerName = null;
    _timerModel.totalCompletedSessions = 0;
    _timerModel.selectedScreen = 1;
    if (notify) {
      notifyListeners();
    }
  }

  deleteTimer() async {
    if (_timerModel.timerReference != null) {
      await DBHelper.deleteAllSessionsForTimerForCurrentUser(
          timerReference: timerModel.timerReference);
      clearTimerReference(notify: false);
      if (_timerModel.isOwnTimer) {
        QuerySnapshot value = await DBHelper.fetchAllSessionsForTimer(
            _timerModel.timerReference!);
        if (value == null || value.docs.isEmpty) {
          await DBHelper.deleteTimer(reference: _timerModel.timerReference!);
        } else {
          await DBHelper.deactivateTimer(
              reference: _timerModel.timerReference!);
        }
        fetchTimers();
      } else {
        fetchInvitedTimers();
      }
    }
  }

  createOrUpdateTimer(String timerName) async {
    timerModel?.timerName = timerName;
    if (timerModel?.timerReference != null) {
      await DBHelper.updateTimer(
          name: timerName, reference: timerModel.timerReference!);
    } else {
      timerModel?.timerReference = await DBHelper.createTimer(name: timerName!);
    }
    fetchTimers();
  }

  completeSession() async {
    //TODO for session completion show something
    timerModel?.isTimerRunning = false;
    if (timerModel?.sessionReference != null) {
      await DBHelper.updateSession(
          status: 0, sessionDocReference: timerModel?.sessionReference);
      timerModel?.sessionReference = null;
      timerModel.totalCompletedSessions++;
      // fetchAllSessions();
    }
  }

  clearAll() {
    _timerModel.timers.clear();
    _timerModel.invitedTimers.clear();
    _timerModel.sessions.clear();
    _timerModel.remainingTime = _timerModel.totalTime;
    _timerModel.isTimerRunning = false;
    _timerModel.isOwnTimer=true;
    clearTimerReference();
  }
}
