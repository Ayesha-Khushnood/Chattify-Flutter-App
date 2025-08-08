
import 'package:chattify/models/chat_user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../api/Apis.dart';
import '../main.dart';
import '../widgets/chat_user_card.dart';
import 'ProfileScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<ChatUser> list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();
    WidgetsBinding.instance.addObserver(this);
    // APIs.updateActiveStatus(true); // Mark user online
  }

  @override
  void dispose() {
    APIs.updateActiveStatus(false); // Mark user offline
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called automatically when app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      APIs.updateActiveStatus(true);
    } else if (state == AppLifecycleState.paused) {
      APIs.updateActiveStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (_isSearching) {
            setState(() => _isSearching = !_isSearching);
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: const Icon(CupertinoIcons.home),
            title: _isSearching
                ? TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search here',
              ),
              autofocus: true,
              style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
              onChanged: (val) {
                _searchList.clear();
                for (var i in list) {
                  if (i.name
                      .toLowerCase()
                      .contains(val.toLowerCase()) ||
                      i.email.toLowerCase().contains(val.toLowerCase())) {
                    _searchList.add(i);
                  }
                  setState(() {
                    _searchList;
                  });
                }
              },
            )
                : const Text('Chattify'),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() => _isSearching = !_isSearching);
                },
                icon: Icon(_isSearching
                    ? CupertinoIcons.clear_circled_solid
                    : Icons.search),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProfileScreen(user: APIs.me)),
                  );
                },
                icon: const Icon(Icons.person),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final emailController = TextEditingController();

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: const [
                      Icon(Icons.person_add, color: Color(0xFFBC9EFB)),
                      SizedBox(width: 8),
                      Text('Add User'),
                    ],
                  ),
                  content: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      prefixIcon:
                      const Icon(Icons.email, color: Color(0xFFBC9EFB)),
                      hintText: 'Enter user email',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: Color(0xFFB28EFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFB28EFF), width: 2),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFFB28EFF)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Add logic later
                      },
                      child: const Text(
                        'Add',
                        style: TextStyle(color: Color(0xFFB28EFF)),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          body: StreamBuilder(
            stream: APIs.getAllUsers(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());
                case ConnectionState.active:
                case ConnectionState.done:
                  final data = snapshot.data?.docs;
                  list = data
                      ?.map((e) => ChatUser.fromJson(e.data()))
                      .toList() ??
                      [];

                  if (list.isNotEmpty) {
                    return ListView.builder(
                      itemCount:
                      _isSearching ? _searchList.length : list.length,
                      padding: EdgeInsets.only(top: mq.height * .01),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ChatUserCard(
                            user: _isSearching
                                ? _searchList[index]
                                : list[index]);
                      },
                    );
                  } else {
                    return const Center(
                      child: Text(
                        'No user found!!!',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  }
              }
            },
          ),
        ),
      ),
    );
  }
}
