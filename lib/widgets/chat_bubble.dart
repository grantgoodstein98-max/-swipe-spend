import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';

/// Widget for displaying a single chat message bubble
class ChatBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showTimestamp = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showTimestamp = !_showTimestamp;
        });
      },
      onLongPress: () {
        _showCopyOption();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: widget.message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: widget.message.isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!widget.message.isUser) ...[
                  _buildAvatar(),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: widget.message.isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(widget.message.isUser ? 20 : 4),
                        bottomRight: Radius.circular(widget.message.isUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.message.text,
                      style: TextStyle(
                        color: widget.message.isUser
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                if (widget.message.isUser) ...[
                  const SizedBox(width: 8),
                  _buildAvatar(),
                ],
              ],
            ),
            if (_showTimestamp) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.message.formattedTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.6),
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.message.isUser
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Theme.of(context).colorScheme.secondary.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.message.isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: widget.message.isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _showCopyOption() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy message'),
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: widget.message.text),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
