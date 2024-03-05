import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thakkalitimer/DBHelper.dart';
import 'package:thakkalitimer/model/TimerModel.dart';
import 'package:thakkalitimer/model/TimerProvider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {

  Timer? _timer;
  TimerModel? timerModel;

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    timerModel = timerProvider?.timerModel;
    return buildTimerSection();
  }

  //Flutter app is built for android,  to handle onpause and onresume events, as mobile screen is switched on and off
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_timer != null) {
        // pause the timer
        _timer?.cancel();
        timerModel?.systemPausedTimeStamp=DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (timerModel?.isTimerRunning == true) {
        int secondsLapsed= DateTime.now().difference(timerModel!.systemPausedTimeStamp).inSeconds;
        timerModel?.remainingTime = timerModel!.remainingTime - secondsLapsed;
        _startTimer();
      }
    }
  }


  void _startTimer() async {
    //TODO move the code to timerprovider
    final timerModel =
        Provider.of<TimerProvider>(context, listen: false).timerModel;
    if (textController.text.isEmpty) {
      focusNode.requestFocus();
      showMessage('Please enter a task label');
      return;
    }
    timerModel?.timerName = textController.text.toString().trim();

    if (timerModel.timerReference != null &&
        FirebaseAuth.instance.currentUser == null) {
      if (!timerModel.isOwnTimer) {
        showMessage('Login to join your friends timer');
      }
      return;
    }
    loading();
    timerModel.timerReference ??=
        await DBHelper.createTimer(name: timerModel!.timerName!);
    if (timerModel.timerReference != null) {
      timerModel.sessionReference = await DBHelper.createSession(
          timerReference: timerModel.timerReference);
    }
    closeLoading();
    if (_timer != null) {
      _timer?.cancel();
    }
    setState(() {
      timerModel.isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _updateTimer();
    });
  }

  void _updateTimer() async {
    if (timerModel!.remainingTime > 0) {
      timerModel!.remainingTime--;
    } else {
      _timer?.cancel();
      await Provider.of<TimerProvider>(context, listen: false)
          .completeSession();
      timerModel!.remainingTime = timerModel!.totalTime;
    }

    setState(() {});
  }

  void closeLoading() {
    // Navigator.of(context).pop();
  }

  void loading() {
    //Show Snackbar
    showMessage('Starting..');
  }

  void _pauseTimer() {
    if (timerModel?.sessionReference != null) {
      DBHelper.updateSession(
          status: 1, sessionDocReference: timerModel?.sessionReference);
    }
    _timer?.cancel();
    setState(() {
      timerModel?.isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    timerModel?.isTimerRunning = false;
    setState(() {
      timerModel!.remainingTime = timerModel!.totalTime;
    });
    if (timerModel?.sessionReference != null) {
      DBHelper.updateSession(
          status: 0,
          sessionDocReference: timerModel?.sessionReference,
          isReset: true);
    }
  }

  void _deleteTimer() {
    //Show a confirmation dialog and on yes delete,

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Delete Timer'),
              content:
                  const Text('Are you sure you want to delete this timer?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No')),
                TextButton(
                    onPressed: () => {
                          Provider.of<TimerProvider>(super.context,
                                  listen: false)
                              .deleteTimer(),
                          Navigator.pop(context)
                        },
                    child: const Text('Yes')),
              ],
            ));
  }
  // ... (Rest of your code – buildTimer, formatTime, etc. should remain the same)

  @override
  void dispose() {
    _timer?.cancel(); // Ensure timer is canceled when the widget is disposed
    super.dispose();
  }

  Widget buildTimerSection() {
    //Wrap the below widget inside a singlechildscrollview
    return Center(
        child: SingleChildScrollView(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      buildTaskLabel(),
      buildOwnerName(),
      const SizedBox(height: 20),
      buildTimer(),
      const SizedBox(height: 10),
      buildButtonRow(),
      const SizedBox(height: 20), // Adjust spacing
      buildSignInOrInvite(),
    ])));
  }

  Widget buildOwnerName() {
    return Text(
      (timerModel!.ownerName != null ? 'by ${timerModel!.ownerName!}' : ''),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
    );
  }

  Widget buildTimer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          width: timerModel!.isTimerRunning ? 300 : 200,
          height: timerModel!.isTimerRunning ? 300 : 200,
          child: SizedBox(
              width: 300,
              height: 300,
              child: CircularProgressIndicator(
                value: 1 - (timerModel!.remainingTime / timerModel!.totalTime), // Calculate progress
                strokeWidth: 20,
                valueColor: const AlwaysStoppedAnimation(
                    Colors.deepPurple), // Accent color
                backgroundColor: Colors.grey[300],
              )),
        ),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 500), // Format time as MM:SS
            style: TextStyle(
              fontSize: timerModel!.isTimerRunning ? 64 : 48,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            child: Text(formatTime(timerModel!.remainingTime)),
          ),
          buildThakkalis(),
        ])
      ],
    );
  }

  Widget buildThakkalis() {
    if (timerModel!.totalCompletedSessions > 4) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(
          'assets/images/tomato.png', // Or 'assets/images/my_icon.png'
          width: 18, // Adjust size as needed
          height: 18,
        ),
        Text('x${timerModel!.totalCompletedSessions}')
      ]);
    } else if (timerModel!.totalCompletedSessions > 0) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ...buildTomatoes(timerModel!.totalCompletedSessions),
      ]);
    } else {
      return Container();
    }
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

