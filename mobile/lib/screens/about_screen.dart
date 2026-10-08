import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _appName = 'Shop To Door';
  static const String _developerName = 'Ekuabou Riame';
  static const String _phoneNumber = '+91 81328436692';
  static const String _supportEmail = 'shoptodoortamenglong@gmail.com';

  Future<void> _callSupport() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: _phoneNumber,
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _emailSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Shop To Door Support',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'Shop To Door respects your privacy. '
              'We collect and use information necessary to provide '
              'shopping, ordering, payment, delivery, and account services. '
              'Your information is handled for the purpose of providing '
              'and improving the Shop To Door service.\n\n'
              'We do not sell your personal information to third parties. '
              'Payment information is processed through the applicable '
              'payment service providers.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTerms(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms & Conditions'),
          content: const SingleChildScrollView(
            child: Text(
              'By using Shop To Door, you agree to use the application '
              'responsibly and provide accurate information when creating '
              'an account or placing an order.\n\n'
              'Product availability, prices, delivery charges, payment '
              'methods, and delivery times may vary. Orders are subject '
              'to availability and confirmation.\n\n'
              'Shop To Door reserves the right to update these terms '
              'when necessary.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Logo
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/shop-to-door-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // App name
              Text(
                _appName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your shopping, delivered to your door.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Description
              _buildSection(
                context,
                icon: Icons.info_outline,
                title: 'About Shop To Door',
                child: const Text(
                  'Shop To Door is a convenient e-commerce platform '
                  'designed to make everyday shopping simple and accessible. '
                  'Browse products, add items to your cart, choose from '
                  'online payment or Cash on Delivery, place orders, and '
                  'track your delivery—all in one place.',
                  textAlign: TextAlign.justify,
                ),
              ),

              const SizedBox(height: 16),

              // Contact / Support
              _buildSection(
                context,
                icon: Icons.support_agent,
                title: 'Contact & Support',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Phone'),
                      subtitle: const Text(_phoneNumber),
                      trailing: IconButton(
                        icon: const Icon(Icons.call_outlined),
                        onPressed: _callSupport,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: const Text(_supportEmail),
                      trailing: IconButton(
                        icon: const Icon(Icons.mail_outline),
                        onPressed: _emailSupport,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Developer
              _buildSection(
                context,
                icon: Icons.code,
                title: 'Developer Information',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: const Text('Developer'),
                  subtitle: const Text(_developerName),
                ),
              ),

              const SizedBox(height: 16),

              // Version
              _buildSection(
                context,
                icon: Icons.apps,
                title: 'App Information',
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.verified_outlined),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
              ),

              const SizedBox(height: 16),

              // Privacy Policy
              _buildActionTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => _showPrivacyPolicy(context),
              ),

              const SizedBox(height: 10),

              // Terms
              _buildActionTile(
                context,
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () => _showTerms(context),
              ),

              const SizedBox(height: 30),

              Text(
                '© ${DateTime.now().year} $_appName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}