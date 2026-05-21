import 'package:equatable/equatable.dart';

class OnboardingPage extends Equatable {
  final String title;
  final String subtitle;
  final String imagePath;
  final String description;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.description,
  });

  @override
  List<Object?> get props => [title, subtitle, imagePath, description];
}
