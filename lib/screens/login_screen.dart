import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todoappp/auth/auth_service.dart';
import 'package:todoappp/screens/main_screen.dart';
import 'package:todoappp/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
    _slideController.reset();
    _slideController.forward();
  }

  void _setLoading(bool v) => setState(() => _isLoading = v);

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    _setLoading(true);
    try {
      if (_isLogin) {
        await AuthService.signInWithEmail(
            _emailController.text, _passwordController.text);
      } else {
        await AuthService.signUpWithEmail(
            _emailController.text, _passwordController.text);
      }
      _goToApp();
    } catch (e) {
      _showError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleGoogle() async {
    _setLoading(true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (result != null) _goToApp();
    } catch (e) {
      _showError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Enter your email address above first.');
      return;
    }
    _setLoading(true);
    try {
      await AuthService.sendPasswordReset(_emailController.text);
      _showSuccess('Password reset email sent!');
    } catch (e) {
      _showError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _goToApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1035),
                Color(0xFF2D1B69),
                Color(0xFF1A1035),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                _Orb(top: -80, right: -60, size: 260, opacity: 0.12),
                _Orb(top: 200, left: -80, size: 200, opacity: 0.08),
                _Orb(bottom: -100, right: -40, size: 300, opacity: 0.09),

                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          _buildHeader(),
                          const SizedBox(height: 36),
                          _buildCard(),
                          const SizedBox(height: 24),
                          _buildDivider(),
                          const SizedBox(height: 24),
                          _buildSocialButtons(),
                          const SizedBox(height: 32),
                          _buildToggleRow(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B5CF6),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: _pulseAnim.value,
            child: child,
          ),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.task_alt_rounded,
                color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'Welcome\nBack 👋' : 'Create\nAccount ✨',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to continue your productivity journey'
              : 'Join thousands achieving more every day',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _AuthField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _AuthField(
              controller: _passwordController,
              label: 'Password',
              hint: _isLogin ? 'Your password' : 'Min. 6 characters',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (!_isLogin && v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            if (_isLogin) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _handleForgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: const Color(0xFF8B5CF6).withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleEmailAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                ),
                child: Text(
                  _isLogin ? 'Sign In' : 'Create Account',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
            child: Container(
                height: 1, color: Colors.white.withOpacity(0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
            child: Container(
                height: 1, color: Colors.white.withOpacity(0.1))),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _SocialButton(
          label: 'Continue with Google',
          iconWidget: Image.network(
            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
            width: 22,
            height: 22,
            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata,
                color: Color(0xFFEA4335), size: 24),
          ),
          onTap: _isLoading ? null : _handleGoogle,
        ),
      ],
    );
  }

  Widget _buildToggleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : 'Already have an account? ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: _toggleMode,
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}


class _Orb extends StatelessWidget {
  final double? top, bottom, left, right, size, opacity;
  const _Orb({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(opacity!),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon:
                Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.iconWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
