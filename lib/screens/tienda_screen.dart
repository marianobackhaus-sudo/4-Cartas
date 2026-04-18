import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';

// ─── Coin Offer Model ─────────────────────────────────────────────────────────

class _CoinOffer {
  final int coins;
  final String price;
  final String? badge;
  final bool highlighted;

  const _CoinOffer({
    required this.coins,
    required this.price,
    this.badge,
    this.highlighted = false,
  });
}

const _coinOffers = [
  _CoinOffer(coins: 100, price: 'US\$ 0,99'),
  _CoinOffer(coins: 350, price: 'US\$ 2,49', badge: 'MÁS POPULAR', highlighted: true),
  _CoinOffer(coins: 800, price: 'US\$ 4,99', badge: 'MEJOR VALOR'),
];

// ─── Pack Model ───────────────────────────────────────────────────────────────

class _Pack {
  final String name;
  final String description;
  final int price;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;
  final IconData icon;

  const _Pack({
    required this.name,
    required this.description,
    required this.price,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.icon,
  });
}

const _packs = [
  _Pack(
    name: 'CARTAS NEON',
    description: 'Brillan en la oscuridad. Para los que juegan de noche.',
    price: 80,
    accentColor: Color(0xFF4DA3FF),
    cardColor: Color(0xFF0D1B3E),
    borderColor: Color(0xFF4DA3FF),
    icon: Icons.bolt_rounded,
  ),
  _Pack(
    name: 'CARTAS SCALONETA',
    description: 'Con la celeste y blanca. Campeones del mundo.',
    price: 120,
    accentColor: Color(0xFF75AADB),
    cardColor: Color(0xFF0A2A4A),
    borderColor: Color(0xFFFFFFFF),
    icon: Icons.sports_soccer_rounded,
  ),
  _Pack(
    name: 'BRAINROT',
    description: 'Meme, caos, exagerado y gracioso.',
    price: 60,
    accentColor: Color(0xFFA8FF3E),
    cardColor: Color(0xFF1A0A2E),
    borderColor: Color(0xFFFF3EA8),
    icon: Icons.sentiment_very_satisfied_rounded,
  ),
  _Pack(
    name: 'GRAFFITI CLASH',
    description: 'Callejero, urbano, explosivo.',
    price: 90,
    accentColor: Color(0xFFFF6B00),
    cardColor: Color(0xFF1A1000),
    borderColor: Color(0xFFFF6B00),
    icon: Icons.brush_rounded,
  ),
  _Pack(
    name: 'BLACK GOLD',
    description: 'Elegante, premium, sobrio.',
    price: 150,
    accentColor: Color(0xFFF5B642),
    cardColor: Color(0xFF0A0A0A),
    borderColor: Color(0xFFF5B642),
    icon: Icons.workspace_premium_rounded,
  ),
  _Pack(
    name: 'FROZEN ACE',
    description: 'Hielo, azul, blanco, más fino y frío.',
    price: 100,
    accentColor: Color(0xFFB8E8FF),
    cardColor: Color(0xFF0A1F2E),
    borderColor: Color(0xFFE0F4FF),
    icon: Icons.ac_unit_rounded,
  ),
  _Pack(
    name: 'INFERNO',
    description: 'Fuego, rojo, energía, agresivo visualmente.',
    price: 110,
    accentColor: Color(0xFFFF4500),
    cardColor: Color(0xFF1F0500),
    borderColor: Color(0xFFFF6B00),
    icon: Icons.local_fire_department_rounded,
  ),
  _Pack(
    name: 'VAPORWAVE',
    description: 'Rosa, celeste, retro digital, muy estético.',
    price: 100,
    accentColor: Color(0xFFFF6EC7),
    cardColor: Color(0xFF1A0A2E),
    borderColor: Color(0xFF6EC6FF),
    icon: Icons.waves_rounded,
  ),
  _Pack(
    name: 'PIXEL RUSH',
    description: 'Estilo arcade/8-bit, más gamer.',
    price: 80,
    accentColor: Color(0xFF00FF41),
    cardColor: Color(0xFF050F05),
    borderColor: Color(0xFF00FF41),
    icon: Icons.videogame_asset_rounded,
  ),
  _Pack(
    name: 'GALAXIA',
    description: 'Espacio, estrellas, violeta, azul oscuro.',
    price: 130,
    accentColor: Color(0xFF9D4EDD),
    cardColor: Color(0xFF050010),
    borderColor: Color(0xFF6A0DAD),
    icon: Icons.auto_awesome_rounded,
  ),
];

