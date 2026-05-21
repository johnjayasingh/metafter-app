import '../domain/entities/onboarding_page.dart';

class OnboardingData {
  static final List<OnboardingPage> pages = [
    const OnboardingPage(
      title: 'Create your will',
      subtitle: 'Plan how your estate is shared with a simple, guided process.',
      imagePath: 'assets/images/family.png',
      description: '',
    ),
    const OnboardingPage(
      title: 'Digital Asset Management',
      subtitle: 'Securely manage access to your online accounts and files.',
      imagePath: 'assets/images/security.svg',
      description: '',
    ),
    const OnboardingPage(
      title: 'Funeral & Memorial',
      subtitle: 'Trusted by families across Australia',
      imagePath: 'assets/images/funeral.svg',
      description:
          'Set your preferences to ease the burden on loved ones.',
    ),
  ];
}
