import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fundament/core/di/injection.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_cubit.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_presentation_event.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_state.dart';

/// The login screen: resolves a screen-scoped `LoginCubit` from DI and
/// hands it to [_LoginView].
class LoginPage extends StatelessWidget {
  /// Creates a [LoginPage].
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginCubit>(
      create: (_) => getIt<LoginCubit>(),
      child: const _LoginView(),
    );
  }
}

/// The login form: an email field, a password field, and a submit button
/// that calls `LoginCubit.submit`.
///
/// A [StatefulWidget] so it can own and dispose the [TextEditingController]s
/// backing the two fields.
class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocPresentationListener<LoginCubit, LoginPresentationEvent>(
      listener: (context, event) {
        switch (event) {
          case ShowErrorSnackbar(:final message):
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<LoginCubit, LoginState>(
              builder: (context, state) {
                final isSubmitting = state is LoginSubmitting;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      key: const Key('login_email_field'),
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextFormField(
                      key: const Key('login_password_field'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 16),
                    if (isSubmitting)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        key: const Key('login_submit_button'),
                        onPressed: () => context.read<LoginCubit>().submit(
                          email: _emailController.text,
                          password: _passwordController.text,
                        ),
                        child: const Text('Log in'),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
