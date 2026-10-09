import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/commission.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'user_avatar.dart';

/// List card for a commission request / offer.
class CommissionCard extends StatelessWidget {
  final Commission commission;
  final VoidCallback onTap;

  const CommissionCard({super.key, required this.commission, required this.onTap});

  static const _offerGreen = Color(0xFF3F7D5B);

  @override
  Widget build(BuildContext context) {
    final c = commission;
    final isRequest = c.type == CommissionType.request;
    final typeColor = isRequest ? AppColors.vermilion : _offerGreen;

    return Opacity(
      opacity: c.isOpen && !c.expired ? 1 : 0.62,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _badge(c.type.label, typeColor),
                    if (!c.isOpen) ...[const SizedBox(width: 6), _badge('已結案', AppColors.muted)],
                    if (c.isOpen && c.expired) ...[const SizedBox(width: 6), _badge('已過期', AppColors.muted)],
                    if (c.isNsfw) ...[const SizedBox(width: 6), _badge('成人', Colors.red.shade400)],
                    const Spacer(),
                    Text(timeAgo(c.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
                          ),
                          if (c.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              c.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF5C544C)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (c.imageUrls.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: c.imageUrls.first,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              Container(width: 72, height: 72, color: AppColors.tint),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (c.budgetText.isNotEmpty) _info('預算', c.budgetText),
                    if (c.deadline != null) _info(isRequest ? '期限' : '可接單至', formatDate(c.deadline!)),
                    if (c.category.isNotEmpty) _info('分類', c.category),
                  ],
                ),
                if (c.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    c.tags.map((t) => '#$t').join('  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.vermilion,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    UserAvatar(photoUrl: c.userPhotoUrl, name: c.userName, radius: 11),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.userName.isNotEmpty ? c.userName : '創作者',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      );

  Widget _info(String label, String value) => Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label  ', style: const TextStyle(color: AppColors.muted)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        style: const TextStyle(fontSize: 13),
      );
}
