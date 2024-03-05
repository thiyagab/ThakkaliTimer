import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thakkalitimer/model/TimerProvider.dart';

class SideMenu extends StatefulWidget{
  const SideMenu({super.key});


  @override
  _SideMenuState createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu>{

  @override
  Widget build(BuildContext context) {
    return buildSideMenu(context);
  }

  Widget buildSideMenu(BuildContext context) {
    return Consumer<TimerProvider>(
        builder: (context, timerProvider, child) => Drawer(
          child: ListView(
            padding: const EdgeInsets.all(5),
            children: [
              DrawerHeader(
                // Consider a header
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: buildGreetUser(),
              ),
              const Padding(
                padding: EdgeInsets.only(
                    left: 16.0, top: 16.0), // Section Spacing
                child: Text('Thakkalis',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                  title: const Text('Create New Timer'),
                  onTap: () {
                    Provider.of<TimerProvider>(context, listen: false)
                        .clearTimerReference();
                    checkAndCloseDrawer();
                  }),
              ...buildTimersMenu(timerProvider),
              const Padding(
                padding: EdgeInsets.only(
                    left: 16.0, top: 16.0), // Section Spacing
                child: Text('Invited Thakkalis',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...buildInvitedTimersMenu(timerProvider),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Statistics'),
                onTap: () {
                  // ... Navigate to settings
                  checkAndCloseDrawer();
                },
              ),
              ListTile(
                title: const Text('Settings'),
                onTap: () {
                  // ... Navigate to settings
                  checkAndCloseDrawer();
                },
              ),
              buildLogout(context),
            ],
          ),
        ));
  }

  checkAndCloseDrawer(){
    if(MediaQuery.of(context).size.width < 600){
      Navigator.pop(context);
    }
  }

  Widget buildLogout(BuildContext context) {
    if(FirebaseAuth.instance.currentUser == null){
      return const SizedBox.shrink();
    }
    return ListTile(
      title: const Text('Logout'),
      onTap: ()  {
        FirebaseAuth.instance.signOut();
        Provider.of<TimerProvider>(context, listen: false).clearAll();
        checkAndCloseDrawer();
      },
    );
  }

  Widget buildGreetUser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Container()), // Push text towards bottom
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Welcome ${FirebaseAuth.instance is FirebaseAuth && FirebaseAuth.instance.currentUser != null ? FirebaseAuth.instance.currentUser!.displayName : 'User'},',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        )
      ],
    );
  }

  List<ListTile> buildTimersMenu(final TimerProvider timerProvider) {
    final timerModel = timerProvider.timerModel;
    if (timerModel != null &&
        timerModel.timers != null &&
        timerModel.timers.isNotEmpty) {
      final List<ListTile> tiles = [];
      for (int index = 0; index < timerModel.timers.length; index++) {
        tiles.add(buildMenuTile(timerModel.timers[index], timerProvider));
      }
      return tiles;
    } else {
      return [];
    }
  }

  List<ListTile> buildInvitedTimersMenu(final TimerProvider timerProvider) {
    final timerModel = timerProvider.timerModel;
    if (timerModel != null &&
        timerModel.invitedTimers != null &&
        timerModel.invitedTimers.isNotEmpty) {
      final List<ListTile> tiles = [];
      for (int index = 0; index < timerModel.invitedTimers.length; index++) {
        tiles.add(buildMenuTile(timerModel.invitedTimers[index], timerProvider));
      }
      return tiles;
    } else {
      return [const ListTile(title: Text('No Invited Timers'))];
    }
  }

  buildMenuTile(DocumentSnapshot value, final TimerProvider timerProvider,){
    final timerData =
    value.data() as Map<String, dynamic>;
    return  ListTile(
      title: Text(timerData['name'] ?? 'Untitled Timer'),
      onTap: () {
        //TODO show some loading, as we fetch all sessions again here, should figure out a way to cache this
        timerProvider.setTimerReference(
            value.reference,
            timerData['name'],
            timerData['owner']);
        //Check if its desktop browser with larger width, if not pop the drawer
        if (MediaQuery.of(context).size.width < 600) {
          Navigator.pop(context);
        }
      },
    );

  }
}