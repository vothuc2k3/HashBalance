import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';

class PostImagesGrid extends StatelessWidget {
  final List<String> images;

  const PostImagesGrid({
    super.key,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return Center(
        child: _buildImage(context, images.first),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: images.map((imageUrl) {
          return _buildImage(context, imageUrl);
        }).toList(),
      ),
    );
  }

  Widget _buildImage(BuildContext context, String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => showImage(context, imageUrl),
        child: kIsWeb
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                progressIndicatorBuilder: (context, url, downloadProgress) {
                  return const Loading();
                },
                imageBuilder: (context, imageProvider) {
                  return FadeInImage(
                    placeholder:
                        const AssetImage('assets/post_image_placeholder.png'),
                    image: imageProvider,
                    fadeInDuration: const Duration(seconds: 1),
                    fadeOutDuration: const Duration(seconds: 1),
                  );
                },
              ),
      ),
    );
  }
}
