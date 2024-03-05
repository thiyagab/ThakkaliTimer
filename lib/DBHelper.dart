import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DBHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _sessionsCollection =
      _db.collection('sessions');
  static final CollectionReference _timersCollection = _db.collection('timers');
  static final CollectionReference _feedCollection = _db.collection('feed');

  static Future<DocumentReference?> createTimer({required String name}) async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        return await _timersCollection.add({
          'name': name,
          'userid': FirebaseAuth.instance.currentUser?.uid,
          'owner': FirebaseAuth.instance.currentUser?.displayName,
          'isActive': true
        });
      }
    } catch (error) {
      print('Error creating timer: $error');
      rethrow;
    }
  }

  // Delete given timerreference
  static Future<void> deleteTimer(
      {required DocumentReference reference}) async {
    try {
      await reference.delete();
    } catch (error) {
      print('Error deleting timer: $error');
      rethrow;
    }
  }

  static Future<void>? deleteAllSessionsForTimerForCurrentUser(
      {required DocumentReference? timerReference}) {
    if (FirebaseAuth.instance.currentUser != null) {
      return _sessionsCollection
          .where('timer', isEqualTo: timerReference)
          .where('userid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get()
          .then((value) {
        value.docs.forEach((element) {
          element.reference.delete();
        });
      });
    }
  }

  // Create a feed with userid, timer reference, time stamp and user display name and add to feedcollection
  static Future<DocumentReference?> createFeed(
      {required DocumentReference? timerReference,
      required String message}) async {
    if (FirebaseAuth.instance.currentUser != null) {
      return await _feedCollection.add({
        'userid': FirebaseAuth.instance.currentUser?.uid,
        'timer': timerReference,
        'timestamp': Timestamp.now(),
        'user': FirebaseAuth.instance.currentUser?.displayName,
        'message': message
      });
    }
  }

  static Future<void> deleteFeed({required DocumentReference reference}) async {
    try {
      await reference.delete();
    } catch (error) {
      print('Error deleting feed: $error');
      rethrow;
    }
  }

  //Fetch all feeds for the given timer reference
  static Stream<QuerySnapshot>? fetchAllFeedsForTimer(
      DocumentReference? timerReference) {
    if (timerReference != null) {
      Stream<QuerySnapshot> value = _feedCollection
          .where('timer', isEqualTo: timerReference)
          .orderBy('timestamp', descending: true)
          .snapshots();
      return value;
      //get the list of docs from the value and return a list of maps
      // return value.docs.map((e) => e.data() as Map<String, dynamic>).toList();
    } else {
      return null;
    }
  }

  static Future<QuerySnapshot<Object?>>? fetchAllTimersForCurrentUser() {
    if (FirebaseAuth.instance.currentUser != null) {
      return _timersCollection
          .where('userid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('isActive', isEqualTo: true)
          .get();
    }
  }

  static Future<List<DocumentSnapshot>?> fetchAllTimersFromSessions() async {
    QuerySnapshot value = await fetchAllSessionsForCurrentUser();
    List<DocumentSnapshot> timers = [];
    if (value.docs != null && value.docs.isNotEmpty) {
      value.docs.map((e) => timers.add(e));
      Set<String> documentIds = value.docs
          .map((session) =>
              ((session.data() as Map)['timer'] as DocumentReference).id)
          .toSet();
      QuerySnapshot value1 = await _timersCollection
          .where(FieldPath.documentId, whereIn: documentIds)
          // .where('userid', isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();

      timers.addAll(value1.docs.where((element) {
        return (element.data() as Map)['userid'] != FirebaseAuth.instance.currentUser?.uid;

      }));
      print('value1 length ${value1.docs.length}'+' timers length ${timers.length}');
      return timers;
    }
  }

  static Future<DocumentSnapshot<Object?>>? fetchTimer(String timerId) {
    try {
      return _timersCollection
          .doc(timerId)
          .get(const GetOptions(source: Source.server));
    } catch (error) {
      print(error);
    }
  }

  static Future<QuerySnapshot<Object?>> fetchAllSessionsForCurrentUser() {
    return _sessionsCollection
        .where('userid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();
  }

  static Future<QuerySnapshot<Object?>> fetchAllSessionsForTimer(
      DocumentReference timerReference) {
    return _sessionsCollection.where('timer', isEqualTo: timerReference).get();
  }

  static Stream<QuerySnapshot<Object?>>? streamAllSessionsForTimer(
      DocumentReference timerReference) {
    return _sessionsCollection
        .where('timer', isEqualTo: timerReference)
        .snapshots();
  }

  static Future<void> updateTimer(
      {required String name, required DocumentReference reference}) async {
    try {
      await reference.update({
        'name': name,
      });
    } catch (error) {
      print('Error creating timer: $error');
      rethrow;
    }
  }

  static Future<void> deactivateTimer(
      {required DocumentReference reference}) async {
    try {
      await reference.update({
        'isActive': false,
      });
    } catch (error) {
      print('Error creating timer: $error');
      rethrow;
    }
  }

  /* Method to create a new session
   status -> 0 for idle, 1 for pause, 2 for in focus
   TODO:  There will be idle sessions created when user simply closes the application after play or pause, should find a way to remove them
  */

  static Future<DocumentReference?> createSession(
      {required DocumentReference? timerReference}) async {
    if (FirebaseAuth.instance.currentUser != null) {
      QuerySnapshot value = await _sessionsCollection
          .where('timer', isEqualTo: timerReference)
          .where('userid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', isNotEqualTo: 0)
          .get();
      if (value.docs.isNotEmpty) {
        await updateSession(
            status: 2,
            sessionDocReference: value.docs.first.reference,
            startts: Timestamp.now());
        return value.docs.first.reference;
      } else {
        return await _sessionsCollection.add({
          'timer': timerReference,
          'status': 2,
          'startts': Timestamp.now(),
          'userid': FirebaseAuth.instance.currentUser?.uid,
          'user': FirebaseAuth.instance.currentUser?.displayName
        });
      }
    }
  }

  static Future<void> updateSession({
    required int status,
    required DocumentReference? sessionDocReference,
    bool isReset = false,
    Timestamp? startts,
  }) async {
    try {
      if (isReset) {
        await sessionDocReference?.delete();
        return;
      }

      Map<String, dynamic> updateData = {
        'status': status,
      };
      if (startts != null) {
        updateData['startts'] = startts;
      }
      if (status == 0) {
        updateData['endts'] = Timestamp.now();
      }
      await sessionDocReference?.update(updateData);
    } catch (error) {
      print('Error updating session: $error');
      rethrow;
    }
  }
}
