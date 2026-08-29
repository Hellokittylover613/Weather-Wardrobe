import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/wardrobe_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_settings.dart';

/// Instagram-style slide-in settings panel, shown via
/// Scaffold.endDrawer from MainShell.
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final WardrobeService _wardrobeService = WardrobeService();

  bool _busy = false;

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // CHANGE DISPLAY NAME
  // ============================================================

  Future<void> _changeDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change display name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    setState(() => _busy = true);

    try {
      await user.updateDisplayName(newName);
      await user.reload();

      if (!mounted) return;
      setState(() => _busy = false);

      _showMessage('Display name updated!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);

      _showMessage('Could not update name: $e');
    }
  }

  // ============================================================
  // CHANGE PASSWORD (requires re-authentication)
  // ============================================================

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      _showMessage('No email on this account.');
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'New password (min 6 characters)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;

    if (currentPassword.isEmpty || newPassword.length < 6) {
      _showMessage(
        'Please fill both fields (new password needs 6+ characters).',
      );
      return;
    }

    setState(() => _busy = true);

    try {
      // Re-authenticate first — Firebase requires a recent login
      // before allowing sensitive changes like password updates.
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      if (!mounted) return;
      setState(() => _busy = false);

      _showMessage('Password updated successfully!');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);

      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Current password is incorrect.';
          break;
        case 'weak-password':
          message = 'Please choose a stronger password.';
          break;
        default:
          message = 'Could not update password: ${e.message}';
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);

      _showMessage('Could not update password: $e');
    }
  }

  // ============================================================
  // DELETE ACCOUNT (requires re-authentication)
  // ============================================================

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and cannot be undone. '
          'Your wardrobe data on the server will not be automatically removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Email/password re-auth prompt before deleting (Firebase requires
    // a recent login for this sensitive action).
    String? password;

    if (user.email != null) {
      final passwordController = TextEditingController();

      password = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm your password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (password == null || password.isEmpty) return;
    }

    setState(() => _busy = true);

    try {
      if (user.email != null && password != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);
      }

      await user.delete();

      if (!mounted) return;

      Navigator.of(context).pop(); // close the drawer

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);

      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect password.';
          break;
        default:
          message = 'Could not delete account: ${e.message}';
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);

      _showMessage('Could not delete account: $e');
    }
  }

  // ============================================================
  // CLEAR ALL WARDROBE ITEMS
  // ============================================================

  Future<void> _clearWardrobe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear entire wardrobe?'),
        content: const Text(
          'This permanently deletes every item in your wardrobe. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);

    try {
      final items = await _wardrobeService.getWardrobeItems();

      for (final item in items) {
        final id = item['id'];
        if (id == null) continue;

        try {
          await _wardrobeService.deleteWardrobeItem(int.parse(id.toString()));
        } catch (_) {
          // Continue deleting the rest even if one item fails.
        }
      }

      if (!mounted) return;
      setState(() => _busy = false);

      _showMessage('Wardrobe cleared.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);

      _showMessage('Could not clear wardrobe: $e');
    }
  }

  // ============================================================
  // CONTACT / FEEDBACK
  // ============================================================

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@weatherwardrobe.app',
      query: 'subject=Weather Wardrobe Feedback',
    );

    try {
      final launched = await launchUrl(uri);

      if (!launched) {
        _showMessage('Could not open email app.');
      }
    } catch (e) {
      _showMessage('Could not open email app: $e');
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.plum,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.plum),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                _sectionLabel('Preferences'),

                ValueListenableBuilder<bool>(
                  valueListenable: AppSettings.instance.useCelsius,
                  builder: (context, useCelsius, _) {
                    return SwitchListTile(
                      title: const Text(
                        'Use Celsius',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.plum,
                        ),
                      ),
                      subtitle: Text(
                        useCelsius ? 'Showing °C' : 'Showing °F',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.plum.withOpacity(0.6),
                        ),
                      ),
                      value: useCelsius,
                      activeColor: AppColors.coral,
                      onChanged: (_) => AppSettings.instance.toggleUnits(),
                    );
                  },
                ),

                const Divider(height: 1),

                _sectionLabel('Account'),

                ListTile(
                  leading: const Icon(
                    Icons.email_outlined,
                    color: AppColors.plum,
                  ),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? 'Not signed in'),
                ),

                ListTile(
                  leading: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.plum,
                  ),
                  title: const Text('Display Name'),
                  subtitle: Text(
                    user?.displayName?.isNotEmpty == true
                        ? user!.displayName!
                        : 'Not set',
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: _changeDisplayName,
                ),

                ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                    color: AppColors.plum,
                  ),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: _changePassword,
                ),

                const Divider(height: 1),

                _sectionLabel('Wardrobe'),

                ListTile(
                  leading: const Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Clear All Wardrobe Items',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: _clearWardrobe,
                ),

                const Divider(height: 1),

                _sectionLabel('Support'),

                ListTile(
                  leading: const Icon(
                    Icons.mail_outline,
                    color: AppColors.plum,
                  ),
                  title: const Text('Contact / Feedback'),
                  onTap: _contactSupport,
                ),

                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.plum),
                  title: Text('About Weather Wardrobe'),
                  subtitle: Text('Version 1.0.0'),
                ),

                const Divider(height: 1),

                _sectionLabel('Danger Zone'),

                ListTile(
                  leading: const Icon(
                    Icons.person_remove_outlined,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: _deleteAccount,
                ),

                const SizedBox(height: 24),
              ],
            ),

            if (_busy)
              Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.plum.withOpacity(0.45),
        ),
      ),
    );
  }
}
