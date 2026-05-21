import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../will_creation/presentation/bloc/will_bloc.dart';
import '../../../will_creation/presentation/bloc/will_event.dart';
import '../../../will_creation/presentation/bloc/will_state.dart';
import '../../../will_creation/data/models/will_detail_models.dart';

class WillCommentsScreen extends StatefulWidget {
  final String willId;

  const WillCommentsScreen({super.key, required this.willId});

  @override
  State<WillCommentsScreen> createState() => _WillCommentsScreenState();
}

class _WillCommentsScreenState extends State<WillCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _secureStorage = SecureStorageService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUserId();
    if (mounted) {
      _loadComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _loadComments() {
    context.read<WillBloc>().add(GetWillCommentsEvent(willId: widget.willId));
  }

  void _sendComment() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    context.read<WillBloc>().add(
      AddWillCommentEvent(willId: widget.willId, comment: comment),
    );
    _commentController.clear();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final commentDay = DateTime(local.year, local.month, local.day);

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $amPm';

    if (commentDay == today) {
      return time;
    } else if (commentDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    } else {
      final day = local.day;
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '$day ${months[local.month - 1]}, $time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderGray, width: 1),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Comments', style: AppTextStyles.questionTitle),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add comments to send back to lawyer for review',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Comments list
          Expanded(
            child: BlocConsumer<WillBloc, WillState>(
              listener: (context, state) {
                if (state is CommentAdded) {
                  _loadComments();
                  _scrollToBottom();
                }
                if (state is CommentsLoaded) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is WillLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CommentsLoaded) {
                  if (state.comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: AppColors.textGray.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No comments yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start a conversation with your lawyer',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: state.comments.length,
                    itemBuilder: (context, index) {
                      final comment = state.comments[index];
                      final isCurrentUser = _isCurrentUser(comment);

                      return _buildCommentBubble(
                        comment: comment,
                        isCurrentUser: isCurrentUser,
                      );
                    },
                  );
                }

                if (state is WillError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.errorRed2,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load comments',
                            style: AppTextStyles.questionTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _loadComments,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 100),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLightGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGray,
                          ),
                          border: InputBorder.none,
                        ),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDarkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _sendComment,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 38,
                          minHeight: 38,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentBubble({
    required WillComment comment,
    required bool isCurrentUser,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            // Commenter info
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      comment.name.isNotEmpty
                          ? comment.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  comment.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // Comment bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.primaryDarkGreen
                  : AppColors.backgroundLightGray,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
              ),
            ),
            child: Text(
              comment.comment,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isCurrentUser ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Timestamp
          Padding(
            padding: EdgeInsets.only(
              left: isCurrentUser ? 0 : 4,
              right: isCurrentUser ? 4 : 0,
            ),
            child: Text(
              _formatTimestamp(comment.createdAt),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentUser(WillComment comment) {
    if (_currentUserId != null) {
      return comment.userId == _currentUserId;
    }
    return false;
  }
}
