// Import statements remain unchanged
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chattify/screens/auth/login_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../api/Apis.dart';
import '../helpers/dialogs.dart';
import '../main.dart';
import '../models/chat_user.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController nameController;
  late final TextEditingController aboutController;
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    aboutController = TextEditingController(text: widget.user.about);
  }

  @override
  void dispose() {
    nameController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.redAccent,
          onPressed: () async {
            Dialogs.showProgressBar(context);
            await APIs.auth.signOut().then((value) async {
              await GoogleSignIn().signOut();
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            });
          },
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
        body: Form(
          key: _formKey,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDFC8FD), Color(0xFFCEB2FA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                mq.width * .05,
                mq.height * .12,
                mq.width * .05,
                20,
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        _image != null
                            ? Hero(
                          tag: 'avatar-${widget.user.id}',
                          child: ClipOval(
                            child: Image.file(
                              File(_image!),
                              width: mq.height * .2,
                              height: mq.height * .2,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                            : Hero(
                          tag: 'avatar-${widget.user.id}',
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.user.image,
                              width: mq.height * .2,
                              height: mq.height * .2,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                              const CircleAvatar(
                                  child: Icon(CupertinoIcons.person)),
                            ),
                          ),
                        ),

                        // Edit icon (Always visible)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: MaterialButton(
                            elevation: 1,
                            onPressed: _showBottomSheet,
                            shape: const CircleBorder(),
                            color: const Color(0xFFBC9EFB),
                            child: const Icon(Icons.edit),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    widget.user.email,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _glassCard(
                    child: TextFormField(
                      controller: nameController,
                      validator: (val) =>
                      val != null && val.isNotEmpty ? null : 'Required Field',
                      onSaved: (val) => APIs.me.name = val ?? '',
                      decoration: _inputDecoration('Name', Icons.person),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _glassCard(
                    child: TextFormField(
                      controller: aboutController,
                      validator: (val) =>
                      val != null && val.isNotEmpty ? null : 'Required Field',
                      onSaved: (val) => APIs.me.about = val ?? '',
                      maxLines: 1,
                      decoration: _inputDecoration('About', Icons.info_outline),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: mq.width * .55,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFBC9EFB),
                        shape: const StadiumBorder(),
                        elevation: 8,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          APIs.updateUserInfo().then((value) {
                            Dialogs.showSnackbar(
                                context, 'Profile Updated Successfully!!');
                          });
                        }
                      },
                      icon: const Icon(Icons.edit, size: 24),
                      label: const Text(
                        'UPDATE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 46),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet() {
    final mq = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(
            top: mq.height * .03,
            bottom: mq.height * .05,
          ),
          children: [
            const Text(
              'Pick Profile Picture',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: mq.height * .02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // From Gallery
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .3, mq.height * .15),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      log('Image Path: ${picked.path}');
                      setState(() => _image = picked.path);
                      Navigator.pop(context);

                      // Upload to Cloudinary
                      Dialogs.showProgressBar(context);
                      await APIs.updateProfilePictureCloudinary(File(picked.path));
                      Navigator.pop(context);

                      Dialogs.showSnackbar(context, 'Profile Picture Updated!');
                    }
                  },
                  child: Image.asset('assets/images/gallery.png'),
                ),

                // From Camera
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .3, mq.height * .15),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? picked = await picker.pickImage(source: ImageSource.camera);
                    if (picked != null) {
                      log('Image Path: ${picked.path}');
                      setState(() => _image = picked.path);
                      Navigator.pop(context);

                      // Upload to Cloudinary
                      Dialogs.showProgressBar(context);
                      await APIs.updateProfilePictureCloudinary(File(picked.path));
                      Navigator.pop(context);

                      Dialogs.showSnackbar(context, 'Profile Picture Updated!');
                    }
                  },
                  child: Image.asset('assets/images/camera.png'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

}

// Glass-style container
Widget _glassCard({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.22),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: child,
    ),
  );
}

// Input field style
InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: Colors.black),
    hintText: 'Your $label',
    label: Text(label, style: const TextStyle(color: Colors.black)),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.white24),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFBC9EFB), width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
