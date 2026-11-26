import 'dart:async';
import '../widgets/chat_icon.dart';
import '../services/chat_delivery.dart';
import '../services/local_chat_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:moneyfy/design_system/spec/visual_spec.dart';
import 'package:moneyfy/widgets/moneyfy_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:moneyfy/features/auth/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RedditChatPage extends StatelessWidget {
  const RedditChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, _) {
        final user = AuthService.currentUser;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('로그인 후 질문할 수 있어요.')),
          );
        }
        return _ChatRooms(key: ValueKey(user.id), userId: user.id);
      },
    );
  }
}

class _ChatRooms extends StatefulWidget {
  const _ChatRooms({super.key, required this.userId});
  final String userId;

  @override
  State<_ChatRooms> createState() => _ChatRoomsState();
}

class _ChatRoomsState extends State<_ChatRooms> {
  String _threadId = const Uuid().v4();
  String? _title;

  void _select(String? id, String? title) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _threadId = id ?? const Uuid().v4();
      _title = title;
    });
  }

  ChatDelivery? _delivery;
  bool _openFailed = false;

  @override
  void initState() {
    super.initState();
    _openStore();
  }

  Future<void> _openStore() async {
    setState(() => _openFailed = false);
    try {
      final store = await LocalChatStore.open(widget.userId);
      if (!mounted) {
        store.db.close();
        return;
      }
      final delivery = ChatDelivery(store, widget.userId);
      setState(() => _delivery = delivery);
      unawaited(delivery.sync());
    } catch (_) {
      if (mounted) setState(() => _openFailed = true);
    }
  }

  @override
  void dispose() {
    _delivery?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delivery = _delivery;
    if (delivery == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _openFailed
              ? TextButton(
                  onPressed: _openStore,
                  child: const Text('기기 대화 저장소 다시 열기'),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    return ListenableBuilder(
      listenable: delivery,
      builder: (context, _) => _chat(context, delivery),
    );
  }

  Widget _chat(BuildContext context, ChatDelivery delivery) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _title ?? '뉴스·Reddit 채팅',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: '새 채팅',
            icon: const ChatIcon(ChatGlyph.newChat),
            onPressed: () => _select(null, null),
          ),
          Builder(
            builder: (context) => IconButton(
              tooltip: '채팅 목록',
              icon: const ChatIcon(ChatGlyph.rooms),
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: ChatRoomsDrawer(
        key: ValueKey(delivery.roomRevision),
        loadPage: (after) async => delivery.store.rooms(after),
        selectedId: _threadId,
        onSelect: _select,
        onDelete: (id) async {
          delivery.remove(id);
          if (mounted && _threadId == id) _select(null, null);
        },
      ),
      body: SafeArea(
        child: _ChatHistory(
          key: ValueKey(_threadId),
          delivery: delivery,
          threadId: _threadId,
          onFirstQuestion: (question) {
            if (_title == null) setState(() => _title = question);
          },
        ),
      ),
    );
  }
}

class ChatRoomsDrawer extends StatefulWidget {
  const ChatRoomsDrawer({
    super.key,
    required this.loadPage,
    required this.onDelete,
    required this.onSelect,
    required this.selectedId,
  });
  final Future<List<Map<String, dynamic>>> Function(Map<String, dynamic>? after)
  loadPage;
  final void Function(String? id, String? title) onSelect;
  final String selectedId;
  final Future<void> Function(String id) onDelete;

  @override
  State<ChatRoomsDrawer> createState() => _ChatRoomsDrawerState();
}

