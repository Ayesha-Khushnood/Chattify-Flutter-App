import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewProfileScreen extends StatelessWidget {
  final String imageUrl;
  final String name;

  const ViewProfileScreen({
    super.key,
    required this.imageUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(name, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) =>
            const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) =>
            const Icon(Icons.error, color: Colors.white),
            width: mq.width,
            height: mq.width,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
