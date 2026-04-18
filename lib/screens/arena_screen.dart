import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../engine/models/card.dart';

// ─── Phase ────────────────────────────────────────────────────────────────────

enum _Phase {
  peekInitial,             // Start: choose 2 cards to memorize
  turn,                    // Normal turn: tap mazo or cut
  cardDrawn,               // Card drawn, waiting for action
  powerPeekOwn,            // 7/8: peek one own card
  powerPeekOpponent,       // 9/10: peek one opponent card
  powerSwapSelectOwn,      // J/Q step 1: select own card
  powerSwapSelectOpponent, // J/Q step 2: select opponent card
  powerKingPeek,           // K step 1: peek any 2 cards
  powerKingDecide,         // K step 2: swap or leave
}

// ─── King Target ──────────────────────────────────────────────────────────────

class _KingTarget {
  final bool isOwn;
  final int slot;
  const _KingTarget(this.isOwn, this.slot);

  @override
  bool operator ==(Object o) => o is _KingTarget && o.isOwn == isOwn && o.slot == slot;
  @override
  int get hashCode => Object.hash(isOwn, slot);
}

// ─── Discard Entry ────────────────────────────────────────────────────────────

class _DiscardEntry {
  final GameCard card;
  final double angle;
  final Offset offset;
  const _DiscardEntry(this.card, this.angle, this.offset);
}

// ─── Deck Builder ─────────────────────────────────────────────────────────────

List<GameCard> _buildFullDeck() {
  final cards = <GameCard>[];
  for (final suit in Suit.values) {
    for (int rank = 1; rank <= 13; rank++) {
      cards.add(GameCard.regular(suit, rank));
    }
  }
  cards.add(const GameCard.joker());
  cards.add(const GameCard.joker());
  return cards;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _suitSymbol(Suit s) {
  switch (s) {
    case Suit.hearts:   return '♥';
    case Suit.diamonds: return '♦';
    case Suit.clubs:    return '♣';
    case Suit.spades:   return '♠';
  }
}

String _rankLabel(int r) {
  switch (r) {
    case 1: return 'A';  case 11: return 'J';
    case 12: return 'Q'; case 13: return 'K';
    default: return '$r';
  }
}

Color _suitColor(Suit s) =>
    (s == Suit.hearts || s == Suit.diamonds)
        ? AppColors.cardInkRed
        : AppColors.cardInkBlack;

int _totalRoundsFor(GameCard firstDiscard) {
  if (firstDiscard.isJoker) return 1;
  return firstDiscard.rank.clamp(1, 5);
}

// ─── Card Face ────────────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  final GameCard card;
  final double width;
  const _CardFace({required this.card, this.width = 72});

  @override
  Widget build(BuildContext context) {
    if (card.isJoker) return _JokerFace(width: width);
    final color = _suitColor(card.suit!);
    final sym = _suitSymbol(card.suit!);
    final rnk = _rankLabel(card.rank);
    final h = width / AppCardDims.aspectRatio;

    return Container(
      width: width, height: h,
      decoration: BoxDecoration(
        color: AppColors.cardFace,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardFaceEdge),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Stack(children: [
        Positioned(top: 5, left: 7, child: _CornerLabel(rnk: rnk, sym: sym, color: color)),
        Center(child: Text(sym, style: TextStyle(color: color, fontSize: width * .30, height: 1, fontWeight: FontWeight.w700))),
        Positioned(bottom: 5, right: 7, child: Transform.rotate(angle: math.pi, child: _CornerLabel(rnk: rnk, sym: sym, color: color))),
      ]),
    );
  }
}

class _JokerFace extends StatelessWidget {
  final double width;
  const _JokerFace({this.width = 72});
  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    return Container(
      width: width, height: h,
      decoration: BoxDecoration(
        color: AppColors.cardFace,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardInkJoker.withValues(alpha: .6)),
        boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
          BoxShadow(color: AppColors.cardInkJoker.withValues(alpha: .3), blurRadius: 12)],
      ),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('★', style: TextStyle(color: AppColors.cardInkJoker, fontSize: width * .28, height: 1)),
        Text('JKR', style: TextStyle(color: AppColors.cardInkJoker, fontSize: width * .14, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ])),
    );
  }
}

class _CornerLabel extends StatelessWidget {
  final String rnk, sym;
  final Color color;
  const _CornerLabel({required this.rnk, required this.sym, required this.color});
  @override
  Widget build(BuildContext context) {
    final s = TextStyle(color: color, fontWeight: FontWeight.w800, height: 1.1, fontSize: 13);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(rnk, style: s), Text(sym, style: s.copyWith(fontSize: 11))]);
  }
}

// ─── Card Back ────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  final double width;
  final Color? borderColor;
  final bool eyeActive;
  final Color eyeColor;
  final bool selected; // J/Q swap selected

  const _CardBack({
    this.width = 72, this.borderColor, this.eyeActive = false,
    this.eyeColor = AppColors.accent, this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    final bc = selected
        ? AppColors.primary
        : borderColor ?? (eyeActive ? eyeColor : AppColors.border);
    final bw = (eyeActive || selected) ? 1.5 : 1.0;

    return Container(
      width: width, height: h,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: .12)
            : AppColors.cardBack,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: bc, width: bw),
        boxShadow: [
          const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
          if (eyeActive || selected)
            BoxShadow(color: bc.withValues(alpha: .40), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: eyeActive
          ? Center(child: Icon(Icons.visibility_outlined, color: eyeColor, size: width * .46))
          : selected
              ? Center(child: Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: width * .46))
              : null,
    );
  }
}

// ─── Flip Card ────────────────────────────────────────────────────────────────

class _FlippableCard extends StatefulWidget {
  final bool showFace;
  final Widget front;
  final Widget back;
  const _FlippableCard({super.key, required this.showFace, required this.front, required this.back});

  @override
  State<_FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<_FlippableCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _anim = Tween<double>(begin: 0.0, end: math.pi).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.showFace) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_FlippableCard old) {
    super.didUpdateWidget(old);
    if (widget.showFace != old.showFace) widget.showFace ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, ch) {
        final angle = _anim.value;
        final showFront = angle > math.pi / 2;
        return Transform(
          transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(showFront ? angle - math.pi : angle),
          alignment: Alignment.center,
          child: showFront ? widget.front : widget.back,
        );
      },
    );
  }
}

