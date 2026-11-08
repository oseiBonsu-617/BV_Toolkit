import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/profile_screen.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// The signed-in user's initials circle. Opens Profile on the root navigator,
/// which hides the bottom bar.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    return Tooltip(
      message: 'Profile',
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
          rootNavigator: true,
        ).push(appRoute(const ProfileScreen())),
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(right: 12),
          decoration: const BoxDecoration(
            color: kPrimary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            user?.initials ?? '?',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
