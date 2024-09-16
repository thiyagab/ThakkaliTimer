
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:thakkalitimer/screens/FeedUI.dart';
import 'package:thakkalitimer/screens/FriendsScreen.dart';
import 'package:thakkalitimer/screens/SideMenu.dart';
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
  void dispose() {
    _tabController?.dispose();
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
        // Desktop Layout: Split View
        return Scaffold(
          body: Row(children: [
            const Expanded(flex: 2, child: SideMenu()),
            // Main content area
            Expanded(flex: 8, child: buildPersistentNavigation()),
          ]),
        );
      } else {
        return Scaffold(
          // Use drawer for mobile and for desktop browsers with a larger width use SplitView instead of Drawer
          drawer: SideMenu(),
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
      animationSettings: const NavBarAnimationSettings(
          navBarItemAnimation: ItemAnimationSettings(
            // Navigation Bar's items animation properties.
            duration: Duration(milliseconds: 400),
            curve: Curves.ease,
          ),
      screenTransitionAnimation: ScreenTransitionAnimationSettings(
        // Screen transition animation on change of selected tab.
        animateTabTransition: true,
        duration: Duration(milliseconds: 300),
        screenTransitionAnimationType:
        ScreenTransitionAnimationType.fadeIn,
      )),
      controller: _tabController,
      screens: [
        FriendsScreen(),
        TimerScreen(), // Create if not defined.
        FeedUI(),
      ],
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
}