// ─── Deck Card ────────────────────────────────────────────────────────────────

class _DeckCard extends StatelessWidget {
  final double width;
  final int count;
  final VoidCallback? onTap;
  final bool canDraw;
  const _DeckCard({this.width = 100, required this.count, this.onTap, this.canDraw = true});

  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    return GestureDetector(
      onTap: canDraw ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width, height: h,
        decoration: BoxDecoration(
          color: AppColors.cardBack,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: canDraw ? AppColors.primary.withValues(alpha: .7) : AppColors.border,
            width: canDraw ? 1.5 : 1.0),
          boxShadow: [
            const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
            if (canDraw) BoxShadow(color: AppColors.primary.withValues(alpha: .25), blurRadius: 14),
          ],
        ),
        child: Center(child: _StackedCardsIcon(size: width * .52)),
      ),
    );
  }
}

class _StackedCardsIcon extends StatelessWidget {
  final double size;
  const _StackedCardsIcon({required this.size});

  Widget _mini(double angle, double opacity) => Transform.rotate(
    angle: angle,
    child: Container(
      width: size, height: size / AppCardDims.aspectRatio,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: opacity * .18),
        borderRadius: BorderRadius.circular(size * .12),
        border: Border.all(color: AppColors.primary.withValues(alpha: opacity), width: 1),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.5, height: (size / AppCardDims.aspectRatio) * 1.35,
    child: Stack(alignment: Alignment.center, children: [
      _mini(-0.28, 0.35), _mini(0.18, 0.55), _mini(0.0, 0.90),
    ]),
  );
}

// ─── Discard Pile ─────────────────────────────────────────────────────────────

class _DiscardPile extends StatelessWidget {
  final List<_DiscardEntry> stack;
  final double width;
  const _DiscardPile({required this.stack, this.width = 100});

  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    if (stack.isEmpty) {
      return Container(
        width: width, height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border)),
        child: Center(child: Text('DESCARTE', style: AppText.caption)),
      );
    }
    final visible = stack.length > 10 ? stack.sublist(stack.length - 10) : stack;
    return SizedBox(
      width: width + 28, height: h + 28,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: visible.map((e) => Transform.translate(
          offset: e.offset,
          child: Transform.rotate(angle: e.angle, child: _CardFace(card: e.card, width: width)),
        )).toList(),
      ),
    );
  }
}

// ─── Power Banner ─────────────────────────────────────────────────────────────

