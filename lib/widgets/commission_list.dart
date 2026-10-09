import 'package:flutter/material.dart';

import '../models/commission.dart';
import '../screens/commission_detail_screen.dart';
import '../screens/commission_edit_screen.dart';
import '../services/auth_service.dart';
import '../services/commission_service.dart';
import '../services/content_filter_service.dart';
import '../theme/app_theme.dart';
import '../utils/disclaimer.dart';
import 'auth_guard.dart';
import 'commission_card.dart';
import 'segment_tabs.dart';

/// The 委託 area: filter, list and the publish button.
class CommissionList extends StatefulWidget {
  const CommissionList({super.key});

  @override
  State<CommissionList> createState() => _CommissionListState();
}

class _CommissionListState extends State<CommissionList> {
  final _service = CommissionService();

  List<Commission>? _all;
  Object? _error;
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _all = list;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_all == null) _error = e;
      });
    }
  }

  Future<void> _publish() async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const CommissionEditScreen()),
    );
    if (created == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('委託已發布')));
      }
    }
  }

  List<Commission> _visible(List<Commission> all) {
    final me = AuthService().currentUser?.uid;
    final showNsfw = ContentFilterService.instance.showNsfw;
    return all.where((c) {
      if (_filter == 1 && c.type != CommissionType.request) return false;
      if (_filter == 2 && c.type != CommissionType.offer) return false;
      if (c.userId == me) return true;
      if (c.hiddenByReports) return false;
      if (c.isNsfw && !showNsfw) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SegmentTabs(
                labels: const ['全部', '委託需求', '接單展示'],
                selected: _filter,
                onChanged: (i) => setState(() => _filter = i),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
        Positioned(
          right: 18,
          bottom: 18,
          child: GestureDetector(
            onTap: _publish,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Text(
                '發布委託',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_error != null && _all == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('讀取失敗，請確認網路連線'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() => _error = null);
                _load();
              },
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }
    if (_all == null) return const Center(child: CircularProgressIndicator());

    return ListenableBuilder(
      listenable: ContentFilterService.instance,
      builder: (context, _) {
        final list = _visible(_all!);
        return RefreshIndicator(
          color: AppColors.vermilion,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 90),
            children: [
              _notice(context),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text('目前沒有委託', style: TextStyle(color: AppColors.muted)),
                  ),
                )
              else
                for (final c in list)
                  CommissionCard(
                    commission: c,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CommissionDetailScreen(commissionId: c.id),
                        ),
                      );
                      _load();
                    },
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _notice(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '平台只刊登委託資訊，交易與付款請在站外自行確認。',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF5C544C)),
            ),
          ),
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('免責聲明'),
                content: SingleChildScrollView(
                  child: Text(commissionDisclaimer, style: const TextStyle(height: 1.6)),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
                ],
              ),
            ),
            child: const Text('免責聲明'),
          ),
        ],
      ),
    );
  }
}
