import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:thakkalitimer/DBHelper.dart';
import 'package:thakkalitimer/model/TimerProvider.dart';

class FeedUI extends StatefulWidget{

  @override
  _FeedUIState createState() => _FeedUIState();
}

class _FeedUIState extends State<FeedUI>{


  // Sample 'feedMessages' structure (You'll get this from your backend later)
  List<Map<String, dynamic>> feedMessages = [
    {
      'author': 'Alice',
      'message': 'Starting a tough session!',
      'timestamp': DateTime.now()
    },
    {
      'author': 'Bob',
      'message': '5 min break is the best.',
      'timestamp': DateTime.now()
    },
  ];

  //TODO this is a ugly pattern, but still to avoid a db query, we store the feed messages locally to validate
  List<DocumentSnapshot> localFeedMessages=[];


  @override
  Widget build(BuildContext context) {
    return buildFeedUI();
  }

  Widget fetchAndBuildFeedUI(){
    //Create a future builder, get feed messages from DBHelper for the timer, fetchAllFeedsForTimer, and build a list
    return StreamBuilder(
      stream: DBHelper.fetchAllFeedsForTimer(Provider.of<TimerProvider>(context, listen: false).timerModel.timerReference),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if((snapshot.data!.docs).isEmpty){
            return const Center(child: Text('No messages found'));
          }
          return buildFeedList(snapshot.data!.docs);
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());
        }else{
          return const Center(child: Text('No messages found'));
        }
      },
    );
  }

  Widget buildFeedList(List<DocumentSnapshot> feedMessages){
    localFeedMessages=feedMessages;
    //Swipe to delete listview

    return ListView.builder(
      reverse: true, // Display latest messages on top
      itemCount: feedMessages.length, // Replace with your message data
      itemBuilder: (context, index) {


        return Dismissible(
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) {
            // First check if the feed belongs to the current user, if not return false, if true asks for confirmation
            if ((feedMessages[index].data() as Map<String, dynamic>)['userid'] != FirebaseAuth.instance.currentUser?.uid) {
              return Future.value(false);
            }
            return showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text('Are you sure you want to delete this message?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
            );
          },

          key: Key(feedMessages[index].id),
          child: buildFeedMessageItem(feedMessages[index].data() as Map<String, dynamic>),
          background: Container(
            color: Colors.red,
            child:
            const Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Delete', style: TextStyle(color: Colors.white),),
              )

            ),
          ),
          onDismissed: (direction) {
            // Remove the message from the list
            removeMessage(feedMessages[index].reference);
            showMessage('Deleting');
          },
        );
        // return buildFeedMessageItem(feedMessages[index].data() as Map<String, dynamic>);
      },
    );
  }

  removeMessage(DocumentReference reference){
    DBHelper.deleteFeed(reference: reference);
  }

  TextEditingController messageController=  TextEditingController();

  Widget buildFeedUI() {

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Input Area

        // Feed Messages List
        Expanded(
          child: fetchAndBuildFeedUI(),
        ),
        Padding(
            padding: const EdgeInsets.all(10),
            child:Row(
          children: [

             Expanded(
              child: TextField(
                decoration: const InputDecoration(hintText: 'Enter your message'),
                controller:messageController ,
                onSubmitted: (value) {
                  postMessage();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
               postMessage();
              },
            ),
          ],
        )),
      ],
    );
  }

  postMessage() async{
    if(FirebaseAuth.instance.currentUser!=null){
      if(messageController.text.isEmpty){
        showMessage('Please enter a message');
        return;
      }else if(messageController.text.trim().length>144){
        showMessage('Message too long');
        return;
      }else if(Provider.of<TimerProvider>(context, listen: false).timerModel.totalCompletedSessions ==0){
        showMessage('Complete atleast one session to post');
        return;
      }else if(!checkLimit()){
        // showMessage('You get to post one message for each completed session');
        print('limit reached');
        showDialog<String>(
            context: context,
            builder: (BuildContext context) =>AlertDialog(
                title: const Text('Its focus time'),
                content: const Text('Focus time! Finish one more session and you will unlock one more message 🚀'),
                actions: <Widget>[
                TextButton(onPressed: () {
                  //dismiss dialog
                  Navigator.pop(context);

                   }, child: const Text('Ok'))
            ]));
        return;
      }
      await DBHelper.createFeed(
          timerReference: Provider.of<TimerProvider>(context, listen: false).timerModel.timerReference,
          message: messageController.text);
      messageController.clear();

      fetchAndBuildFeedUI();
    }else{
      showMessage('Login to post message');
    }
  }

  bool checkLimit(){
    if(Provider.of<TimerProvider>(context, listen: false).timerModel.totalCompletedSessions==0){
      return false;
    }
    //Iterate through the localfeedmessages, and find how many messages belong to the current user, by checking the userid
    int count=0;
    for(var message in localFeedMessages){
      Map<String,dynamic> data=message.data() as Map<String,dynamic>;
      if(data['userid'] == FirebaseAuth.instance.currentUser!.uid) {
        count++;
      }
    }
    print(count);
    return count < Provider.of<TimerProvider>(context, listen: false).timerModel.totalCompletedSessions;
  }

  // Helper to build individual message items
  Widget buildFeedMessageItem(Map<String, dynamic> message) {
    Timestamp timestamp = message['timestamp'];
    String formattedTimestamp = DateFormat('dd MMM, hh:mm').format(timestamp.toDate());

    return Container(
        margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration( // Keep the outer container decoration if desired
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(8),
    ),
    child: ListTile(
        title: Text(message['message']!, style: const TextStyle(fontSize: 18,fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message['user']!,style: const TextStyle(fontSize: 12)),
            Text(formattedTimestamp, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        )));


    // return Container(
    //   margin: const EdgeInsets.only(bottom: 8),
    //   padding: const EdgeInsets.all(10),
    //   decoration: BoxDecoration(
    //     color: Colors.grey[200],
    //     borderRadius: BorderRadius.circular(8),
    //   ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Text(message['user']!,
    //           style: const TextStyle(fontWeight: FontWeight.bold)),
    //       Text(message['message']!),
    //       const SizedBox(height: 4), // Optional spacing
    //       Text(formattedTimestamp,
    //           style: const TextStyle(fontSize: 12, color: Colors.grey)),
    //       //Add a like and report icons below the timestamp
    //       // Row(mainAxisAlignment: MainAxisAlignment.end,children: [
    //       // IconButton(
    //       //   icon: const Icon(Icons.thumb_up,size: 12,),
    //       //   onPressed: () {},
    //       // ),
    //       // IconButton(
    //       //   icon: const Icon(Icons.report,size:12),
    //       //   onPressed: () {},
    //       // )])
    //     ],
    //   ),
    // );
  }

  showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)));
  }
}