class _PowerBannerOverlay extends StatelessWidget {
  final bool visible;
  final String text;
  final String sub;
  final Color color;
  const _PowerBannerOverlay({required this.visible, required this.text, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 350),
        child: Container(
          color: Colors.black.withValues(alpha: .45),
          child: Center(
            child: AnimatedScale(
              scale: visible ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 350),
              curve: Curves.elasticOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.bgDeepest,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: .45), blurRadius: 30, spreadRadius: 4)],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(text, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(sub, style: AppText.caption.copyWith(color: color.withValues(alpha: .8))),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Arena Screen ─────────────────────────────────────────────────────────────

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});
  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  final _random = math.Random();

  // ── game ─────────────────────────────────────────────────────────────────────
  _Phase _phase = _Phase.peekInitial;
  late List<GameCard> _deck;
  late List<_DiscardEntry> _discardStack;
  late List<GameCard> _playerCards;
  late List<GameCard> _opponentCards;
  int _roundsRemaining = 3;
  GameCard? _drawnCard;

  // ── initial peek ─────────────────────────────────────────────────────────────
  Set<int> _initialPeekShowing = {};
  int _peeksUsed = 0;
  Timer? _peekHideTimer;

  // ── known / flip state ───────────────────────────────────────────────────────
  Set<int> _justSwappedSlots = {};

  // ── 3-second temporary reveals ───────────────────────────────────────────────
  int? _revealOwnSlot;
  int? _revealOpponentSlot;
  Timer? _revealTimer;

  // ── power states ─────────────────────────────────────────────────────────────
  int? _swapOwnSlot;          // J/Q: selected own slot
  List<_KingTarget> _kingTargets = [];   // K: peeked targets (1 own + 1 opponent)

  // ── espejo penalty ────────────────────────────────────────────────────────────
  int _playerPenalty = 0;

  // ── match (best of 3 partidas) ────────────────────────────────────────────────
  int _playerPartidaWins = 0;
  int _opponentPartidaWins = 0;
  int _currentPartida = 1;

  // ── partida over ─────────────────────────────────────────────────────────────
  bool _partidaOver = false;
  bool _matchOver = false;

  // ── opponent turn ─────────────────────────────────────────────────────────────
  bool _isOpponentTurn = false;
  Timer? _opponentTimer;

  // ── settings ─────────────────────────────────────────────────────────────────
  double _musicVolume = 0.8;
  double _fxVolume = 1.0;
  bool _hapticEnabled = true;

  // ── banner ────────────────────────────────────────────────────────────────────
  bool _bannerVisible = false;
  String _bannerText = '';
  String _bannerSub = '';
  Color _bannerColor = AppColors.primary;

  @override
  void initState() { super.initState(); _initFullMatch(); }

  @override
  void dispose() {
    _peekHideTimer?.cancel();
    _revealTimer?.cancel();
    _opponentTimer?.cancel();
    super.dispose();
  }

  // ── Init ─────────────────────────────────────────────────────────────────────

  void _initFullMatch() {
    _opponentTimer?.cancel();
    _peekHideTimer?.cancel();
    _revealTimer?.cancel();
    setState(() {
      _playerPartidaWins = 0;
      _opponentPartidaWins = 0;
      _currentPartida = 1;
      _partidaOver = false;
      _matchOver = false;
    });
    _initPartida();
  }

  // Starts a fresh partida without resetting match score.
  void _initPartida() {
    final cards = _buildFullDeck()..shuffle(_random);
    final pCards = List<GameCard>.from(cards.sublist(0, 4));
    final oCards = List<GameCard>.from(cards.sublist(4, 8));
    final firstDiscard = cards[8];
    final deck = List<GameCard>.from(cards.sublist(9));
    final total = _totalRoundsFor(firstDiscard);
    setState(() {
      _playerCards = pCards;
      _opponentCards = oCards;
      _deck = deck;
      _discardStack = [_DiscardEntry(firstDiscard, _rAngle(), _rOffset())];
      _roundsRemaining = total;
      _phase = _Phase.peekInitial;
      _drawnCard = null;
      _initialPeekShowing = {};
      _peeksUsed = 0;
      _justSwappedSlots = {};
      _swapOwnSlot = null;
      _kingTargets = [];
      _revealOwnSlot = null;
      _revealOpponentSlot = null;
      _isOpponentTurn = false;
      _partidaOver = false;
      _playerPenalty = 0;
    });
  }

  // ── Random helpers ────────────────────────────────────────────────────────────
  double _rAngle() => (_random.nextDouble() - 0.5) * 0.52;
  Offset _rOffset() => Offset((_random.nextDouble() - 0.5) * 14, (_random.nextDouble() - 0.5) * 10);

  // ── End player turn → opponent thinks → ronda completes ───────────────────────
  void _endPlayerTurn() {
    _opponentTimer?.cancel();
    setState(() { _phase = _Phase.turn; _isOpponentTurn = true; });
    _opponentTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) _onRoundComplete();
    });
  }

  // Called when both player and opponent have played one ronda.
  void _onRoundComplete() {
    final newRounds = _roundsRemaining - 1;
    if (newRounds <= 0) {
      setState(() { _isOpponentTurn = false; _roundsRemaining = 0; });
      _endPartida();
    } else {
      setState(() { _isOpponentTurn = false; _roundsRemaining = newRounds; });
    }
  }

  // Ends the current partida, scores it, checks match result.
  void _endPartida() {
    _opponentTimer?.cancel();
    final playerScore = _playerCards.fold(0, (sum, c) => sum + c.value) + _playerPenalty;
    final opponentScore = _opponentCards.fold(0, (sum, c) => sum + c.value);
    int newPlayerWins = _playerPartidaWins;
    int newOpponentWins = _opponentPartidaWins;
    if (playerScore < opponentScore) {
      newPlayerWins++;
    } else if (opponentScore < playerScore) {
      newOpponentWins++;
    }
    final matchOver = newPlayerWins >= 2 || newOpponentWins >= 2 || _currentPartida >= 3;
    setState(() {
      _playerPartidaWins = newPlayerWins;
      _opponentPartidaWins = newOpponentWins;
      _isOpponentTurn = false;
      _partidaOver = true;
      _matchOver = matchOver;
    });
  }

  // Starts the next partida in the match.
  void _startNextPartida() {
    setState(() => _currentPartida += 1);
    _initPartida();
  }

  // ── Banner ───────────────────────────────────────────────────────────────────
  void _showBanner(String text, String sub, Color color, {Duration dur = const Duration(milliseconds: 1600)}) {
    setState(() { _bannerVisible = true; _bannerText = text; _bannerSub = sub; _bannerColor = color; });
    Future.delayed(dur, () { if (mounted) setState(() => _bannerVisible = false); });
  }

  // ── Initial peek ─────────────────────────────────────────────────────────────
  void _onTapInitialPeek(int i) {
    if (_initialPeekShowing.contains(i)) return; // already showing
    if (_peeksUsed >= 2) return; // already used both peeks

    _peekHideTimer?.cancel();
    final newShowing = {..._initialPeekShowing, i};
    final newPeeks = _peeksUsed + 1;

    setState(() {
      _initialPeekShowing = newShowing;
      _peeksUsed = newPeeks;
    });

    if (newPeeks == 2) {
      // Both selected: hide after 3s and start game
      _peekHideTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _initialPeekShowing = {};
          _phase = _Phase.turn;
        });
      });
    }
  }

  // ── Draw ─────────────────────────────────────────────────────────────────────
  void _drawCard() {
    if (_drawnCard != null || _deck.isEmpty || _phase != _Phase.turn || _isOpponentTurn) return;
    setState(() {
      _drawnCard = _deck.removeLast();
      _phase = _Phase.cardDrawn;
    });
  }

  void _discardDrawn() {
    final card = _drawnCard;
    if (card == null) return;
    setState(() {
      _discardStack = [..._discardStack, _DiscardEntry(card, _rAngle(), _rOffset())];
      _drawnCard = null;
    });
    _activatePower(card);
  }

  void _swapWithSlot(int i) {
    final drawn = _drawnCard;
    if (drawn == null) return;
    final outCard = _playerCards[i];
    final newCards = List<GameCard>.from(_playerCards)..[i] = drawn;
    setState(() {
      _playerCards = newCards;
      _discardStack = [..._discardStack, _DiscardEntry(outCard, _rAngle(), _rOffset())];
      _drawnCard = null;
      _justSwappedSlots = {..._justSwappedSlots, i};
    });
    _endPlayerTurn();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _justSwappedSlots = _justSwappedSlots.difference({i}));
    });
  }

  // ── Cut ──────────────────────────────────────────────────────────────────────
  void _handleCut() {
    _showBanner('¡CORTE!', 'Última vuelta del rival', AppColors.danger, dur: const Duration(seconds: 2));
    _opponentTimer?.cancel();
    setState(() => _isOpponentTurn = true);
    _opponentTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) { setState(() => _isOpponentTurn = false); _endPartida(); }
    });
  }

  // ── Powers ───────────────────────────────────────────────────────────────────
  void _activatePower(GameCard card) {
    if (card.isJoker) { _endPlayerTurn(); return; }
    switch (card.rank) {
      case 7:
      case 8:
        _showBanner('PODER ${_rankLabel(card.rank)}', 'Mirá una carta tuya', AppColors.accent);
        Future.delayed(const Duration(milliseconds: 1700), () {
          if (mounted) setState(() => _phase = _Phase.powerPeekOwn);
        });
      case 9:
      case 10:
        _showBanner('PODER ${_rankLabel(card.rank)}', 'Mirá una carta del rival', AppColors.warning);
        Future.delayed(const Duration(milliseconds: 1700), () {
          if (mounted) setState(() => _phase = _Phase.powerPeekOpponent);
        });
      case 11:
      case 12:
        _showBanner('PODER ${_rankLabel(card.rank)}', 'Intercambiá una tuya con una del rival', AppColors.success);
        Future.delayed(const Duration(milliseconds: 1700), () {
          if (mounted) setState(() { _phase = _Phase.powerSwapSelectOwn; _swapOwnSlot = null; });
        });
      case 13:
        _showBanner('PODER REY', 'Mirá 1 tuya y 1 del rival, decidí si intercambiar', AppColors.primary);
        Future.delayed(const Duration(milliseconds: 1700), () {
          if (mounted) setState(() { _phase = _Phase.powerKingPeek; _kingTargets = []; });
        });
      default:
        _endPlayerTurn();
    }
  }

  // ── 7/8 own peek ─────────────────────────────────────────────────────────────
  void _onPeekOwn(int i) {
    if (_phase != _Phase.powerPeekOwn) return;
    _revealTimer?.cancel();
    setState(() => _revealOwnSlot = i);
    _endPlayerTurn();
    _revealTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _revealOwnSlot = null);
    });
  }

  // ── 9/10 opponent peek ───────────────────────────────────────────────────────
  void _onPeekOpponent(int i) {
    if (_phase != _Phase.powerPeekOpponent) return;
    _revealTimer?.cancel();
    setState(() => _revealOpponentSlot = i);
    _endPlayerTurn();
    _revealTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _revealOpponentSlot = null);
    });
  }

  // ── J/Q swap ─────────────────────────────────────────────────────────────────
  void _onSwapSelectOwn(int i) {
    if (_phase != _Phase.powerSwapSelectOwn) return;
    setState(() { _swapOwnSlot = i; _phase = _Phase.powerSwapSelectOpponent; });
  }

  void _onSwapSelectOpponent(int i) {
    if (_phase != _Phase.powerSwapSelectOpponent) return;
    final own = _swapOwnSlot;
    if (own == null) return;
    final ownCard = _playerCards[own];
    final oppCard = _opponentCards[i];
    final newPlayer = List<GameCard>.from(_playerCards)..[own] = oppCard;
    final newOpponent = List<GameCard>.from(_opponentCards)..[i] = ownCard;
    setState(() {
      _playerCards = newPlayer;
      _opponentCards = newOpponent;
      _swapOwnSlot = null;
      _justSwappedSlots = {..._justSwappedSlots, own};
    });
    _endPlayerTurn();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _justSwappedSlots = _justSwappedSlots.difference({own}));
    });
    _showBanner('¡INTERCAMBIO!', '', AppColors.success);
  }

  // ── K king ───────────────────────────────────────────────────────────────────
  void _onKingPeek(bool isOwn, int i) {
    if (_phase != _Phase.powerKingPeek) return;
    final target = _KingTarget(isOwn, i);
    if (_kingTargets.contains(target)) return;
    // Enforce 1 from own side + 1 from opponent side
    if (_kingTargets.isNotEmpty && _kingTargets[0].isOwn == isOwn) return;
    final newTargets = [..._kingTargets, target];
    setState(() => _kingTargets = newTargets);
    if (newTargets.length == 2) {
      setState(() => _phase = _Phase.powerKingDecide);
    }
  }

  void _kingDecide(bool doSwap) {
    if (doSwap && _kingTargets.length == 2) {
      final a = _kingTargets[0];
      final b = _kingTargets[1];
      GameCard cardA = a.isOwn ? _playerCards[a.slot] : _opponentCards[a.slot];
      GameCard cardB = b.isOwn ? _playerCards[b.slot] : _opponentCards[b.slot];
      final newPlayer = List<GameCard>.from(_playerCards);
      final newOpponent = List<GameCard>.from(_opponentCards);
      if (a.isOwn) newPlayer[a.slot] = cardB; else newOpponent[a.slot] = cardB;
      if (b.isOwn) newPlayer[b.slot] = cardA; else newOpponent[b.slot] = cardA;
      setState(() { _playerCards = newPlayer; _opponentCards = newOpponent; });
      _showBanner('¡INTERCAMBIO REY!', '', AppColors.primary);
    }
    setState(() => _kingTargets = []);
    _endPlayerTurn();
  }

  // ── Mirror (Espejo) ──────────────────────────────────────────────────────────
  void _handleMirror() {
    if (_phase != _Phase.turn || _isOpponentTurn || _discardStack.isEmpty) return;
    final topCard = _discardStack.last.card;
    final matchIndices = <int>[];
    for (int i = 0; i < _playerCards.length; i++) {
      final c = _playerCards[i];
      final matches = topCard.isJoker ? c.isJoker : (!c.isJoker && c.rank == topCard.rank);
      if (matches) matchIndices.add(i);
    }
    if (matchIndices.isEmpty) {
      setState(() => _playerPenalty += 5);
      _showBanner('¡FALLASTE!', '+5 puntos de penalidad', AppColors.danger);
      _endPlayerTurn();
    } else {
      final newCards = [
        for (int i = 0; i < _playerCards.length; i++)
          if (!matchIndices.contains(i)) _playerCards[i],
      ];
      final newDiscard = [
        ..._discardStack,
        for (final i in matchIndices) _DiscardEntry(_playerCards[i], _rAngle(), _rOffset()),
      ];
      setState(() {
        _playerCards = newCards;
        _discardStack = newDiscard;
      });
      if (newCards.isEmpty) {
        _showBanner('¡ESPEJO! Sin cartas', 'Última vuelta del rival', AppColors.success);
        _opponentTimer?.cancel();
        setState(() => _isOpponentTurn = true);
        _opponentTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) { setState(() => _isOpponentTurn = false); _endPartida(); }
        });
      } else {
        final n = matchIndices.length;
        _showBanner('¡ESPEJO!', '$n carta${n > 1 ? 's' : ''} al descarte', AppColors.success);
        _endPlayerTurn();
      }
    }
  }

  // ── Exit confirmation ────────────────────────────────────────────────────────
  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('¿Salir del juego?',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        content: const Text('Perderás el progreso de la partida actual.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); Navigator.of(context).pop(); },
            child: const Text('Salir', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Settings sheet ────────────────────────────────────────────────────────────
  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final sliderTheme = SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: .18),
            trackHeight: 3,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.base, AppSpacing.xl, AppSpacing.xl2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill))),
              const SizedBox(height: AppSpacing.xl),
              const Text('CONFIGURACIÓN', style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 15,
                  fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: AppSpacing.xl2),

              // Música
              Row(children: [
                const Icon(Icons.music_note_rounded, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Text('Música', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('${(_musicVolume * 100).round()}%', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ]),
              SliderTheme(
                data: sliderTheme,
                child: Slider(
                  value: _musicVolume,
                  onChanged: (v) { setState(() => _musicVolume = v); setSheet(() {}); },
                ),
              ),

              // Sonido FX
              Row(children: [
                const Icon(Icons.volume_up_rounded, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Text('Sonido FX', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('${(_fxVolume * 100).round()}%', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ]),
              SliderTheme(
                data: sliderTheme,
                child: Slider(
                  value: _fxVolume,
                  onChanged: (v) { setState(() => _fxVolume = v); setSheet(() {}); },
                ),
              ),

              const SizedBox(height: AppSpacing.xs),
              // Vibración
              Row(children: [
                const Icon(Icons.vibration_rounded, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Text('Vibración', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                const Spacer(),
                Switch(
                  value: _hapticEnabled,
                  onChanged: (v) { setState(() => _hapticEnabled = v); setSheet(() {}); },
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.border,
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hasOwnKingTarget = _kingTargets.any((t) => t.isOwn);
    final hasOppKingTarget = _kingTargets.any((t) => !t.isOwn);
    final opponentEye = _phase == _Phase.powerPeekOpponent;
    final opponentKingEye = _phase == _Phase.powerKingPeek && !hasOppKingTarget;
    final ownKingEyeEnabled = _phase == _Phase.powerKingPeek && !hasOwnKingTarget;
    final opponentKingPeeked = _kingTargets.where((t) => !t.isOwn).map((t) => t.slot).toSet();
    final playerKingPeeked = _kingTargets.where((t) => t.isOwn).map((t) => t.slot).toSet();
    final swapOpponent = _phase == _Phase.powerSwapSelectOpponent;

    return Scaffold(
      backgroundColor: AppColors.bgDeepest,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeepest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
          onPressed: () => _confirmExit(context),
        ),
        title: const Text('4 CARTAS BLITZ', style: TextStyle(
          color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: Stack(children: [
        Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppColors.bgBase, AppColors.bgDeepest])),
          child: SafeArea(
            child: Column(children: [
              _OpponentSection(
                opponentCards: _opponentCards,
                revealingSlot: _revealOpponentSlot,
                peekEye: opponentEye || opponentKingEye,
                kingPeekedSlots: opponentKingPeeked,
                swapSelectable: swapOpponent,
                isThinking: _isOpponentTurn,
                onTapCard: (i) {
                  if (_phase == _Phase.powerPeekOpponent) _onPeekOpponent(i);
                  else if (opponentKingEye) _onKingPeek(false, i);
                  else if (_phase == _Phase.powerSwapSelectOpponent) _onSwapSelectOpponent(i);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _RoundsBadge(remaining: _roundsRemaining, currentPartida: _currentPartida, playerWins: _playerPartidaWins, opponentWins: _opponentPartidaWins),
              const SizedBox(height: AppSpacing.xs),
              _PhaseHint(
                phase: _phase, peeksUsed: _peeksUsed,
                kingCount: _kingTargets.length, swapOwnSelected: _swapOwnSlot != null,
                kingPickedOwn: hasOwnKingTarget, kingPickedOpp: hasOppKingTarget,
              ),
              const Spacer(),
              _TurnIndicator(isPlayerTurn: _phase == _Phase.turn && !_isOpponentTurn),
              const SizedBox(height: AppSpacing.sm),
              _TableCenter(
                deckCount: _deck.length,
                discardStack: _discardStack,
                drawnCard: _drawnCard,
                canDraw: _phase == _Phase.turn && _drawnCard == null && !_isOpponentTurn,
                onDrawCard: _drawCard,
                onDiscardDrawn: _discardDrawn,
              ),
              const Spacer(),
              _ActionBar(
                phase: _phase,
                isOpponentTurn: _isOpponentTurn,
                onCut: _handleCut,
                onMirror: _handleMirror,
                onKingSwap: () => _kingDecide(true),
                onKingKeep: () => _kingDecide(false),
              ),
              const SizedBox(height: AppSpacing.xs),
              _PlayerHand(
                playerCards: _playerCards,
                phase: _phase,
                revealingSlot: _revealOwnSlot,
                kingPeekedSlots: playerKingPeeked,
                justSwappedSlots: _justSwappedSlots,
                initialPeekShowing: _initialPeekShowing,
                swapOwnSlot: _swapOwnSlot,
                ownKingEyeEnabled: ownKingEyeEnabled,
                onTapCard: (i) {
                  if (_phase == _Phase.peekInitial) _onTapInitialPeek(i);
                  else if (_phase == _Phase.cardDrawn) _swapWithSlot(i);
                  else if (_phase == _Phase.powerPeekOwn) _onPeekOwn(i);
                  else if (ownKingEyeEnabled) _onKingPeek(true, i);
                  else if (_phase == _Phase.powerSwapSelectOwn) _onSwapSelectOwn(i);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ]),
          ),
        ),
        // Power banner overlay
        Positioned.fill(
          child: _PowerBannerOverlay(
            visible: _bannerVisible,
            text: _bannerText,
            sub: _bannerSub,
            color: _bannerColor,
          ),
        ),
        // Partida over overlay
        if (_partidaOver)
          Positioned.fill(
            child: _GameOverOverlay(
              playerCards: _playerCards,
              opponentCards: _opponentCards,
              playerPartidaWins: _playerPartidaWins,
              opponentPartidaWins: _opponentPartidaWins,
              currentPartida: _currentPartida,
              matchOver: _matchOver,
              onNextPartida: _startNextPartida,
              onNewMatch: _initFullMatch,
              onExit: () => Navigator.of(context).pop(),
            ),
          ),
      ]),
    );
  }
}

// ─── Coin Stack Icon ─────────────────────────────────────────────────────────

class _CoinStackIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _CoinStackIcon({this.size = 28, this.color = AppColors.primary});

  Widget _coin(double w, double h, double alpha) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: color.withValues(alpha: alpha * .85),
      borderRadius: BorderRadius.circular(h / 2),
      border: Border.all(color: color, width: 1.2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final w = size * 1.15;
    final h = size * 0.32;
    final gap = h * 0.72;
    return SizedBox(
      width: w,
      height: h + gap * 2,
      child: Stack(alignment: Alignment.bottomCenter, children: [
        Positioned(bottom: 0,       child: _coin(w, h, 1.0)),
        Positioned(bottom: gap,     child: _coin(w, h, 0.80)),
        Positioned(bottom: gap * 2, child: _coin(w, h, 0.60)),
      ]),
    );
  }
}

// ─── Game Over Overlay ────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final List<GameCard> playerCards;
  final List<GameCard> opponentCards;
  final int playerPartidaWins;
  final int opponentPartidaWins;
  final int currentPartida;
  final bool matchOver;
  final VoidCallback onNextPartida;
  final VoidCallback onNewMatch;
  final VoidCallback onExit;

  const _GameOverOverlay({
    required this.playerCards, required this.opponentCards,
    required this.playerPartidaWins, required this.opponentPartidaWins,
    required this.currentPartida, required this.matchOver,
    required this.onNextPartida, required this.onNewMatch, required this.onExit,
  });

  int _score(List<GameCard> cards) => cards.fold(0, (sum, c) => sum + c.value);

  Widget _cardCol(GameCard card) {
    final valLabel = card.isJoker ? '−2' : '${card.value}';
    final valColor = card.isJoker ? AppColors.cardInkJoker : AppColors.textPrimary;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _CardFace(card: card, width: 58),
      const SizedBox(height: 5),
      Text(valLabel, style: TextStyle(color: valColor, fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _winDot(bool filled) => Container(
    width: 10, height: 10,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? AppColors.primary : Colors.transparent,
      border: Border.all(color: AppColors.primary, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final playerScore = _score(playerCards);
    final opponentScore = _score(opponentCards);
    final playerWinsPartida = playerScore < opponentScore;
    final tied = playerScore == opponentScore;

    final String resultLabel;
    final Color resultColor;
    if (tied) {
      resultLabel = 'EMPATE en esta partida';
      resultColor = AppColors.warning;
    } else if (playerWinsPartida) {
      resultLabel = matchOver
          ? (playerPartidaWins >= 2 ? '¡GANASTE EL MATCH!' : '¡Ganaste esta partida!')
          : '¡Ganaste esta partida!';
      resultColor = AppColors.success;
    } else {
      resultLabel = matchOver
          ? (opponentPartidaWins >= 2 ? 'El rival ganó el match' : 'El rival ganó esta partida')
          : 'El rival ganó esta partida';
      resultColor = AppColors.danger;
    }

    final String actionLabel = matchOver ? 'NUEVA PARTIDA' : 'SEGUIR';
    final VoidCallback actionTap = matchOver ? onNewMatch : onNextPartida;
    final Color frameColor = tied
        ? AppColors.warning
        : playerWinsPartida ? AppColors.success : AppColors.danger;

    return Container(
      color: Colors.black.withValues(alpha: .90),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: frameColor, width: 2),
              boxShadow: [BoxShadow(color: frameColor.withValues(alpha: .35), blurRadius: 32, spreadRadius: 2)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header: partida + dots + result
              const SizedBox(height: AppSpacing.xs),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('PARTIDA $currentPartida/3  ', style: AppText.caption.copyWith(letterSpacing: 1)),
                Row(children: List.generate(2, (i) => _winDot(i < playerPartidaWins))),
                Text('  vs  ', style: AppText.caption),
                Row(children: List.generate(2, (i) => _winDot(i < opponentPartidaWins))),
              ]),
              const SizedBox(height: AppSpacing.xs),
              Text(resultLabel, style: TextStyle(
                  color: resultColor, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: AppSpacing.base),

              // Player cards (compact)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: playerCards
                      .map((c) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _cardCol(c)))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Score comparison — single line
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('TÚ  ', style: AppText.caption),
                  Text('$playerScore', style: TextStyle(
                      color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                    child: Text('vs', style: AppText.caption),
                  ),
                  Text('$opponentScore', style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 28, fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()])),
                  Text('  RIVAL', style: AppText.caption),
                ]),
              ),

              if (matchOver) ...[
                const SizedBox(height: AppSpacing.sm),
                // Coins
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary.withValues(alpha: .18),
                      AppColors.warning.withValues(alpha: .10),
                    ]),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primary.withValues(alpha: .5)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _CoinStackIcon(size: 26, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('+${playerWinsPartida || tied ? 100 : 25}', style: const TextStyle(
                        color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()])),
                    const SizedBox(width: AppSpacing.xs),
                    Text('monedas', style: AppText.label.copyWith(color: AppColors.primary)),
                  ]),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Watch video
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.warning, width: 1.5),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.play_circle_outline_rounded, color: AppColors.warning, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text('VER VIDEO Y DUPLICAR', style: TextStyle(
                          color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),
              // Buttons
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: onExit,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: const Center(child: Text('SALIR', style: TextStyle(
                        color: AppColors.textSecondary, fontWeight: FontWeight.w800, letterSpacing: 1))),
                  ),
                )),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: GestureDetector(
                  onTap: actionTap,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .4), blurRadius: 10)],
                    ),
                    child: Center(child: Text(actionLabel,
                        style: const TextStyle(color: AppColors.bgDeepest,
                            fontWeight: FontWeight.w800, fontSize: 13))),
                  ),
                )),
              ]),
              const SizedBox(height: AppSpacing.xs),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Opponent Section ─────────────────────────────────────────────────────────

