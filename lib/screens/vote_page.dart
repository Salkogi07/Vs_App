// lib/pages/vote_page.dart

import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/supabase_service.dart';
import '../models/character.dart';

class VotePage extends StatefulWidget {
  final MatchModel match;

  const VotePage({super.key, required this.match});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final _srv = SupabaseService();
  bool _isVoting = false;
  String? _votedForId; // 사용자가 투표한 캐릭터의 ID

  // 매치가 종료되었는지 확인하는 getter
  bool get _isMatchOver => DateTime.now().isAfter(widget.match.endAt);

  @override
  void initState() {
    super.initState();
    _checkVoteStatus();
  }

  /// 페이지가 로드될 때 사용자가 이미 투표했는지 확인합니다.
  Future<void> _checkVoteStatus() async {
    final votedId = await _srv.checkIfVoted(widget.match.id);
    if (mounted) {
      setState(() {
        _votedForId = votedId;
      });
    }
  }

  /// 투표를 처리하는 함수
  Future<void> _handleVote(String characterId) async {
    // 이미 투표했거나, 투표가 진행 중이거나, 매치가 종료되었다면 아무것도 하지 않음
    if (_votedForId != null || _isVoting || _isMatchOver) return;

    setState(() {
      _isVoting = true;
    });

    try {
      await _srv.castVote(
        matchId: widget.match.id,
        characterId: characterId,
      );
      if (mounted) {
        setState(() {
          _votedForId = characterId; // 투표 성공 시 상태 업데이트
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('투표가 완료되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('투표 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.match.a.name} vs ${widget.match.b.name}'),
      ),
      body: Column(
        children: [
          // 상단: 투표 영역
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CharacterVoteView(
                    character: widget.match.a,
                    onVote: () => _handleVote(widget.match.a.id),
                    isVoting: _isVoting,
                    isMatchOver: _isMatchOver,
                    hasVotedForThis: _votedForId == widget.match.a.id,
                    hasVotedForOther: _votedForId != null && _votedForId != widget.match.a.id,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CharacterVoteView(
                    character: widget.match.b,
                    onVote: () => _handleVote(widget.match.b.id),
                    isVoting: _isVoting,
                    isMatchOver: _isMatchOver,
                    hasVotedForThis: _votedForId == widget.match.b.id,
                    hasVotedForOther: _votedForId != null && _votedForId != widget.match.b.id,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32, thickness: 1),
          // 하단: 채팅 영역 (추후 구현)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    '채팅 기능이 추가될 예정입니다.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 캐릭터 정보와 투표 버튼을 표시하는 재사용 가능한 위젯
class _CharacterVoteView extends StatelessWidget {
  final Character character;
  final VoidCallback onVote;
  final bool isVoting;
  final bool isMatchOver;
  final bool hasVotedForThis;
  final bool hasVotedForOther;

  const _CharacterVoteView({
    required this.character,
    required this.onVote,
    required this.isVoting,
    required this.isMatchOver,
    required this.hasVotedForThis,
    required this.hasVotedForOther,
  });

  @override
  Widget build(BuildContext context) {
    // 투표 버튼 비활성화 조건
    final isVoteDisabled = isVoting || isMatchOver || hasVotedForThis || hasVotedForOther;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              character.avatarUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
              progress == null ? child : const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, __, ___) => const Icon(Icons.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '상세 설명',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  character.attributes,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isVoteDisabled ? null : onVote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasVotedForThis ? Colors.green : null,
                    foregroundColor: hasVotedForThis ? Colors.white : null,
                  ),
                  child: _buildButtonChild(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonChild() {
    if (isMatchOver) {
      return const Text('투표 종료');
    }
    if (hasVotedForThis) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check, size: 18),
          SizedBox(width: 4),
          Text('투표 완료'),
        ],
      );
    }
    if (hasVotedForOther) {
      return const Text('투표하기'); // 다른 쪽에 투표했으므로 비활성화 상태
    }
    if (isVoting) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return const Text('투표하기');
  }
}