import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';

class WillSignWebViewPage extends StatefulWidget {
  final String signUrl;
  final VoidCallback onSigningComplete;

  /// Called whenever the webview page is closed, regardless of reason
  /// (signing completed, cancelled, or back button). Use this to trigger
  /// any cleanup such as stopping a recording after a delay.
  final VoidCallback? onClosed;

  const WillSignWebViewPage({
    super.key,
    required this.signUrl,
    required this.onSigningComplete,
    this.onClosed,
  });

  @override
  State<WillSignWebViewPage> createState() => _WillSignWebViewPageState();
}

class _WillSignWebViewPageState extends State<WillSignWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _signingCompleted = false;
  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
            _checkUrlChange(url);
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            _checkUrlChange(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.signUrl));
  }

  /// Returns true when the URL belongs to the DocuSign signing flow.
  bool _isDocuSignUrl(String host) {
    return host.endsWith('docusign.net') || host.endsWith('docusign.com');
  }

  void _checkUrlChange(String url) {
    if (_signingCompleted) return;

    final currentHost = Uri.tryParse(url)?.host ?? '';
    if (currentHost.isEmpty) return;

    // Only treat as complete when we navigate away from ALL DocuSign domains
    // (DocuSign uses both demo.docusign.net and apps-d.docusign.com internally)
    if (!_isDocuSignUrl(currentHost)) {
      print('Signing completed - redirected away from DocuSign: $url');
      _signingCompleted = true;
      widget.onSigningComplete();
      widget.onClosed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_signingCompleted) {
          // Back-button exit without completing signing — still notify caller.
          widget.onClosed?.call();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _showCancelDialog,
        ),
        title: Text(
          'Sign Will',
          style: AppTextStyles.stepTitle,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Signing?', style: AppTextStyles.cardTitle),
        content: Text(
          'Are you sure you want to cancel the signing process?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          AppTextButton(
            text: 'Continue Signing',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppTextButton(
            text: 'Cancel',
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              widget.onClosed?.call();     // Notify caller the webview is closing
              this.context.pop(); // Close webview
            },
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}