class _OpponentSection extends StatelessWidget {
  final List<GameCard> opponentCards;
  final int? revealingSlot;
  final bool peekEye;
  final Set<int> kingPeekedSlots;
  final bool swapSelectable;
  final bool isThinking;
  final void Function(int) onTapCard;

  const _OpponentSection({
    required this.opponentCards, required this.revealingSlot,
    required this.peekEye, required this.kingPeekedSlots,
    required this.swapSelectable, required this.isThinking, required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('NEON_DRIFTER', style: AppText.titleSmall),
              const SizedBox(height: 3),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isThinking
                  ? Row(key: const ValueKey('thinking'), children: [
                      Container(width: 7, height: 7,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('Pensando...', style: AppText.caption.copyWith(
                          color: AppColors.success, fontWeight: FontWeight.w500)),
                    ])
                  : Row(key: const ValueKey('waiting'), children: [
                      Container(width: 7, height: 7,
                          decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('Esperando', style: AppText.caption.copyWith(
                          color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                    ]),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final isRevealing = revealingSlot == i;
            final isKingPeeked = kingPeekedSlots.contains(i);
            final showFace = isRevealing || isKingPeeked;
            final tappable = peekEye && !showFace || swapSelectable;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1),
              child: GestureDetector(
                onTap: tappable ? () => onTapCard(i) : null,
                child: _FlippableCard(
                  showFace: showFace,
                  front: _CardFace(card: opponentCards[i], width: 68),
                  back: _CardBack(
                    width: 68,
                    eyeActive: peekEye && !isKingPeeked,
                    eyeColor: AppColors.warning,
                    selected: swapSelectable,
                  ),
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

// ─── Rounds Badge ─────────────────────────────────────────────────────────────

class _RoundsBadge extends StatelessWidget {
  final int remaining;
  final int currentPartida;
  final int playerWins;
  final int opponentWins;
  const _RoundsBadge({required this.remaining, required this.currentPartida, required this.playerWins, required this.opponentWins});

  Widget _dot(bool filled) => Container(
    width: 9, height: 9,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? AppColors.primary : Colors.transparent,
      border: Border.all(color: AppColors.primary, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.cardInkJoker;
    final isLast = remaining == 1;
    final roundLabel = isLast ? '⚡ ÚLTIMA RONDA ⚡' : 'RONDAS: $remaining';
    final roundColor = isLast ? AppColors.danger : purple;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Match score
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text('PARTIDA $currentPartida/3  ', style: AppText.caption.copyWith(letterSpacing: 1)),
        Row(children: List.generate(2, (i) => _dot(i < playerWins))),
        Text('  vs  ', style: AppText.caption),
        Row(children: List.generate(2, (i) => _dot(i < opponentWins))),
      ]),
      const SizedBox(height: 4),
      // Ronda badge
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: roundColor, width: 1.5),
          boxShadow: [BoxShadow(color: roundColor.withValues(alpha: .28), blurRadius: 14)],
        ),
        child: Text(roundLabel, style: TextStyle(
            color: roundColor, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      ),
    ]);
  }
}

// ─── Phase Hint ──────────────────────────────────────────────────────────────

class _PhaseHint extends StatelessWidget {
  final _Phase phase;
  final int peeksUsed;
  final int kingCount;
  final bool swapOwnSelected;
  final bool kingPickedOwn;
  final bool kingPickedOpp;
  const _PhaseHint({required this.phase, required this.peeksUsed, required this.kingCount,
    required this.swapOwnSelected, required this.kingPickedOwn, required this.kingPickedOpp});

  @override
  Widget build(BuildContext context) {
    String text = '';
    Color color = AppColors.textMuted;
    switch (phase) {
      case _Phase.peekInitial:
        text = peeksUsed == 0 ? 'Elegí 2 cartas para memorizar' : peeksUsed == 1 ? 'Elegí 1 carta más (${2 - peeksUsed} restante)' : 'Memorizalas bien... ⏳';
        color = AppColors.accent;
      case _Phase.powerPeekOwn:
        text = 'PODER: Tocá una carta tuya para ver';
        color = AppColors.accent;
      case _Phase.powerPeekOpponent:
        text = 'PODER: Tocá una carta del rival para ver';
        color = AppColors.warning;
      case _Phase.powerSwapSelectOwn:
        text = 'PODER: Elegí una de TUS cartas';
        color = AppColors.success;
      case _Phase.powerSwapSelectOpponent:
        text = 'PODER: Ahora tocá una carta del RIVAL';
        color = AppColors.success;
      case _Phase.powerKingPeek:
        if (!kingPickedOwn && !kingPickedOpp) text = 'REY: Tocá 1 tuya y 1 del rival';
        else if (kingPickedOwn) text = 'REY: Ahora tocá 1 carta del RIVAL';
        else text = 'REY: Ahora tocá 1 carta TUYA';
        color = AppColors.primary;
      case _Phase.powerKingDecide:
        text = '¿Intercambiás estas 2 cartas?';
        color = AppColors.primary;
      case _Phase.cardDrawn:
        text = 'Tocá una carta tuya para intercambiar · o tirá la robada';
        color = AppColors.textSecondary;
      default:
        text = '';
    }
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(text, style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center);
  }
}

// ─── Table Center ─────────────────────────────────────────────────────────────

class _TableCenter extends StatelessWidget {
  final int deckCount;
  final List<_DiscardEntry> discardStack;
  final GameCard? drawnCard;
  final bool canDraw;
  final VoidCallback onDrawCard;
  final VoidCallback onDiscardDrawn;

  const _TableCenter({
    required this.deckCount, required this.discardStack, required this.drawnCard,
    required this.canDraw, required this.onDrawCard, required this.onDiscardDrawn,
  });

  @override
  Widget build(BuildContext context) {
    final hasDraw = drawnCard != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            _DeckCard(width: hasDraw ? 80 : 100, count: deckCount, onTap: onDrawCard, canDraw: canDraw),
            Positioned(
              top: -6, right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .5), blurRadius: 8)]),
                child: Text('$deckCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Text('MAZO', style: AppText.caption),
        ]),
        if (hasDraw) ...[
          const SizedBox(width: AppSpacing.md),
          Column(children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(drawnCard),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.elasticOut,
              builder: (ctx, scale, child) => Transform.scale(scale: scale, child: child),
              child: GestureDetector(
                onTap: onDiscardDrawn,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .55), blurRadius: 22, spreadRadius: 3)],
                  ),
                  child: _CardFace(card: drawnCard!, width: 90),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('TIRAR', style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ]),
        ],
        SizedBox(width: hasDraw ? AppSpacing.md : AppSpacing.xl2 + AppSpacing.base),
        Column(children: [
          _DiscardPile(stack: discardStack, width: hasDraw ? 90 : 100),
          const SizedBox(height: AppSpacing.xs),
          Text('DESCARTE', style: AppText.caption.copyWith(color: AppColors.primary)),
        ]),
      ],
    );
  }
}

