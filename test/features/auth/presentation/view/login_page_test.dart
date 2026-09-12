import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fundament/core/di/injection.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_cubit.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_presentation_event.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_state.dart';
import 'package:flutter_fundament/features/auth/presentation/view/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

void main() {
  late _MockLoginCubit mockLoginCubit;
  late StreamController<LoginPresentationEvent> presentationController;

  setUp(() {
    mockLoginCubit = _MockLoginCubit();
    presentationController =
        StreamController<LoginPresentationEvent>.broadcast();

    when(
      () => mockLoginCubit.presentation,
    ).thenAnswer((_) => presentationController.stream);
    when(
      () => mockLoginCubit.submit(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});

    getIt.registerFactory<LoginCubit>(() => mockLoginCubit);
  });

  tearDown(() async {
    await presentationController.close();
    await getIt.reset();
  });

  testWidgets(
    'shows a loading indicator and no submit button while submitting',
    (tester) async {
      whenListen(
        mockLoginCubit,
        const Stream<LoginState>.empty(),
        initialState: const LoginState.submitting(),
      );

      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsNothing);
    },
  );

  testWidgets('calls LoginCubit.submit with the entered email and password', (
    tester,
  ) async {
    whenListen(
      mockLoginCubit,
      const Stream<LoginState>.empty(),
      initialState: const LoginState.initial(),
    );

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    verify(
      () => mockLoginCubit.submit(
        email: 'test@example.com',
        password: 'password123',
      ),
    ).called(1);
  });

  testWidgets(
    'shows a SnackBar with the message carried by ShowErrorSnackbar',
    (tester) async {
      whenListen(
        mockLoginCubit,
        const Stream<LoginState>.empty(),
        initialState: const LoginState.initial(),
      );

      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      presentationController.add(
        const LoginPresentationEvent.showErrorSnackbar('Invalid credentials'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid credentials'), findsOneWidget);
    },
  );
}
