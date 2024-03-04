import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';
import 'package:thakkalitimer/screens/FeedUI.dart';
import 'package:thakkalitimer/screens/FriendsScreen.dart';
import 'package:thakkalitimer/screens/TimerScreen.dart';
import 'model/TimerProvider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  PersistentTabController? _tabController;
  DocumentSnapshot? timerReference;
  String appBarTitle = 'Thakkali Timer';

  @override
  void initState() {
    super.initState();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider.of<TimerProvider>(context, listen: false).checkAndFetchTimers();
  }

  @override
  void dispose() {
    _tabController?.dispose(); // Di
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return
      Consumer<TimerProvider>(builder: (context, timerProvider, child) {
        _tabController = PersistentTabController(initialIndex: timerProvider.timerModel.selectedScreen);
      return LayoutBuilder(
        builder: (context, constraints) {
      if (constraints.maxWidth >= 600) {
        // Adjust the breakpoint as needed
        // Desktop Layout: Split View
        return Scaffold(
          body: Row(children: [
            Expanded(flex: 2, child: buildSideMenu(context)),
            // Main content area
            Expanded(flex: 8, child: buildPersistentNavigation()),
          ]),
        );
      } else {
        return Scaffold(
          // Use drawer for mobile and for desktop browsers with a larger width use SplitView instead of Drawer
          drawer: buildSideMenu(context),
          appBar: AppBar(
            title: Text(appBarTitle),
            leading: Builder(
                builder: (context) => // Hamburger button for smaller screens
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    )),
          ),
          body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: buildPersistentNavigation()),
          ),
        );
      }
    });
      });
  }

  Widget buildPersistentNavigation() {
    return PersistentTabView(
      context,
      screenTransitionAnimation: const ScreenTransitionAnimation(
        // Screen transition animation on change of selected tab.
        animateTabTransition: true,
        curve: Curves.easeInOut,
        duration: Duration(milliseconds: 400),
      ),
      controller: _tabController,
      screens: [
        FriendsScreen(),
        TimerScreen(), // Create if not defined.
        FeedUI(),
      ],
      itemAnimationProperties: const ItemAnimationProperties(
        // Navigation Bar's items animation properties.
        duration: Duration(milliseconds: 400),
        curve: Curves.ease,
      ),
      items: _buildNavBarItems(),
      onItemSelected: (index) => _onItemTapped(index),
      navBarStyle: NavBarStyle.style6, // Choose a style you like
    );
  }

  List<PersistentBottomNavBarItem> _buildNavBarItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.people),
        title: ("Friends"),
        activeColorPrimary: Colors.blue, // Your styling
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.timer),
        title: ("Timer"),
        activeColorPrimary: Colors.blue, // Your styling
        inactiveColorPrimary: Colors.grey,
        // ... style similarly
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.feed),
        title: ("Feeds"),
        activeColorPrimary: Colors.blue, // Your styling
        inactiveColorPrimary: Colors.grey,
        // ... style similarly
      )
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _tabController!.index = index;
      switch (index) {
        case 0:
          appBarTitle = 'Friends';
          break;
        case 1:
          appBarTitle = 'Thakkali Timer';
          break;
        case 2:
          appBarTitle = 'Feed';
          break;
      }
    });
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
      onTap: () {
        FirebaseAuth.instance.signOut();
        Provider.of<TimerProvider>(context, listen: false).clearTimerReference();
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