// ─── Action Bar ───────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final _Phase phase;
  final bool isOpponentTurn;
  final VoidCallback onCut;
  final VoidCallback onMirror;
  final VoidCallback onKingSwap;
  final VoidCallback onKingKeep;

  const _ActionBar({
    required this.phase, required this.isOpponentTurn, required this.onCut,
    required this.onMirror, required this.onKingSwap, required this.onKingKeep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: switch (phase) {
        _Phase.powerKingDecide => Row(children: [
          Expanded(child: _Btn(label: '¡INTERCAMBIAR!', icon: Icons.swap_horiz_rounded, color: AppColors.primary, solid: true, onTap: onKingSwap)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _Btn(label: 'DEJAR ASÍ', icon: Icons.close_rounded, color: AppColors.danger, solid: false, onTap: onKingKeep)),
        ]),
        _Phase.cardDrawn => Center(child: Text(
          'Tocá una carta tuya para intercambiar',
          style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center)),
        _Phase.peekInitial ||
        _Phase.powerPeekOwn ||
        _Phase.powerPeekOpponent ||
        _Phase.powerSwapSelectOwn ||
        _Phase.powerSwapSelectOpponent ||
        _Phase.powerKingPeek => const SizedBox(height: 52),
        _ => Row(children: [
          Expanded(child: _Btn(label: 'CORTAR', icon: Icons.content_cut_rounded, color: AppColors.danger, solid: false, onTap: isOpponentTurn ? () {} : onCut, disabled: isOpponentTurn)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _Btn(label: '¡ESPEJO!', icon: Icons.copy_all_rounded, color: AppColors.success, solid: true, onTap: isOpponentTurn ? () {} : onMirror, disabled: isOpponentTurn)),
        ]),
      },
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool solid;
  final bool disabled;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.icon, required this.color, required this.solid, required this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = disabled ? AppColors.textMuted : color;
    final bg = solid ? effectiveColor : effectiveColor.withValues(alpha: .15);
    final fg = solid ? AppColors.bgDeepest : effectiveColor;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: effectiveColor, width: 1.5),
            boxShadow: disabled ? [] : [BoxShadow(color: effectiveColor.withValues(alpha: .30), blurRadius: 12)],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
          ]),
        ),
      ),
    );
  }
}

