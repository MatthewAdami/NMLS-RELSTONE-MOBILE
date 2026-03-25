import 'package:flutter/material.dart';
import 'package:nmls_mobile/ce_tracker_screen.dart';
import 'package:nmls_mobile/courses_screen.dart';
import 'package:nmls_mobile/dashboard_screen.dart';
import 'package:nmls_mobile/exam_prep_screen.dart';
import 'package:nmls_mobile/how_it_works_screen.dart';
import 'package:nmls_mobile/widgets/more_sheet.dart';

const _kBlue = Color(0xFF2EABFE);
const _kBlueFaint = Color(0x1A2EABFE);
const _kBorder = Color(0x1A020817);
const _kSurface = Color(0xD0FFFFFF);
const _kInactive = Color(0xFFBBBBBB);

enum AppNavTab { home, courses, examPrep, ceTracker }

class AppBottomNav extends StatelessWidget {
  final AppNavTab activeTab;
  final String userName;
  final String userEmail;
  final String? token;
  final String nmlsId;
  final String state;
  final VoidCallback? onSignOut;

  const AppBottomNav({
    super.key,
    required this.activeTab,
    required this.userName,
    required this.userEmail,
    this.token,
    this.nmlsId = 'Not set',
    this.state = 'Not set',
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.menu_book_outlined, 'active': Icons.menu_book_rounded, 'label': 'Courses'},
      {'icon': Icons.assignment_outlined, 'active': Icons.assignment, 'label': 'Exam Prep'},
      {'icon': Icons.access_time_outlined, 'active': Icons.access_time_filled, 'label': 'CE Tracker'},
      {'icon': Icons.more_horiz, 'active': Icons.more_horiz, 'label': 'More'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(items.length, (i) {
          final tab = _tabForIndex(i);
          final active = tab != null && tab == activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onNavTap(context, i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: active ? _kBlueFaint : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      active ? items[i]['active'] as IconData : items[i]['icon'] as IconData,
                      color: active ? _kBlue : _kInactive,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i]['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: active ? _kBlue : _kInactive,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  AppNavTab? _tabForIndex(int index) {
    switch (index) {
      case 0:
        return AppNavTab.home;
      case 1:
        return AppNavTab.courses;
      case 2:
        return AppNavTab.examPrep;
      case 3:
        return AppNavTab.ceTracker;
      default:
        return null;
    }
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == 4) {
      _showMoreSheet(context);
      return;
    }

    final targetTab = _tabForIndex(index);
    if (targetTab == null || targetTab == activeTab) {
      return;
    }

    if (targetTab == AppNavTab.home) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            user: {
              'name': userName,
              'email': userEmail,
              'nmls_id': nmlsId,
              'state': state,
            },
            token: token,
          ),
        ),
      );
      return;
    }

    if (targetTab == AppNavTab.courses) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CoursesScreen(
            token: token,
            userName: userName,
            userEmail: userEmail,
          ),
        ),
      );
      return;
    }

    if (targetTab == AppNavTab.examPrep) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ExamPrepScreen(
            token: token,
            userName: userName,
            userEmail: userEmail,
          ),
        ),
      );
      return;
    }

    if (targetTab == AppNavTab.ceTracker) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CETrackerScreen(
            token: token,
            userName: userName,
            userEmail: userEmail,
          ),
        ),
      );
    }
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoreSheet(
        userName: userName,
        userEmail: userEmail,
        nmlsId: nmlsId,
        state: state,
        initial: userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
        onSignOut: onSignOut ??
            () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
        onHowItWorks: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HowItWorksScreen()),
          );
        },
      ),
    );
  }
}