// Helper function to format time
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // New Method to Build the Button Row
  Widget buildButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: (timerModel!.isTimerRunning) ? 0.0 : 1.0,
            child: IconButton(
              // Reset Button (Left)
              onPressed: _resetTimer,
              icon: const Icon(Icons.replay_outlined,
                  color: Colors.black, size: 24),
            )),
        // Spacing between buttons
        IconButton(
          onPressed: timerModel!.isTimerRunning ? _pauseTimer : _startTimer,
          icon: Icon(
            timerModel!.isTimerRunning ? Icons.pause_circle : Icons.play_arrow,
            color: Colors.black,
            size: 64, // Increased icon size
          ),
        ),
        AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: (timerModel!.isTimerRunning) ? 0.0 : 1.0,
            child: IconButton(
              onPressed: _deleteTimer,
              icon: Icon(
                Icons.remove_circle_outline,
                color: Colors.black,
                size: 24,
              ),
            )),
      ],
    );
  }

  final focusNode = FocusNode();
  TextEditingController textController = TextEditingController();

  Widget buildTaskLabel() {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _handleTaskUpdate(textController.text);
      }
    });
    textController.text = timerModel?.timerName ?? '';
    return (!timerModel!.isOwnTimer || timerModel!.isTimerRunning)
        ? Text(
            timerModel?.timerName ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          )
        :
        // Task Label
        TextFormField(
            enabled: timerModel!.isOwnTimer && !timerModel!.isTimerRunning,
            focusNode: focusNode,
            controller: textController,
            textAlign: TextAlign.center,
            maxLength: 15,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter Task name';
              }
              return null; // Indicates no error if validation passes
            },
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
                border: InputBorder.none, // Remove default border
                hintText: 'Enter Task',
                counterText: ''),
            onFieldSubmitted: (value) {
              _handleTaskUpdate(value);
            },
          );
  }

  void _handleTaskUpdate(String value) async {
    if (value.trim().isNotEmpty && value != timerModel?.timerName) {
      //TODO there is a flaw in the design, this screen update works via setState and we still call notifyListeners in provider, which notifies only the sidemenu for now
      // To add a consumer in timerscreen too, and use notify instead of setState
      Provider.of<TimerProvider>(context, listen: false)
          .createOrUpdateTimer(value);
    }
  }

  Widget buildSignInOrInvite() {
    return AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: (timerModel!.isTimerRunning) ? 0.0 : 1.0,
        child: ElevatedButton(
            onPressed: () {
              if (FirebaseAuth.instance.currentUser == null) {
                showModalBottomSheet(
                    isDismissible: true,
                    context: context,
                    builder: (context) => SignInScreen(actions: [
                          AuthStateChangeAction<SignedIn>((context, state) {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/',
                                arguments: [state.user?.uid]);
                            Provider.of<TimerProvider>(context, listen: false)
                                .checkAndFetchTimers(null);
                          }),
                        ]));
              } else {
                //TODO Share Timer
                //Validate taskLabel and createTimer
                if (timerModel?.timerReference != null) {
                  String? timerId = timerModel?.timerReference?.id;
                  String url = 'https://thakkalitimer.web.app/?timer=$timerId';
                  String text =
                      'Want to unlock the secret to focused work? Join me on this Thakkali timer app 🍅 \n$url';
                  Share.share(text);
                  // Clipboard.setData(ClipboardData(text: url)).then((value) =>
                  //     showMessage(
                  //         'Invite copied, paste where you want to share'));
                }
              }
            },
            child: Text(
              '${FirebaseAuth.instance.currentUser != null ? '' : 'Login to '}Invite',
              textAlign: TextAlign.center, // Ensures text remains centered
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )));
  }

  showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)));
  }
}
