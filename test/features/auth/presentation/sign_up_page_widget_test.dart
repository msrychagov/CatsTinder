import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_setup_task/features/auth/domain/auth_credentials_validator.dart';
import 'package:flutter_setup_task/features/auth/presentation/sign_up_page.dart';

void main() {
  testWidgets('shows validation feedback when sign up form is invalid', (
    tester,
  ) async {
    _setPhoneViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: SignUpPage(
          validator: AuthCredentialsValidator(),
          onToggleToSignIn: () {},
          onSubmit: (_) async {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('sign_up_email_field')),
      'cat@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign_up_password_field')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('sign_up_repeat_password_field')),
      '654321',
    );

    await tester.ensureVisible(find.byKey(const Key('sign_up_submit_button')));
    await tester.tap(find.byKey(const Key('sign_up_submit_button')));
    await tester.pump();

    expect(find.text('Пароли не совпадают'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('sign_up_repeat_password_field')),
      '123456',
    );
    await tester.ensureVisible(find.byKey(const Key('sign_up_submit_button')));
    await tester.tap(find.byKey(const Key('sign_up_submit_button')));
    await tester.pump();

    expect(find.text('Добавьте фото профиля'), findsOneWidget);
  });

  testWidgets('submits sign up form successfully with selected photo', (
    tester,
  ) async {
    _setPhoneViewport(tester);

    SignUpFormData? submittedData;

    await tester.pumpWidget(
      MaterialApp(
        home: SignUpPage(
          validator: AuthCredentialsValidator(),
          onToggleToSignIn: () {},
          pickPhotoPath: () async => '/tmp/test_avatar.png',
          onSubmit: (formData) async {
            submittedData = formData;
          },
        ),
      ),
    );

    await tester.tap(find.text('Добавить фото'));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('sign_up_email_field')),
      'cat@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign_up_password_field')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('sign_up_repeat_password_field')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('sign_up_description_field')),
      'Люблю спать на подоконнике',
    );

    await tester.ensureVisible(find.byKey(const Key('sign_up_submit_button')));
    await tester.tap(find.byKey(const Key('sign_up_submit_button')));
    await tester.pump();

    expect(submittedData, isNotNull);
    expect(submittedData?.email, 'cat@example.com');
    expect(submittedData?.password, '123456');
    expect(submittedData?.description, 'Люблю спать на подоконнике');
    expect(submittedData?.photoPath, '/tmp/test_avatar.png');
    expect(submittedData?.energyLevel, 3);
    expect(submittedData?.intelligence, 3);
    expect(submittedData?.affectionLevel, 3);
    expect(submittedData?.socialNeeds, 3);
  });
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1290, 2796);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
