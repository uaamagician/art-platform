import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(post.title)),
      body: ListView(
        children: [
          InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: post.imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: post.userPhotoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(post.userPhotoUrl)
                          : null,
                      child: post.userPhotoUrl.isEmpty
                          ? Text(post.userName.isNotEmpty ? post.userName[0] : '?')
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      post.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('讚 ${post.likesCount}'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(post.description),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(post.category)),
                    ...post.tags.map((tag) => Chip(label: Text('#$tag'))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
