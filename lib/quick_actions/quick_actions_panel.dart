import 'package:flutter/material.dart';
import 'package:fureverhealthy/quick_actions/community/community.dart';
import 'package:fureverhealthy/quick_actions/feeding.dart';
import 'package:fureverhealthy/quick_actions/grooming.dart';
import 'package:fureverhealthy/quick_actions/medications.dart';

class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3C8FF), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .9,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _QuickAction(
                label: 'Communities',
                iconPath: 'assets/pawscomm.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CommunityPage()),
                  );
                },
              ),
              _QuickAction(
                label: 'Feeding',
                iconPath: 'assets/feed.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedingPage()),
                  );
                },
              ),
              _QuickAction(
                label: 'Grooming',
                iconPath: 'assets/groom.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GroomingPage()),
                  );
                },
              ),
              _QuickAction(
                label: 'Medications',
                iconPath: 'assets/medications.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MedicationsPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback? onTap;
  const _QuickAction({required this.label, required this.iconPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE6FFF7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: Image.asset(iconPath, height: 36)),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
