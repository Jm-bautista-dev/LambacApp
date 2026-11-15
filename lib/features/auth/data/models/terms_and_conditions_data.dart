import '../../../../core/constants/app_constants.dart';

/// Single section within the Terms & Conditions document
class TermsSection {
  final String title;
  final String content;
  final List<String> bulletPoints;

  const TermsSection({
    required this.title,
    required this.content,
    this.bulletPoints = const [],
  });
}

/// Official Approved Terms & Conditions Document for Lambac Coffee Roastery
class TermsAndConditionsDocument {
  final String version;
  final String effectiveDate;
  final String title;
  final String introduction;
  final List<TermsSection> sections;
  final String closingStatement;

  const TermsAndConditionsDocument({
    required this.version,
    required this.effectiveDate,
    required this.title,
    required this.introduction,
    required this.sections,
    required this.closingStatement,
  });

  /// The authoritative current version of Lambac Coffee Roastery Terms & Conditions
  static const TermsAndConditionsDocument current = TermsAndConditionsDocument(
    version: AppConstants.currentTermsVersion,
    effectiveDate: AppConstants.termsEffectiveDate,
    title: 'Terms & Conditions',
    introduction:
        'Welcome to Lambac Coffee Roastery. These Terms & Conditions ("Terms") constitute a legally binding agreement between you ("User", "Customer", "Barista", or "Administrator") and Lambac Coffee Roastery regarding your access to and use of our mobile ordering platform, concierge chat, counter pickup tracking, and related roastery digital services.',
    sections: [
      TermsSection(
        title: '1. Acceptance of Terms & Eligibility',
        content:
            'By accessing or using the Lambac Coffee Roastery mobile application, you confirm that you have reached the age of majority in your jurisdiction or possess valid parental or guardian consent. If you do not agree with any part of these Terms, you must decline and discontinue use of the application immediately.',
        bulletPoints: [
          'Access to authenticated services requires explicit acceptance of these Terms.',
          'Each account identity is strictly tied to the verified user session.',
          'Acceptance applies to all platforms including mobile ordering, concierge messaging, and staff counter management.',
        ],
      ),
      TermsSection(
        title: '2. Account Registration, Credentials & Security',
        content:
            'To place pickup orders, communicate with roastery baristas, or access business operations, you must register for an account using a valid email address and verified credentials. You agree to maintain the security and confidentiality of your credentials at all times.',
        bulletPoints: [
          'You are solely responsible for all activities and counter orders occurring under your authenticated account.',
          'Account sharing, credential transfer, or unauthorized access attempts are strictly prohibited.',
          'Notify Lambac Roastery support immediately if you suspect unauthorized access to your account.',
        ],
      ),
      TermsSection(
        title: '3. Mobile Ordering & Scheduled Counter Pickup',
        content:
            'Our mobile ordering system allows customers to select artisan coffee roasts, specify brewing specifications (grind size, bean variety, and package sizes), and schedule convenient counter pickup times at our roastery bar.',
        bulletPoints: [
          'Orders must be collected during designated roastery operating hours at the specified counter location.',
          'Custom-ground beans and fresh espresso extractions are prepared to order to ensure peak flavor and aroma.',
          'Customers are requested to arrive promptly during their selected pickup window for optimal extraction quality.',
        ],
      ),
      TermsSection(
        title: '4. Pricing, Counter Payments & Cancellation Policy',
        content:
            'All product prices are quoted in Philippine Pesos (PHP / ₱) and include applicable taxes unless expressly stated otherwise. Prices and seasonal roast availability are subject to change based on harvest crop yields.',
        bulletPoints: [
          'Counter payments may be finalized via cash, supported digital wallets, or official point-of-sale methods upon pickup.',
          'Cancellations are accepted through the application while the order is in "Pending" or "Confirmed" status prior to preparation.',
          'Once a roast batch is ground, extracted, or packaged for pickup, cancellation may be restricted to prevent artisanal food waste.',
        ],
      ),
      TermsSection(
        title: '5. Roastery Concierge Chat & Communication Conduct',
        content:
            'The built-in Concierge Chat enables direct communication between customers and roastery staff for brewing advice, roast profiles, and order assistance.',
        bulletPoints: [
          'All communication must remain courteous, constructive, and related to coffee, orders, or roastery services.',
          'Harassment, abusive language, automated spam, or transmission of malicious content will result in immediate suspension.',
          'Baristas respond to inquiries during regular roasting and counter operating hours.',
        ],
      ),
      TermsSection(
        title: '6. Product Reviews & Tasting Notes Guidelines',
        content:
            'Customers may submit tasting notes and star ratings for coffee beans and roasts they have ordered. Reviews reflect genuine personal experiences and help our roastery community.',
        bulletPoints: [
          'Reviews must not contain defamatory, misleading, offensive, or infringing material.',
          'Lambac Roastery reserves the right to moderate, flag, or remove reviews that violate community standards.',
          'Submitting a review grants Lambac Coffee Roastery a non-exclusive license to display the feedback within the application.',
        ],
      ),
      TermsSection(
        title: '7. Staff, Barista & Administrative Roles',
        content:
            'Authorized employees, baristas, and administrators accessing internal tools (POS, inventory, order processing, and analytics) are bound by professional duty of care.',
        bulletPoints: [
          'Staff must safeguard customer contact details, order history, and confidential sales figures.',
          'Administrative accounts must never manipulate or forge customer data, pricing, or system audit trails.',
          'Employee roles and permissions are assigned strictly on a need-to-know basis and subject to ongoing audit logging.',
        ],
      ),
      TermsSection(
        title: '8. Customer Privacy & Data Isolation Commitment',
        content:
            'Lambac Coffee Roastery prioritizes customer privacy and rigorous data isolation. Your notifications, private concierge chats, order history, and account activity are cryptographically and logically isolated by your authenticated Firebase UID.',
        bulletPoints: [
          'Under no circumstances does Customer A have access to Customer B’s orders, messages, or notifications.',
          'Data collected is used strictly for roastery operations, customer support, and authorized analytics.',
          'You may request account and data deletion at any time via Profile Settings.',
        ],
      ),
      TermsSection(
        title: '9. Terms Updates & Version Governance',
        content:
            'Lambac Coffee Roastery reserves the right to modify these Terms to reflect operational changes, product offerings, or regulatory requirements. Material revisions will be accompanied by an incremented version number.',
        bulletPoints: [
          'Whenever a new version of the Terms is published, users will be prompted to review and accept the updated terms upon next login.',
          'Continued use of the application following the acceptance prompt signifies agreement to the revised Terms.',
          'Historical acceptance records including timestamp and version are securely archived for audit compliance.',
        ],
      ),
      TermsSection(
        title: '10. Governing Law & Roastery Contact',
        content:
            'These Terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines. Any disputes arising out of or related to these Terms shall be resolved through good-faith mediation before the competent courts of the roastery’s jurisdiction.',
        bulletPoints: [
          'Roastery Location: Lambac Coffee Roastery Flagship Bar, Baguio / Benguet Region, Philippines.',
          'Support Inquiries: support@lambaccoffee.com',
          'Operating Hours: Tuesday – Sunday, 7:00 AM – 8:00 PM PHT.',
        ],
      ),
    ],
    closingStatement:
        'By selecting the agreement checkbox and pressing Continue below, you acknowledge that you have scrolled through and thoroughly reviewed all 10 sections of these Terms & Conditions, and agree to be bound by them in full.',
  );
}
