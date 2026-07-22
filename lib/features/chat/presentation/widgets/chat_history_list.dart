import 'package:flutter/material.dart';

import '../../domain/entities/chat_command.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_message_bubble.dart';

class ChatHistoryList extends StatefulWidget {
  const ChatHistoryList({
    super.key,
    required this.messages,
    required this.attempts,
    required this.currentUserId,
    required this.hasMore,
    required this.loadingOlder,
    required this.showNewMessages,
    this.firstUnreadMessageId,
    required this.onLoadOlder,
    required this.onRetry,
    required this.onJumpToNewest,
  });

  final List<ChatMessage> messages;
  final List<ChatSendAttempt> attempts;
  final String currentUserId;
  final bool hasMore;
  final bool loadingOlder;
  final bool showNewMessages;
  final String? firstUnreadMessageId;
  final Future<void> Function() onLoadOlder;
  final ValueChanged<ChatSendAttempt> onRetry;
  final VoidCallback onJumpToNewest;

  @override
  State<ChatHistoryList> createState() => _ChatHistoryListState();
}

class _ChatHistoryListState extends State<ChatHistoryList> {
  final _scrollController = ScrollController();
  final _firstUnreadKey = GlobalKey();
  bool _positionedInitialView = false;
  bool _initialPositionScheduled = false;
  String? _reportedNewestMessageId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_reportNewestWhenVisible);
  }

  @override
  void didUpdateWidget(covariant ChatHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.lastOrNull?.id != widget.messages.lastOrNull?.id) {
      _reportedNewestMessageId = null;
    }
    _scheduleInitialPosition();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_reportNewestWhenVisible)
      ..dispose();
    super.dispose();
  }

  void _scheduleInitialPosition() {
    if (_positionedInitialView ||
        _initialPositionScheduled ||
        widget.messages.isEmpty) {
      return;
    }
    _initialPositionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        _initialPositionScheduled = false;
        return;
      }
      final unreadContext = _firstUnreadKey.currentContext;
      if (unreadContext != null) {
        Scrollable.ensureVisible(unreadContext, alignment: 0.2);
      } else if (widget.firstUnreadMessageId case final unreadId?) {
        final unreadIndex = widget.messages.indexWhere(
          (message) => message.id == unreadId,
        );
        if (unreadIndex >= 0 && widget.messages.length > 1) {
          final estimatedOffset =
              _scrollController.position.maxScrollExtent *
              unreadIndex /
              (widget.messages.length - 1);
          _scrollController.jumpTo(estimatedOffset);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final builtUnreadContext = _firstUnreadKey.currentContext;
              if (builtUnreadContext != null) {
                Scrollable.ensureVisible(builtUnreadContext, alignment: 0.2);
              }
              _finishInitialPosition();
            }
          });
          return;
        }
      } else {
        _settleNewestPosition(5);
        return;
      }
      _finishInitialPosition();
    });
  }

  void _settleNewestPosition(int attemptsRemaining) {
    if (!mounted || !_scrollController.hasClients) {
      _finishInitialPosition();
      return;
    }
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attemptsRemaining > 0 &&
          mounted &&
          _scrollController.hasClients &&
          _scrollController.position.extentAfter > 1) {
        _settleNewestPosition(attemptsRemaining - 1);
      } else {
        _finishInitialPosition();
      }
    });
  }

  void _finishInitialPosition() {
    _initialPositionScheduled = false;
    _positionedInitialView = true;
    _reportNewestWhenVisible();
  }

  void _reportNewestWhenVisible() {
    if (!_scrollController.hasClients || widget.messages.isEmpty) return;
    if (_scrollController.position.extentAfter > 24) return;
    final newestId = widget.messages.last.id;
    if (_reportedNewestMessageId == newestId) return;
    _reportedNewestMessageId = newestId;
    widget.onJumpToNewest();
  }

  Future<void> _loadOlderPreservingViewport() async {
    if (!_scrollController.hasClients) {
      await widget.onLoadOlder();
      return;
    }
    final oldPixels = _scrollController.position.pixels;
    final oldMaximum = _scrollController.position.maxScrollExtent;
    await widget.onLoadOlder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final addedExtent = _scrollController.position.maxScrollExtent - oldMaximum;
      _scrollController.jumpTo(
        (oldPixels + addedExtent).clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ).toDouble(),
      );
    });
  }

  void _jumpToNewest() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    widget.onJumpToNewest();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleInitialPosition();
    return Column(
      children: [
        if (widget.hasMore)
          TextButton(
            onPressed: widget.loadingOlder ? null : _loadOlderPreservingViewport,
            child: Text(
              widget.loadingOlder
                  ? 'Loading older messages…'
                  : 'Load older messages',
            ),
          ),
        Expanded(
          child: widget.messages.isEmpty && widget.attempts.isEmpty
              ? const Center(
                  child: Text('No messages yet. Start the conversation.'),
                )
              : ListView(
                  key: const Key('chat-history-list'),
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final message in widget.messages)
                      KeyedSubtree(
                        key: message.id == widget.firstUnreadMessageId
                            ? const Key('first-unread-message')
                            : ValueKey('chat-message-${message.id}'),
                        child: KeyedSubtree(
                          key: message.id == widget.firstUnreadMessageId
                              ? _firstUnreadKey
                              : null,
                          child: ChatMessageBubble(
                            message: message,
                            isMine:
                                message.authorUserId == widget.currentUserId,
                          ),
                        ),
                      ),
                    for (final attempt in widget.attempts.where(
                      (item) => item.status != ChatSendAttemptStatus.sent,
                    ))
                      ChatAttemptBubble(
                        attempt: attempt,
                        onRetry: () => widget.onRetry(attempt),
                      ),
                  ],
                ),
        ),
        if (widget.showNewMessages)
          FilledButton.tonal(
            onPressed: _jumpToNewest,
            child: const Text('New messages'),
          ),
      ],
    );
  }
}