class _ChatRoomsDrawerState extends State<ChatRoomsDrawer> {
  final _rooms = <Map<String, dynamic>>[];
  final _deleted = <String>{};
  final _deleting = <String>{};
  bool _loading = false, _more = true, _error = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading || !_more) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final page = await widget.loadPage(_rooms.lastOrNull);
      if (!mounted) return;
      final known = _rooms.map((r) => r['id']).toSet();
      setState(() {
        _rooms.addAll(
          page.where((r) => !_deleted.contains(r['id']) && known.add(r['id'])),
        );
        _more = page.length == 30;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> room) async {
    final id = room['id'] as String;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화를 삭제할까요?'),
        content: Text('“${room['title']}”의 질문과 답변이 모두 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _deleting.contains(id)) return;
    setState(() => _deleting.add(id));
    try {
      await widget.onDelete(id);
      if (!mounted) return;
      setState(() {
        _deleted.add(id);
        _rooms.removeWhere((r) => r['id'] == id);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('대화를 삭제하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  void _open(Map<String, dynamic> room) {
    Scaffold.of(context).closeEndDrawer();
    widget.onSelect(room['id'] as String, room['title'] as String?);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text('채팅', style: Theme.of(context).textTheme.titleLarge),
              trailing: IconButton(
                tooltip: '닫기',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Scaffold.of(context).closeEndDrawer(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SlidableAutoCloseBehavior(
                child: ListView.builder(
                  itemCount: _rooms.length + (_more || _rooms.isEmpty ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _rooms.length) {
                      if (_loading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (!_more) {
                        return const ListTile(title: Text('아직 저장된 채팅이 없어요.'));
                      }
                      return TextButton(
                        onPressed: _load,
                        child: Text(_error ? '다시 불러오기' : '채팅 더 보기'),
                      );
                    }
                    final room = _rooms[i];
                    return Slidable(
                      key: ValueKey(room['id']),
                      groupTag: 'chatRooms',
                      enabled: !_deleting.contains(room['id']),
                      endActionPane: moneyfySingleSlideActionPane(
                        onPressed: () => _delete(room),
                        icon: Icons.close_rounded,
                        iconColor: VisualSpec.brand.brandRed,
                        semanticLabel: '대화 삭제',
                      ),
                      child: ListTile(
                        selected: room['id'] == widget.selectedId,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        title: Text(
                          room['title'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _open(room),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHistory extends StatefulWidget {
  const _ChatHistory({
    super.key,
    required this.delivery,
    required this.threadId,
    required this.onFirstQuestion,
  });
  final ChatDelivery delivery;
  final String threadId;
  final ValueChanged<String> onFirstQuestion;

  @override
  State<_ChatHistory> createState() => _ChatHistoryState();
}

class _ChatHistoryState extends State<_ChatHistory> {
  final _input = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.delivery.send(widget.threadId, question);
      if (mounted) {
        _input.clear();
        widget.onFirstQuestion(question);
      }
    } catch (error) {
      if (!mounted) return;
      final conflict = error is PostgrestException && error.code == '23505';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            conflict ? '이전 질문에 답변 중이에요.' : '전송 상태를 확인할 수 없어요. 대화 기록을 확인해 주세요.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.delivery.store.history(widget.threadId);
    final busy =
        _sending ||
        rows.any((r) => r['status'] == 'queued' || r['status'] == 'running');
    return Column(
      children: [
        if (widget.delivery.offline)
          TextButton(
            onPressed: widget.delivery.sync,
            child: const Text('서버 연결 재시도 · 기기에 저장한 대화는 볼 수 있어요.'),
          ),
        Expanded(
          child: MarketChatView(
            rows: rows,
            input: _input,
            sending: _sending,
            busy: busy,
            onSend: _send,
          ),
        ),
      ],
    );
  }
}

class MarketChatView extends StatelessWidget {
  const MarketChatView({
    super.key,
    required this.rows,
    required this.input,
    required this.sending,
    required this.busy,
    required this.onSend,
  });
  final List<Map<String, dynamic>> rows;
  final TextEditingController input;
  final bool sending;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: Column(
          children: [
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '무엇이 궁금하세요?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final prompt in [
                                  '최근 뉴스 요약해 줘',
                                  '엔비디아 CEO 복귀에 대한 뉴스와 레딧 반응 비교해 줘',
                                ])
                                  ActionChip(
                                    label: Text(prompt),
                                    onPressed: () {
                                      input.value = TextEditingValue(
                                        text: prompt,
                                        selection: TextSelection.collapsed(
                                          offset: prompt.length,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : Align(
                      alignment: Alignment.topCenter,
                      child: ListView.builder(
                        shrinkWrap: true,
                        reverse: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        itemCount: rows.length,
                        itemBuilder: (context, i) => _Exchange(
                          key: ValueKey(rows[i]['id']),
                          row: rows[i],
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 3, 4, 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: input,
                          readOnly: sending,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          decoration:
                              const InputDecoration.collapsed(
                                hintText: '뉴스나 Reddit에 질문하기',
                              ).copyWith(
                                counterText: '',
                                filled: false,
                                isCollapsed: false,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                        ),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: input,
                        builder: (_, value, _) => IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: colors.onSurface,
                            foregroundColor: colors.surface,
                          ),
                          tooltip: '질문 보내기',
                          icon: const ChatIcon(ChatGlyph.send),
                          onPressed: busy || value.text.trim().isEmpty
                              ? null
                              : onSend,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Exchange extends StatelessWidget {
  const _Exchange({super.key, required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final answer = row['answer'] as String;
    final sources = (row['sources'] as List).whereType<Map>().toList();
    final status = row['status'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: .86,
              alignment: Alignment.centerRight,
              child: Align(
                alignment: Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: SelectableText(
                      row['question'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (answer.isNotEmpty)
            SelectionArea(
              child: MarkdownBody(
                data: answer,
                inlineSyntaxes: [_ChatStrongSyntax()],
                imageBuilder: (_, _, alt) => Text(alt ?? ''),
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: TextStyle(
                    fontSize: 16,
                    height: 1.55,
                    color: colors.onSurface,
                  ),
                  h1: theme.textTheme.titleLarge,
                  h2: theme.textTheme.titleMedium,
                  blockSpacing: 10,
                ),
              ),
            ),
          if (status == 'failed')
            Text(
              '답변을 완료하지 못했어요. 다시 질문해 주세요.',
              style: TextStyle(color: colors.error),
            )
          else if (answer.isEmpty)
            Text(
              status == 'queued' ? '질문을 전달하고 있어요…' : '근거를 확인하고 있어요…',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          if (status == 'done' && answer.isNotEmpty)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                IconButton(
                  tooltip: '답변 복사',
                  iconSize: 17,
                  icon: const ChatIcon(ChatGlyph.copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: answer));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('답변을 복사했어요.')),
                      );
                    }
                  },
                ),
                if (sources.isNotEmpty)
                  TextButton.icon(
                    icon: const ChatIcon(ChatGlyph.sources, size: 16),
                    label: Text('출처 ${sources.length}개'),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      useSafeArea: true,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (context) => ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * .7,
                        ),
                        child: SafeArea(
                          top: false,
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  '답변 출처',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              for (final source in sources)
                                _ChatSource(source: source),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// Model output can escape both delimiters or attach a Korean particle
// directly to a punctuation-ending phrase such as **금리(%)**는.
class _ChatStrongSyntax extends md.InlineSyntax {
  _ChatStrongSyntax()
    : super(
        r'\\\*\\\*(?!\s)([^*`\n]*?[^\s*`\\])\\\*\\\*'
        r'|(?<!\*)\*\*(?![\s*])([^*`\n]*?[^\s*`])\*\*(?=[가-힣])'
        r'|(?<=[가-힣])\*\*(?![\s*])([^*`\n]*?[^\s*`])\*\*(?!\*)',
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match[1] ?? match[2] ?? match[3]!;
    parser.addNode(md.Element('strong', parser.document.parseInline(content)));
    return true;
  }
}

class _ChatSource extends StatelessWidget {
  const _ChatSource({required this.source});
  final Map source;

  @override
  Widget build(BuildContext context) {
    final news = source['sourceType'] == 'news_article';
    final label = news ? '뉴스' : 'Reddit';
    final date = DateTime.tryParse(source['publishedAt'] as String? ?? '');
    final uri = Uri.tryParse(source['url'] as String? ?? '');
    final canOpen =
        news &&
        uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
    final details = [
      if (news && source['publisher'] != null) source['publisher'],
      if (date != null) date.toUtc().toIso8601String().substring(0, 10),
    ].join(' · ');
    return ListTile(
      title: Text(
        '[${source['rank']}] $label · ${source['title'] ?? source['sourceId']}',
      ),
      subtitle: Text(
        [if (details.isNotEmpty) details, source['preview'] ?? ''].join('\n'),
      ),
      trailing: canOpen
          ? Semantics(
              label: '기사 열기',
              child: const ChatIcon(ChatGlyph.externalLink),
            )
          : null,
      onTap: canOpen
          ? () async {
              try {
                if (await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                )) {
                  return;
                }
              } catch (_) {}
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('기사 링크를 열 수 없어요.')),
                );
              }
            }
          : null,
    );
  }
}
