import 'package:cloud_firestore/cloud_firestore.dart';

class TimerModel {
   DocumentReference? timerReference;
   DocumentReference? sessionReference;
   List<QueryDocumentSnapshot> timers=[];
   List<DocumentSnapshot> invitedTimers=[];
   List<QueryDocumentSnapshot> sessions=[];
   String? timerName;
   bool isOwnTimer=true;
   String? ownerName;
   bool isTimerRunning=false;
   int totalCompletedSessions=0;
   int selectedScreen=1;
   int remainingTime = 25*60;
   int totalTime = 25*60;
   DateTime systemPausedTimeStamp=DateTime.now();




  TimerModel({this.timerReference, this.timerName});
}
