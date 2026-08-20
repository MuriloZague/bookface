import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/validators.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Column(
                      children: [
                        const _MiniLogo(size: 72),
                        const SizedBox(height: 16),
                        Text(
                          'bookface',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.emailOrPhone,
                      decoration: const InputDecoration(
                        hintText: 'E-mail ou telefone',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Informe sua senha' : null,
                      onFieldSubmitted: (_) => _onLogin(),
                      decoration: InputDecoration(
                        hintText: 'Senha',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Botão entrar.
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Esqueceu a senha?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox(height: 24)),
                    Row(
                      children: const [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ou',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Criar nova conta.
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Criar nova conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniLogo extends StatelessWidget {
  const _MiniLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text(
          'b',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.7,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
