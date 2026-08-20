import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conta criada com sucesso!')),
    );
    Navigator.of(context).pop();
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
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: Validators.name,
                        decoration: const InputDecoration(
                          hintText: 'Nome completo',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: Validators.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          PhoneInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Telefone',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                        decoration: const InputDecoration(
                          hintText: 'E-mail',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        validator: Validators.password,
                        onFieldSubmitted: (_) => _onRegister(),
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
                      // Botão cadastrar.
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _onRegister,
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
                                  'Cadastrar',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
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

                      // Voltar para o login.
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Já tem uma conta? Entrar',
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
