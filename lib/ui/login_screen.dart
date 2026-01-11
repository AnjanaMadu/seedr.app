import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../service/seedr.dart';
import '../service/settings_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _userCode;
  String? _deviceCode;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty)
      return;

    setState(() => _isLoading = true);
    try {
      final seedr = context.read<Seedr>();
      final settings = context.read<SettingsService>();
      final token = await seedr.login(
        _emailController.text,
        _passwordController.text,
      );
      await settings.setToken(token);
      await settings.saveAccount(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startDeviceFlow() async {
    setState(() => _isLoading = true);
    try {
      final seedr = context.read<Seedr>();
      final code = await seedr.getDeviceCode();
      setState(() {
        _userCode = code;
        _deviceCode = seedr.devc;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get device code: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkDeviceAuth() async {
    if (_deviceCode == null) return;
    setState(() => _isLoading = true);
    try {
      final seedr = context.read<Seedr>();
      final settings = context.read<SettingsService>();
      final token = await seedr.getToken(_deviceCode!);
      await settings.setToken(token);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not authorized yet or error. Check Seedr website.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                        Icons.cloud_download_rounded,
                        size: 80,
                        color: colorScheme.primary,
                      )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .rotate(delay: 200.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Seedr Android',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'High-speed cloud torrenting',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 48),
                  if (_userCode == null) ...[
                    _buildSavedAccounts(context, colorScheme),
                    const SizedBox(height: 24),
                    ..._buildEmailFields(colorScheme),
                  ] else
                    ..._buildDeviceFlow(colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailFields(ColorScheme colorScheme) {
    return [
      TextField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Email',
          prefixIcon: const Icon(Icons.email_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        keyboardType: TextInputType.emailAddress,
      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        obscureText: true,
      ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: _isLoading ? null : _login,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Sign In'),
        ),
      ).animate().scale(delay: 700.ms, curve: Curves.elasticOut),
      const SizedBox(height: 16),
      TextButton(
        onPressed: _isLoading ? null : _startDeviceFlow,
        child: const Text('Login with Device Code'),
      ).animate().fadeIn(delay: 800.ms),
    ];
  }

  List<Widget> _buildDeviceFlow(ColorScheme colorScheme) {
    return [
      Card(
        elevation: 0,
        color: colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Enter this code on seedr.cc/devices:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                    _userCode!,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: colorScheme.primary,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2.seconds),
            ],
          ),
        ),
      ).animate().flipV(),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: _isLoading ? null : _checkDeviceAuth,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('I have authorized'),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => setState(() => _userCode = null),
        child: const Text('Back to Login'),
      ),
    ];
  }

  Widget _buildSavedAccounts(BuildContext context, ColorScheme colorScheme) {
    // We need to listen to SettingsService to update the list if an account is removed
    final settings = context.watch<SettingsService>();
    final accounts = settings.savedAccounts;

    if (accounts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Accounts',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        SizedBox(
          height: 100, // Fixed height for horizontal list
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: accounts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final email = account['username'] ?? '';
              final password = account['password'] ?? '';

              // Simple avatar logic: first letter
              final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

              return Stack(
                children: [
                  Material(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        _emailController.text = email;
                        _passwordController.text = password;
                        _login();
                      },
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => settings.removeAccount(email),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: (100 * index).ms).slideX();
            },
          ),
        ),
      ],
    );
  }
}