// ─── Tienda Screen ────────────────────────────────────────────────────────────

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  int _coins = 100;
  final Set<String> _ownedPacks = {};

  void _handleBuyPack(BuildContext context, _Pack pack) {
    if (_coins >= pack.price) {
      setState(() {
        _coins -= pack.price;
        _ownedPacks.add(pack.name);
      });
      showDialog(
        context: context,
        builder: (_) => _PurchaseSuccessDialog(pack: pack),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _BuyCoinsSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeepest,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeepest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppSpacing.base,
        title: const Text(
          'TIENDA',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          _CoinsWidget(amount: _coins),
          const SizedBox(width: AppSpacing.base),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgBase, AppColors.bgDeepest],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                'SKINS DE CARTAS',
                style: AppText.label.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: AppSpacing.md),
              ..._packs.map((pack) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.base),
                    child: _PackCard(
                      pack: pack,
                      ownedCoins: _coins,
                      isOwned: _ownedPacks.contains(pack.name),
                      onBuy: () => _handleBuyPack(context, pack),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pack Card ────────────────────────────────────────────────────────────────

class _PackCard extends StatelessWidget {
  final _Pack pack;
  final int ownedCoins;
  final bool isOwned;
  final VoidCallback onBuy;

  const _PackCard({
    required this.pack,
    required this.ownedCoins,
    required this.isOwned,
    required this.onBuy,
  });

  bool get _canAfford => ownedCoins >= pack.price;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview area
          _PackPreview(pack: pack),
          // Info area
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pack.name, style: AppText.titleSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            pack.description,
                            style: AppText.body.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${pack.price}',
                            style: AppText.bodyStrong.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Buy button
                    GestureDetector(
                      onTap: isOwned ? null : onBuy,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        decoration: BoxDecoration(
                          color: isOwned
                              ? AppColors.success.withValues(alpha: 0.15)
                              : _canAfford
                                  ? pack.accentColor
                                  : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isOwned
                                ? AppColors.success
                                : _canAfford
                                    ? pack.accentColor
                                    : AppColors.border,
                          ),
                          boxShadow: !isOwned && _canAfford
                              ? [
                                  BoxShadow(
                                    color: pack.accentColor
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            isOwned ? 'EQUIPADO ✓' : 'COMPRAR',
                            style: TextStyle(
                              color: isOwned
                                  ? AppColors.success
                                  : _canAfford
                                      ? AppColors.bgDeepest
                                      : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pack Preview ─────────────────────────────────────────────────────────────

class _PackPreview extends StatelessWidget {
  final _Pack pack;
  const _PackPreview({required this.pack});

  static const _angles = [-0.18, 0.0, 0.18];
  static const _offsets = [Offset(-28, 4), Offset(0, 0), Offset(28, 4)];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pack.cardColor,
            pack.accentColor.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle glow behind cards
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: pack.accentColor.withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          ...List.generate(3, (i) {
            return Transform.translate(
              offset: _offsets[i],
              child: Transform.rotate(
                angle: _angles[i],
                child: _SkinCardBack(pack: pack),
              ),
            );
          }),
          // Pack icon badge top-right
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: pack.accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: pack.accentColor.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(pack.icon, color: pack.accentColor, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skin Card Back ───────────────────────────────────────────────────────────

class _SkinCardBack extends StatelessWidget {
  final _Pack pack;
  const _SkinCardBack({required this.pack});

  @override
  Widget build(BuildContext context) {
    const width = 56.0;
    const height = width / AppCardDims.aspectRatio;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: pack.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: pack.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: pack.accentColor.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.layers_rounded,
          color: pack.accentColor.withValues(alpha: 0.6),
          size: width * 0.42,
        ),
      ),
    );
  }
}

// ─── Coins Widget ─────────────────────────────────────────────────────────────

class _CoinsWidget extends StatelessWidget {
  final int amount;
  const _CoinsWidget({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$amount',
            style: AppText.bodyStrong.copyWith(
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(width: 1, height: 18, color: AppColors.border),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _BuyCoinsSheet(),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Purchase Success Dialog ──────────────────────────────────────────────────

class _PurchaseSuccessDialog extends StatelessWidget {
  final _Pack pack;
  const _PurchaseSuccessDialog({required this.pack});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 32),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '¡COMPRA EXITOSA!',
              style: AppText.title.copyWith(letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              pack.name,
              style: AppText.bodyStrong.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'El skin fue agregado a tu perfil.\nActivalo desde Mi Perfil.',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.35),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '¡GENIAL!',
                    style: TextStyle(
                      color: AppColors.bgDeepest,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
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

// ─── Buy Coins Sheet ──────────────────────────────────────────────────────────

class _BuyCoinsSheet extends StatelessWidget {
  const _BuyCoinsSheet();

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.xl + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text('COMPRAR MONEDAS', style: AppText.title.copyWith(letterSpacing: 1)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Elegí el paquete que más te conviene',
            style: AppText.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _coinOffers
                .map((offer) => Expanded(child: _CoinOfferCard(offer: offer)))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'Los precios están en dólares estadounidenses.',
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Coin Offer Card ──────────────────────────────────────────────────────────

class _CoinOfferCard extends StatelessWidget {
  final _CoinOffer offer;
  const _CoinOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final border = offer.highlighted ? AppColors.primary : AppColors.border;
    final bg = offer.highlighted
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border, width: offer.highlighted ? 1.5 : 1),
          boxShadow: offer.highlighted
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 14)]
              : null,
        ),
        child: Column(
          children: [
            if (offer.badge != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: offer.highlighted ? AppColors.primary : AppColors.surfaceElevated,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg - 1),
                  ),
                ),
                child: Text(
                  offer.badge!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: offer.highlighted ? AppColors.onPrimary : AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              )
            else
              const SizedBox(height: AppSpacing.xl),
            const SizedBox(height: AppSpacing.md),
            const Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 22),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${offer.coins}',
              style: AppText.scoreNumeric.copyWith(
                color: offer.highlighted ? AppColors.primary : AppColors.textPrimary,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('monedas', style: AppText.caption),
            const SizedBox(height: AppSpacing.base),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: offer.highlighted ? AppColors.primary : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: border),
                  ),
                  child: Center(
                    child: Text(
                      offer.price,
                      style: TextStyle(
                        color: offer.highlighted ? AppColors.onPrimary : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