// ─── Turn Indicator ──────────────────────────────────────────────────────────

class _TurnIndicator extends StatelessWidget {
  final bool isPlayerTurn;
  const _TurnIndicator({required this.isPlayerTurn});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isPlayerTurn ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: AppColors.accent.withValues(alpha: .12),
          border: Border.all(color: AppColors.accent.withValues(alpha: .5), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 11),
          const SizedBox(width: 4),
          Text('TU TURNO', style: AppText.caption.copyWith(
              color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.5)),
        ]),
      ),
    );
  }
}

// ─── Player Hand ─────────────────────────────────────────────────────────────

class _PlayerHand extends StatelessWidget {
  final List<GameCard> playerCards;
  final _Phase phase;
  final int? revealingSlot;
  final Set<int> kingPeekedSlots;
  final Set<int> justSwappedSlots;
  final Set<int> initialPeekShowing;
  final int? swapOwnSlot;
  final bool ownKingEyeEnabled;
  final void Function(int) onTapCard;

  const _PlayerHand({
    required this.playerCards, required this.phase, required this.revealingSlot,
    required this.kingPeekedSlots, required this.justSwappedSlots,
    required this.initialPeekShowing, required this.swapOwnSlot,
    required this.ownKingEyeEnabled, required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.cardInkJoker;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final card = playerCards[i];
        final isRevealing = revealingSlot == i;
        final isKingPeeked = kingPeekedSlots.contains(i);
        final isInitialPeek = initialPeekShowing.contains(i);
        final justSwapped = justSwappedSlots.contains(i);
        final showFace = isRevealing || isKingPeeked || (isInitialPeek && !justSwapped);

        final isSwapOwn = swapOwnSlot == i;
        final eyeActive = phase == _Phase.powerPeekOwn || (ownKingEyeEnabled && !isKingPeeked);
        final tappable = switch (phase) {
          _Phase.peekInitial => !isInitialPeek,
          _Phase.cardDrawn => true,
          _Phase.powerPeekOwn => !isRevealing,
          _Phase.powerKingPeek => ownKingEyeEnabled && !isKingPeeked,
          _Phase.powerSwapSelectOwn => true,
          _ => false,
        };

        Color borderColor;
        if (isSwapOwn) borderColor = AppColors.primary;
        else if (phase == _Phase.cardDrawn) borderColor = AppColors.accent;
        else if (phase == _Phase.peekInitial) borderColor = AppColors.accent;
        else borderColor = purple;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1),
          child: GestureDetector(
            onTap: tappable ? () => onTapCard(i) : null,
            child: _FlippableCard(
              key: ValueKey('p_${i}_${card.toString()}'),
              showFace: showFace,
              front: _CardFace(card: card, width: 72),
              back: _CardBack(
                width: 72,
                borderColor: borderColor,
                eyeActive: eyeActive,
                eyeColor: AppColors.accent,
                selected: isSwapOwn,
              ),
            ),
          ),
        );
      }),
    );
  }
}
