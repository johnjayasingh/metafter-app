import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_router.dart';
import '../../data/signup_draft.dart';
import '../widgets/metafter_field.dart';
import '../widgets/metafter_primary_button.dart';
import '../widgets/signup_scaffold.dart';

class SignupProfileScreen extends StatefulWidget {
  const SignupProfileScreen({super.key});

  @override
  State<SignupProfileScreen> createState() => _SignupProfileScreenState();
}

class _SignupProfileScreenState extends State<SignupProfileScreen> {
  static const _roles = <String>[
    'Working Professional',
    'Student',
    'Entrepreneur',
    'Freelancer',
    'Other',
  ];

  final _draft = SignupDraft.instance;
  late final TextEditingController _name;
  late final TextEditingController _designation;
  late final TextEditingController _company;
  late final TextEditingController _intro;
  String? _role;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _draft.name);
    _designation = TextEditingController(text: _draft.designation);
    _company = TextEditingController(text: _draft.company);
    _intro = TextEditingController(text: _draft.introduction);
    _role = _draft.role.isNotEmpty ? _draft.role : _roles.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _designation.dispose();
    _company.dispose();
    _intro.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _name.text.trim().isNotEmpty &&
      (_role ?? '').isNotEmpty &&
      _designation.text.trim().isNotEmpty;

  void _onNext() {
    _draft.update(() {
      _draft.name = _name.text.trim();
      _draft.role = _role ?? '';
      _draft.designation = _designation.text.trim();
      _draft.company = _company.text.trim();
      _draft.introduction = _intro.text.trim();
    });
    context.push(AppRouter.signupPhoto);
  }

  @override
  Widget build(BuildContext context) {
    return SignupScaffold(
      title: 'Let’s complete your profile',
      bottomButton: MetafterPrimaryButton(
        label: 'Next',
        onPressed: _canContinue ? _onNext : null,
      ),
      child: Column(
        children: [
          MetafterField(
            label: 'Name',
            controller: _name,
            hint: 'Luna Ray',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          MetafterDropdownField<String>(
            label: 'Your Role',
            value: _role,
            items: _roles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _role = v),
          ),
          const SizedBox(height: 20),
          MetafterField(
            label: 'Designation',
            controller: _designation,
            hint: 'UI / UX Designer',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          MetafterField(
            label: 'Company Name',
            controller: _company,
            hint: 'Techinorm',
          ),
          const SizedBox(height: 20),
          MetafterField(
            label: 'Professional Introduction',
            controller: _intro,
            hint: 'This is how you’ll be introduced to others.',
            maxLines: 4,
            minLines: 3,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
