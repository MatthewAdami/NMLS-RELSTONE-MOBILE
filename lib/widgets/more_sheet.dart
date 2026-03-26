import 'package:flutter/material.dart';
import 'package:nmls_mobile/about_relstone_screen.dart';
import 'package:nmls_mobile/contact_support_page.dart';
import 'package:nmls_mobile/edit_profile_screen.dart';
import 'package:nmls_mobile/faq_screen.dart';
import 'package:nmls_mobile/my_certificates_screen.dart';
import 'package:nmls_mobile/orders_screen.dart';

const _kDark = Color(0xFF091925);
const _kBlue = Color(0xFF2EABFE);
const _kWhite = Colors.white;

class MoreSheet extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String nmlsId;
  final String state;
  final String initial;
  final VoidCallback onSignOut;
  final VoidCallback onHowItWorks;

  const MoreSheet({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.nmlsId,
    required this.state,
    required this.initial,
    required this.onSignOut,
    required this.onHowItWorks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2EABFE), Color(0xFF1799F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.96),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, size: 44, color: _kBlue),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 14.5,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(label: 'Learning'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: _kBlue),
            title: const Text(
              'How it works',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: onHowItWorks,
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined, color: _kBlue),
            title: const Text(
              'My Certificates',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyCertificatesScreen(
                    userName: userName,
                    userEmail: userEmail,
                  ),
                ),
              );
            },
          ),
          const _SectionHeader(label: 'Account'),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined, color: _kBlue),
            title: const Text(
              'Edit Profile',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    userName: userName,
                    userEmail: userEmail,
                    userPhone: '',
                    userAddress: '',
                    state: state,
                    licenseGoal: nmlsId == 'Not set' ? '' : nmlsId,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: _kBlue),
            title: const Text(
              'Account Setup',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: () {
              // Skip the guide and go straight to the setup flow.
              Navigator.of(context, rootNavigator: true).pushNamed('/account-setup');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: _kBlue),
            title: const Text(
              'Orders & Billing',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
          ),
          const _SectionHeader(label: 'Help & Company'),
          ListTile(
            leading: const Icon(Icons.quiz_outlined, color: _kBlue),
            title: const Text(
              'FAQ Page',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined, color: _kBlue),
            title: const Text(
              'About Relstone',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AboutRelstonePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent, color: _kBlue),
            title: const Text(
              'Contact Support',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContactSupportPage(
                    userName: userName,
                    userEmail: userEmail,
                  ),
                ),
              );
            },
          ),
          const _SectionHeader(label: 'Session'),
          ListTile(
            leading: const Icon(Icons.logout, color: _kBlue),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: onSignOut,
          ),
              SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kDark.withValues(alpha: 0.55),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: _kDark.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}
