import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thakkalitimer/DBHelper.dart';
import 'package:thakkalitimer/model/TimerProvider.dart';

class FriendsScreen extends StatefulWidget{

  @override
  _FriendsScreenState createState() => _FriendsScreenState();

}
class _FriendsScreenState extends State<FriendsScreen>{

  List<Map<String, dynamic>> friendsList = [

  ];
  Map<String, List<Map<String,dynamic>>> sessionMap = {};

  @override
  Widget build(BuildContext context) {
    return buildFriendsSection();
  }

  Widget buildFriendsSection() {
    // Create a future builder fetching all sessions using DBHelper
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    if(timerProvider.timerModel.timerReference==null){
      return const Center(child: Text('No friends found'));
    }
    return StreamBuilder(
      stream: DBHelper.streamAllSessionsForTimer(timerProvider.timerModel!.timerReference!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if((snapshot.data!.docs).isEmpty){
            return const Center(child: Text('No friends found'));
          }
          else {
            // final sessionList = snapshot.data as List<DocumentSnapshot>;
            return buildFriendsList(snapshot.data!.docs);
          }
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }


  // Method to build the list of friends
  Widget buildFriendsList(List<DocumentSnapshot> sessionList) {

    /*Iterate through the sessionList, create a new map, with userid as the key and the list of session objects with same userid as the value
     */

    //refactor element to session
    sessionMap.clear();
    for (var session in sessionList) {
      Map<String,dynamic> sessionData = session.data() as Map<String,dynamic>;
      if (sessionMap.containsKey(sessionData['userid'])) {
        sessionMap[sessionData['userid']]!.add(sessionData);
      } else {
        sessionMap[sessionData['userid']] = [sessionData];
      }

    }
    friendsList.clear();
    //Iterate through the session map and Create a unique entry for user, with userid, name and number of sessions, and add it to friendsList
    sessionMap.forEach((key, value) {
      //The value has list of session objects, each session has a timestamp field 'startts', find the latest startts and get its status and startts
      value.sort((a, b) => b['startts'].compareTo(a['startts']));
      friendsList.add({
        'userid': key,
        'user': value[0]['user'],
        'status': value[0]['status'],
        'sessions': value.length
      });
    });



    return ListView.builder(
      itemCount: friendsList.length,
      itemBuilder: (context, index) {
        return buildFriendListItem(friendsList[index]);
      },
    );
  }


  // Method to build individual friend list items
  Widget buildFriendListItem(Map<String, dynamic> session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Spacing between items
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Row(children: [
                Text(session['user'], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                buildThakkalis(session['sessions']),
              ])),
          Text(displayStatus(session['status']),
              textAlign: TextAlign.end, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
        ],
      ),
    );
  }


  Widget buildThakkalis(int count){
    if(count>4) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/tomato.png', // Or 'assets/images/my_icon.png'
              width: 18, // Adjust size as needed
              height: 18,
            ), Text('x${count}')]);
    }else if(count>0){
      return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...buildTomatoes(count),
          ]);

    }
    else{
      return Container();
    }
  }

  displayStatus(int status){
    switch(status){
      case 0:
        return 'Idle';
      case 1:
        return 'Paused';
      case 2:
        return 'InFocus';
      default:
        return 'Unknown';
    }
  }

  // Helper function to format time
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  List<Image> buildTomatoes(int count) {
    return List.generate(
        count,
            (index) => Image.asset(
          'assets/images/tomato.png', // Or 'assets/images/my_icon.png'
          width: 12, // Adjust size as needed
          height: 12,
        ));
  }
}