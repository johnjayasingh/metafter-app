import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Full-screen pricing page (opened from the Pro upgrade dialog "See other
/// plans" link, or as the destination of "Get Started" / "Continue with Pro").
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _annual = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.brandRed, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('MetAfter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.brandRed,
            )),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('Pricing',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              )),
          const SizedBox(height: 10),
          const Text(
            'We believe MetAfter should be accessible to all. Simple, transparent pricing',
            style: TextStyle(fontSize: 15, color: Color(0xFF4F4F4F), height: 1.4),
          ),
          const SizedBox(height: 22),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PricingToggle(
                  value: _annual,
                  onChanged: (v) => setState(() => _annual = v),
                ),
                const SizedBox(width: 12),
                const Text('Annual pricing ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    )),
                const Text('(Save 20%)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandRed,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // "Most popular!" tag
          Padding(
            padding: const EdgeInsets.only(right: 30),
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.subdirectory_arrow_left_rounded,
                      size: 22, color: AppColors.brandRed),
                  SizedBox(width: 4),
                  Text('Most popular!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandRed,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _PlanCard(
            price: _annual ? r'$10/mth' : r'$12/mth',
            planName: 'Pro Plan',
            billing: _annual ? 'Billed annually.' : 'Billed monthly.',
            features: const [
              'Access to all basic features &',
              'Unlimited connection requests',
              'Invitation note to 5 individual users',
              'Priority chat and email support',
            ],
            ctaLabel: 'Get Started',
            onCta: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pro Plan checkout (mock)'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _PlanCard(
            price: _annual ? r'$5/mth' : r'$6/mth',
            planName: 'Starter Plan',
            billing: _annual ? 'Billed annually.' : 'Billed monthly.',
            features: const [
              'Access to all basic features',
              'Up to 50 connection requests / month',
              'Invitation note to 1 individual user',
              'Standard email support',
            ],
            ctaLabel: 'Get Started',
            onCta: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Starter Plan checkout (mock)'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PricingToggle extends StatelessWidget {
  const _PricingToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.brandRed : const Color(0xFFCFCFCF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.price,
    required this.planName,
    required this.billing,
    required this.features,
    required this.ctaLabel,
    required this.onCta,
  });
  final String price;
  final String planName;
  final String billing;
  final List<String> features;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(price,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              )),
          const SizedBox(height: 8),
          Text(planName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              )),
          const SizedBox(height: 4),
          Text(billing,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B6B6B))),
          const SizedBox(height: 18),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD7F1D9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 14, color: Color(0xFF2BA84A)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4F4F4F),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(ctaLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
