import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:geoapp/geoapp.dart';
import 'package:google_fonts/google_fonts.dart';

/// FrontPage - Akshara Intelligence landing experience
/// Built for Flutter web with responsive layout and lightweight interactions.
class FrontPage extends StatefulWidget {
  const FrontPage({super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  final ScrollController _scrollController = ScrollController();
  final _demoSectionKey = GlobalKey();
  final _ctaSectionKey = GlobalKey();
  late final List<_GeometryStep> _demoSteps;

  @override
  void initState() {
    super.initState();
    _demoSteps = List<_GeometryStep>.from(sampleGeometrySteps);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ThemeData _buildLocalTheme(BuildContext context) {
    final base = Theme.of(context);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme.copyWith(
      displayLarge: GoogleFonts.poppins(
          textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      displayMedium: GoogleFonts.poppins(
          textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      displaySmall: GoogleFonts.poppins(
          textStyle: const TextStyle(fontWeight: FontWeight.w600)),
    ));

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _Palette.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: _Palette.primary,
      secondary: _Palette.secondary,
      tertiary: _Palette.accent,
      surface: _Palette.neutralLight,
      surfaceContainerHighest: Colors.white,
      onSurfaceVariant: _Palette.neutralDark.withOpacity(0.7),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: _Palette.neutralLight,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: _Palette.neutralDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _Palette.accent,
          foregroundColor: _Palette.primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _Palette.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _Palette.secondary,
          side: const BorderSide(color: _Palette.secondary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  void _openGeoDrawPlayground() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProblemFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _buildLocalTheme(context);

    return Theme(
      data: theme,
      child: Scaffold(
        body: Scrollbar(
          controller: _scrollController,
          thumbVisibility: kIsWeb,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopNavigation(
                  onDemoTap: () => _scrollTo(_demoSectionKey),
                  onContactTap: () => _scrollTo(_ctaSectionKey),
                  onLaunchGeoDraw: _openGeoDrawPlayground,
                  onWorkspaceTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const ProblemManagementScreen(),
                    ),
                  ),
                ),
                _HeroSection(
                  demoKey: _demoSectionKey,
                  onLaunchGeoDraw: _openGeoDrawPlayground,
                  onPrimaryCta: () => _scrollTo(_demoSectionKey),
                  onSecondaryCta: () => _scrollTo(_ctaSectionKey),
                ),
                const _VisionRoadmapSection(),
                const _ValuePropositionSection(),
                const _FeatureShowcaseSection(),
                _InteractiveDemoSection(
                  key: _demoSectionKey,
                  steps: _demoSteps,
                ),
                const _UseCasesSection(),
                const _TestimonialsSection(),
                const _HowItWorksSection(),
                const _TeamSection(),
                _CtaSection(key: _ctaSectionKey),
                const _FooterSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavigation extends StatelessWidget {
  const _TopNavigation({
    required this.onDemoTap,
    required this.onContactTap,
    required this.onLaunchGeoDraw,
    required this.onWorkspaceTap,
  });

  final VoidCallback onDemoTap;
  final VoidCallback onContactTap;
  final VoidCallback onLaunchGeoDraw;
  final VoidCallback onWorkspaceTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            _LogoMark(),
            const Spacer(),
            _NavButton(label: 'Live Demo', onTap: onDemoTap),
            _NavButton(label: 'Features', onTap: onDemoTap),
            _NavButton(label: 'Contact', onTap: onContactTap),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: onLaunchGeoDraw,
              style: OutlinedButton.styleFrom(
                foregroundColor: _Palette.secondary,
                side: const BorderSide(color: _Palette.secondary, width: 1.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.draw),
              label: const Text('Launch GeoDraw'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onWorkspaceTap,
              style: FilledButton.styleFrom(
                backgroundColor: _Palette.secondary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.explore),
              label: const Text('Open Problem Workspace'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.demoKey,
    required this.onLaunchGeoDraw,
    required this.onPrimaryCta,
    required this.onSecondaryCta,
  });

  final GlobalKey demoKey;
  final VoidCallback onLaunchGeoDraw;
  final VoidCallback onPrimaryCta;
  final VoidCallback onSecondaryCta;

  @override
  Widget build(BuildContext context) {
    final prefersReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Container(
      color: _Palette.primary,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 900;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!prefersReducedMotion)
                    Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        width: isSmall ? 140 : 200,
                        height: isSmall ? 140 : 200,
                        child: const _AnimatedHeroMesh(),
                      ),
                    ),
                  Flex(
                    direction: isSmall ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: isSmall
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: isSmall ? 0 : 5,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: isSmall ? 0 : 40,
                              bottom: isSmall ? 32 : 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'One Algebraic Core. Infinite Domains.',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      height: 1.05,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Starting with International Math Olympiad geometry, expanding through physics and AI integration, '
                                'toward robotics—all powered by a unified symbolic algebra framework that never hallucinates.',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 28),
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: [
                                  ElevatedButton(
                                    onPressed: onLaunchGeoDraw,
                                    child:
                                        const Text('Launch GeoDraw Playground'),
                                  ),
                                  OutlinedButton(
                                    onPressed: onSecondaryCta,
                                    child: const Text('Request Early Access'),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (context) =>
                                              const ProblemManagementScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.list_alt),
                                    label: const Text('Enter Problem List'),
                                  ),
                                  TextButton(
                                    onPressed: onPrimaryCta,
                                    child: const Text('View Interactive Demo'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isSmall)
                        Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: 500,
                            child: _GeometryHeroDemo(
                                prefersReducedMotion: prefersReducedMotion),
                          ),
                        )
                      else
                        SizedBox(
                          height: 400,
                          width: double.infinity,
                          child: _GeometryHeroDemo(
                              prefersReducedMotion: prefersReducedMotion),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GeometryHeroDemo extends StatefulWidget {
  const _GeometryHeroDemo({required this.prefersReducedMotion});

  final bool prefersReducedMotion;

  @override
  State<_GeometryHeroDemo> createState() => _GeometryHeroDemoState();
}

class _GeometryHeroDemoState extends State<_GeometryHeroDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..addListener(() {
        if (!widget.prefersReducedMotion && mounted) {
          setState(() {
            _currentStep = ((_controller.value * sampleGeometrySteps.length))
                .floor()
                .clamp(0, sampleGeometrySteps.length - 1);
          });
        }
      });
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    if (!widget.prefersReducedMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GeometryHeroDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prefersReducedMotion != widget.prefersReducedMotion) {
      if (widget.prefersReducedMotion) {
        _controller.stop();
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = sampleGeometrySteps[_currentStep];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter:
                      _GeometryScenePainter(animationValue: _animation.value),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _SymbolicStepsToggle(currentStep: currentStep),
        ],
      ),
    );
  }
}

class _VisionRoadmapSection extends StatelessWidget {
  const _VisionRoadmapSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Palette.primary.withOpacity(0.03),
            _Palette.secondary.withOpacity(0.03),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('The Vision: Incremental Mastery',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600, color: _Palette.primary)),
              const SizedBox(height: 20),
              Text(
                'One core algebraic framework. Multiple domains. A clear roadmap from competitive math to autonomous intelligence.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _Palette.neutralDark.withOpacity(0.85), height: 1.5),
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 900;
                  if (isSmall) {
                    return Column(
                      children: [
                        _RoadmapPhaseCard(
                          phase: 'TODAY',
                          title: 'Geometry',
                          description:
                              'Solve International Math Olympiad and competitive geometry problems with verified, step-by-step proofs.',
                          features: const [
                            '✓ IMO/USAMO problem solving',
                            '✓ Interactive GeoDraw canvas',
                            '✓ Solver backend (live)',
                            '✓ CLI & API access',
                          ],
                          color: _Palette.secondary,
                          icon: Icons.functions_outlined,
                        ),
                        const SizedBox(height: 32),
                        _RoadmapPhaseCard(
                          phase: 'NEXT',
                          title: 'Physics',
                          description:
                              'Extend the algebraic core to mechanics, electromagnetics, and physical simulations with the same symbolic rigor.',
                          features: const [
                            '→ Classical mechanics',
                            '→ Electromagnetic fields',
                            '→ AI-augmented reasoning',
                            '→ Natural language interface',
                          ],
                          color: _Palette.primary,
                          icon: Icons.waves_outlined,
                        ),
                        const SizedBox(height: 32),
                        _RoadmapPhaseCard(
                          phase: 'FUTURE',
                          title: 'Robotics',
                          description:
                              'Math + Physics + AI convergence for autonomous systems with real-time, provably correct control and planning.',
                          features: const [
                            '⟡ Motion planning',
                            '⟡ Autonomous control',
                            '⟡ Industrial automation',
                            '⟡ Verifiable AI agents',
                          ],
                          color: _Palette.accent,
                          icon: Icons.precision_manufacturing_outlined,
                        ),
                      ],
                    );
                  }
                  
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RoadmapPhaseCard(
                          phase: 'TODAY',
                          title: 'Geometry',
                          description:
                              'Solve International Math Olympiad and competitive geometry problems with verified, step-by-step proofs.',
                          features: const [
                            '✓ IMO/USAMO problem solving',
                            '✓ Interactive GeoDraw canvas',
                            '✓ Solver backend (live)',
                            '✓ CLI & API access',
                          ],
                          color: _Palette.secondary,
                          icon: Icons.functions_outlined,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _RoadmapPhaseCard(
                          phase: 'NEXT',
                          title: 'Physics',
                          description:
                              'Extend the algebraic core to mechanics, electromagnetics, and physical simulations with the same symbolic rigor.',
                          features: const [
                            '→ Classical mechanics',
                            '→ Electromagnetic fields',
                            '→ AI-augmented reasoning',
                            '→ Natural language interface',
                          ],
                          color: _Palette.primary,
                          icon: Icons.waves_outlined,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _RoadmapPhaseCard(
                          phase: 'FUTURE',
                          title: 'Robotics',
                          description:
                              'Math + Physics + AI convergence for autonomous systems with real-time, provably correct control and planning.',
                          features: const [
                            '⟡ Motion planning',
                            '⟡ Autonomous control',
                            '⟡ Industrial automation',
                            '⟡ Verifiable AI agents',
                          ],
                          color: _Palette.accent,
                          icon: Icons.precision_manufacturing_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _Palette.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _Palette.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hub_outlined,
                        color: _Palette.secondary, size: 32),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        'One Unified Algebraic Framework Powers All Phases',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _Palette.primary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoadmapPhaseCard extends StatelessWidget {
  const _RoadmapPhaseCard({
    required this.phase,
    required this.title,
    required this.description,
    required this.features,
    required this.color,
    required this.icon,
  });

  final String phase;
  final String title;
  final String description;
  final List<String> features;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  phase,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                ),
              ),
              const Spacer(),
              Icon(icon, color: color, size: 36),
            ],
          ),
          const SizedBox(height: 20),
          Text(title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: _Palette.primary)),
          const SizedBox(height: 12),
          Text(description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6, color: _Palette.neutralDark.withOpacity(0.85))),
          const SizedBox(height: 24),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.substring(0, 1),
                      style: TextStyle(
                          color: color, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature.substring(2),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _Palette.neutralDark, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SymbolicStepsToggle extends StatefulWidget {
  const _SymbolicStepsToggle({required this.currentStep});

  final _GeometryStep currentStep;

  @override
  State<_SymbolicStepsToggle> createState() => _SymbolicStepsToggleState();
}

class _SymbolicStepsToggleState extends State<_SymbolicStepsToggle> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'View symbolic steps',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: _expanded ? 120 : 0,
          child: ClipRect(
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sampleGeometrySteps.map((step) {
                    final isActive = step.title == widget.currentStep.title;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isActive ? 1.0 : 0.4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.title,
                                style: TextStyle(
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w500)),
                            const SizedBox(height: 4),
                            Math.tex(
                              step.latex,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(step.explanation,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ValuePropositionSection extends StatelessWidget {
  const _ValuePropositionSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Palette.neutralLight,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The Akshara Advantage',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: _Palette.primary)),
              const SizedBox(height: 16),
              Text(
                'Built to scale from competitive mathematics to autonomous systems',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _Palette.neutralDark.withOpacity(0.8)),
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 900;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: valuePropositions
                        .map((prop) => _HoverCard(
                            prop: prop,
                            width: isSmall
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 48) / 2))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  const _HoverCard({required this.prop, required this.width});

  final _ValueProp prop;
  final double width;

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: widget.width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _hovering
                  ? _Palette.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
              blurRadius: _hovering ? 24 : 12,
              offset: Offset(0, _hovering ? 16 : 8),
            ),
          ],
          border: Border.all(color: _Palette.primary.withOpacity(0.08)),
        ),
        transform: Matrix4.identity()..translate(0.0, _hovering ? -6.0 : 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.prop.icon, size: 36, color: _Palette.secondary),
            const SizedBox(height: 16),
            Text(widget.prop.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600, color: _Palette.primary)),
            const SizedBox(height: 12),
            Text(widget.prop.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: _Palette.neutralDark)),
          ],
        ),
      ),
    );
  }
}

class _FeatureShowcaseSection extends StatelessWidget {
  const _FeatureShowcaseSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(featureShowcaseItems.length, (index) {
              final item = featureShowcaseItems[index];
              final isEven = index.isEven;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == featureShowcaseItems.length - 1 ? 0 : 56),
                child: _FeatureRow(item: item, reverse: !isEven),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.item, required this.reverse});

  final _FeatureShowcaseItem item;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 900;
        final children = <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600, color: _Palette.primary)),
                const SizedBox(height: 16),
                Text(item.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.6, color: _Palette.neutralDark)),
                if (item.codeSnippet != null) ...[
                  const SizedBox(height: 20),
                  _CodeSnippet(snippet: item.codeSnippet!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 32, height: 24),
          Expanded(child: item.visualBuilder(context)),
        ];

        return Flex(
          direction: isSmall ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reverse && !isSmall ? children.reversed.toList() : children,
        );
      },
    );
  }
}

class _InteractiveDemoSection extends StatefulWidget {
  const _InteractiveDemoSection({super.key, required this.steps});

  final List<_GeometryStep> steps;

  @override
  State<_InteractiveDemoSection> createState() =>
      _InteractiveDemoSectionState();
}

class _InteractiveDemoSectionState extends State<_InteractiveDemoSection> {
  int _currentStepIndex = 0;
  bool _isAutoSolving = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoSolve() {
    _timer?.cancel();
    setState(() {
      _isAutoSolving = true;
      _currentStepIndex = 0;
    });
    const stepDuration = Duration(seconds: 1);
    _timer = Timer.periodic(stepDuration, (timer) {
      if (_currentStepIndex >= widget.steps.length - 1) {
        timer.cancel();
        setState(() => _isAutoSolving = false);
      } else {
        setState(() => _currentStepIndex++);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefersReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final steps = widget.steps;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Live Geometry Playground (Preview)',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: _Palette.primary)),
              const SizedBox(height: 16),
              Text(
                'Experiment with interactive constructions. This lightweight sandbox runs client-side with mocked solver responses.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: _Palette.neutralDark.withOpacity(0.85)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 900, // Fixed height for the interactive demo
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 1000;
                    final canvas = Expanded(
                      flex: 5,
                      child: Container(
                        height: 420,
                        decoration: BoxDecoration(
                          color: _Palette.neutralLight,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: _Palette.primary.withOpacity(0.08)),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _GeoPlaygroundPainter(
                                    stepIndex: _currentStepIndex),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Wrap(
                                spacing: 12,
                                children: [
                                  _PlaygroundChip(
                                      label: 'Add point',
                                      icon: Icons.add_location_alt_outlined,
                                      onPressed: () {}),
                                  _PlaygroundChip(
                                      label: 'Add line',
                                      icon: Icons.timeline_outlined,
                                      onPressed: () {}),
                                  _PlaygroundChip(
                                    label: _isAutoSolving
                                        ? 'Solving…'
                                        : 'Auto-solve',
                                    icon: Icons.auto_fix_high_outlined,
                                    onPressed:
                                        _isAutoSolving ? null : _startAutoSolve,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final panel = Expanded(
                      flex: 4,
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: isSmall ? 0 : 32, top: isSmall ? 24 : 0),
                        child: Container(
                          height: 420,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: _Palette.primary.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 18)),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_stories_outlined,
                                      color: _Palette.secondary),
                                  const SizedBox(width: 12),
                                  Text('Symbolic reasoning',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Copy JSON payload',
                                    onPressed: () {},
                                    icon: const Icon(Icons.copy_outlined),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: prefersReducedMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 500),
                                  child: ListView.builder(
                                    key: ValueKey(_currentStepIndex),
                                    itemCount: steps.length,
                                    itemBuilder: (context, index) {
                                      final step = steps[index];
                                      final isActive =
                                          index <= _currentStepIndex;
                                      return AnimatedDefaultTextStyle(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: isActive
                                                  ? _Palette.primary
                                                  : _Palette.neutralDark
                                                      .withOpacity(0.5),
                                              fontWeight: isActive
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  '${index + 1}. ${step.title}'),
                                              const SizedBox(height: 6),
                                              Math.tex(step.latex,
                                                  textStyle: const TextStyle(
                                                      fontSize: 14)),
                                              if (isActive) ...[
                                                const SizedBox(height: 4),
                                                Text(step.explanation,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    if (isSmall) {
                      // Remove Expanded wrappers for Column layout
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 420, child: canvas.child),
                          SizedBox(height: 420, child: panel.child),
                        ],
                      );
                    }
                    return Row(children: [canvas, panel]);
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text('Sample geometry payload (mocked)',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _CodeSnippet(snippet: exampleGeometryPayload, height: 160),
            ],
          ),
        ),
      ),
    );
  }
}

class _UseCasesSection extends StatelessWidget {
  const _UseCasesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Palette.neutralLight,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Applications Across The Journey',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: _Palette.primary)),
              const SizedBox(height: 12),
              Text(
                'From today\'s geometry to tomorrow\'s autonomous systems',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _Palette.neutralDark.withOpacity(0.75)),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: useCases
                    .map((useCase) => _IconBullet(
                        title: useCase.title,
                        description: useCase.description,
                        icon: useCase.icon))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voices from early partners',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: _Palette.primary)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: testimonials
                    .map((testimonial) =>
                        _TestimonialCard(testimonial: testimonial))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Palette.neutralLight,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Our Approach: Incremental Domain Mastery',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: _Palette.primary)),
              const SizedBox(height: 12),
              Text(
                'Start with geometry, prove the framework, expand systematically',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _Palette.neutralDark.withOpacity(0.75)),
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 24,
                runSpacing: 24,
                children: processSteps
                    .map((step) => _ProcessStepCard(step: step))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Team & advisors',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: _Palette.primary)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: teamMembers
                    .map((member) => _TeamCard(member: member))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaSection extends StatefulWidget {
  const _CtaSection({super.key});

  @override
  State<_CtaSection> createState() => _CtaSectionState();
}

class _CtaSectionState extends State<_CtaSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _orgController = TextEditingController();
  String _useCase = useCaseOptions.first;
  bool _submitting = false;
  String? _feedback;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _feedback = null;
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    final success = math.Random().nextBool();

    setState(() {
      _submitting = false;
      _feedback = success
          ? 'Thank you! We will reach out shortly.'
          : 'Something went wrong. Please try again later.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_Palette.primary, _Palette.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join us on the journey from Olympiad geometry to autonomous intelligence.',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tell us which phase interests you—whether it\'s today\'s geometry solver, tomorrow\'s physics engine, or our long-term robotics vision.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.white70, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TextField(
                              controller: _nameController,
                              label: 'Full name',
                              validator: _requiredValidator),
                          const SizedBox(height: 16),
                          _TextField(
                            controller: _emailController,
                            label: 'Work email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _TextField(
                              controller: _orgController,
                              label: 'Organization',
                              validator: _requiredValidator),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _useCase,
                            decoration: const InputDecoration(
                                labelText: 'Main use case'),
                            items: useCaseOptions
                                .map((option) => DropdownMenuItem(
                                    value: option, child: Text(option)))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _useCase = value ?? _useCase),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text('Request early access'),
                          ),
                          if (_feedback != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _feedback!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: _feedback!.startsWith('Thank')
                                        ? _Palette.secondary
                                        : Colors.redAccent,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Palette.primary,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _LogoMark(darkBackground: true),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: footerLinks.entries
                          .map(
                            (entry) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.key,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                ...entry.value.map((link) => Text(link,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.white70))),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Icon(Icons.linked_camera_outlined, color: Colors.white70),
                      SizedBox(height: 8),
                      Icon(Icons.code_outlined, color: Colors.white70),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              Text(
                  '© ${DateTime.now().year} Akshara Intelligence. All rights reserved.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

InputBorder _inputBorder() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: _Palette.primary.withOpacity(0.15)),
    );

String? _requiredValidator(String? value) =>
    (value == null || value.isEmpty) ? 'Required' : null;

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: _inputBorder(),
        focusedBorder: _inputBorder().copyWith(
          borderSide: const BorderSide(color: _Palette.secondary, width: 1.5),
        ),
      ),
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  const _CodeSnippet({required this.snippet, this.height});

  final String snippet;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.primary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Text(
          snippet,
          style: GoogleFonts.ibmPlexMono(
              textStyle: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ),
    );
  }
}

class _PlaygroundChip extends StatelessWidget {
  const _PlaygroundChip(
      {required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        backgroundColor: Colors.white,
        foregroundColor: _Palette.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _IconBullet extends StatelessWidget {
  const _IconBullet(
      {required this.title, required this.description, required this.icon});

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _Palette.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600, color: _Palette.primary)),
                const SizedBox(height: 4),
                Text(description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _Palette.neutralDark.withOpacity(0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial});

  final _Testimonial testimonial;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote,
                  size: 32, color: _Palette.secondary),
              const SizedBox(height: 12),
              Text('"${testimonial.quote}"',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.5)),
              const SizedBox(height: 16),
              Text(testimonial.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(testimonial.role,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: _Palette.neutralDark.withOpacity(0.7))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessStepCard extends StatelessWidget {
  const _ProcessStepCard({required this.step});

  final _ProcessStep step;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _Palette.secondary.withOpacity(0.15),
            child: Icon(step.icon, color: _Palette.secondary),
          ),
          const SizedBox(height: 16),
          Text(step.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: _Palette.primary)),
          const SizedBox(height: 8),
          Text(step.description,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: _Palette.neutralDark.withOpacity(0.85))),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.member});

  final _TeamMember member;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: _Palette.secondary.withOpacity(0.2),
                child: Text(member.initials,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _Palette.secondary)),
              ),
              const SizedBox(height: 16),
              Text(member.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: _Palette.primary)),
              const SizedBox(height: 4),
              Text(member.role,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: _Palette.neutralDark.withOpacity(0.7))),
              const SizedBox(height: 12),
              Text(member.bio,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.5),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({this.darkBackground = false});

  final bool darkBackground;

  @override
  Widget build(BuildContext context) {
    final color = darkBackground ? Colors.white : _Palette.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                LinearGradient(colors: [_Palette.accent, _Palette.secondary]),
          ),
          child: Icon(Icons.auto_graph, color: color, size: 26),
        ),
        const SizedBox(width: 12),
        Text('Akshara Intelligence',
            style: GoogleFonts.poppins(
                textStyle: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _AnimatedHeroMesh extends StatefulWidget {
  const _AnimatedHeroMesh();

  @override
  State<_AnimatedHeroMesh> createState() => _AnimatedHeroMeshState();
}

class _AnimatedHeroMeshState extends State<_AnimatedHeroMesh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _HeroMeshPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _HeroMeshPainter extends CustomPainter {
  const _HeroMeshPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.08), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: size.center(Offset.zero), radius: size.shortestSide / 2));

    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke;

    final step = size.width / 6;
    final offset = (progress * step);

    for (double i = -step; i <= size.width + step; i += step) {
      final dx = ((i + offset) % (size.width + step)) - step;
      final pathVertical = Path()
        ..moveTo(dx, 0)
        ..cubicTo(dx + step * 0.2, size.height * 0.25, dx - step * 0.2,
            size.height * 0.75, dx, size.height);
      canvas.drawPath(pathVertical, gridPaint);
    }

    for (double j = -step; j <= size.height + step; j += step) {
      final dy = ((j + offset) % (size.height + step)) - step;
      final pathHorizontal = Path()
        ..moveTo(0, dy)
        ..cubicTo(size.width * 0.25, dy + step * 0.2, size.width * 0.75,
            dy - step * 0.2, size.width, dy);
      canvas.drawPath(
          pathHorizontal, gridPaint..color = Colors.white.withOpacity(0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _HeroMeshPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Palette constants for front page.
class _Palette {
  static const Color primary = AppPalette.primary;
  static const Color secondary = AppPalette.secondary;
  static const Color accent = AppPalette.accent;
  static const Color neutralLight = AppPalette.neutralLight;
  static const Color neutralDark = AppPalette.neutralDark;
}

/// Sample geometry steps used across hero + demo sections.
class _GeometryStep {
  const _GeometryStep(
      {required this.title, required this.latex, required this.explanation});

  final String title;
  final String latex;
  final String explanation;
}

const List<_GeometryStep> sampleGeometrySteps = [
  _GeometryStep(
    title: 'Define triangle',
    latex: r"A, B, C",
    explanation: 'Points A, B and C establish the base triangle.',
  ),
  _GeometryStep(
    title: 'Bisectors',
    latex: r"\text{PerpBis}(AB),\ \text{PerpBis}(BC)",
    explanation: 'Construct perpendicular bisectors for segments AB and BC.',
  ),
  _GeometryStep(
    title: 'Circumcenter',
    latex: r"O = \text{PerpBis}(AB) \cap \text{PerpBis}(BC)",
    explanation: 'Intersection of bisectors yields circumcenter O.',
  ),
];

/// Sample JSON payload displayed under demo section.
const String exampleGeometryPayload = '''{
  "primitives": {
    "points": ["A", "B", "C"],
    "segments": [["A","B"], ["B","C"], ["C","A"]]
  },
  "actions": [
    {"op": "construct", "entity": "PerpBis", "args": ["A","B"]},
    {"op": "construct", "entity": "PerpBis", "args": ["B","C"]},
    {"op": "solve", "entity": "Intersection", "args": ["PerpBis(AB)", "PerpBis(BC)"], "label": "O"}
  ],
  "symbolicTrace": [
    {"title": "Define triangle", "latex": "A,B,C", "explanation": "Points A, B, C defined."},
    {"title": "Bisectors", "latex": "\\text{PerpBis}(AB), \\text{PerpBis}(BC)", "explanation": "Construct perpendicular bisectors."},
    {"title": "Circumcenter", "latex": "O", "explanation": "Intersection of bisectors is circumcenter O."}
  ]
}''';

class _ValueProp {
  const _ValueProp(
      {required this.title, required this.description, required this.icon});

  final String title;
  final String description;
  final IconData icon;
}

const List<_ValueProp> valuePropositions = [
  _ValueProp(
    title: 'Unified Algebraic Core',
    description:
        'One mathematical engine that works across geometry, physics, and beyond. Build once, scale infinitely.',
    icon: Icons.hub_outlined,
  ),
  _ValueProp(
    title: 'IMO to Physics to Robotics',
    description:
        'Master Olympiad-level geometry today. Physics simulation tomorrow. Autonomous systems soon.',
    icon: Icons.timeline_outlined,
  ),
  _ValueProp(
    title: 'AI-Augmented, Not AI-Dependent',
    description:
        'LLM integration for natural language, but all reasoning grounded in symbolic proof—no hallucinations.',
    icon: Icons.verified_outlined,
  ),
  _ValueProp(
    title: 'Built for the Long Game',
    description:
        'From competitive math to robotics control. We\'re building the foundation that scales to real-world intelligence.',
    icon: Icons.rocket_launch_outlined,
  ),
];

class _FeatureShowcaseItem {
  const _FeatureShowcaseItem(
      {required this.title,
      required this.description,
      required this.visualBuilder,
      this.codeSnippet});

  final String title;
  final String description;
  final WidgetBuilder visualBuilder;
  final String? codeSnippet;
}

final List<_FeatureShowcaseItem> featureShowcaseItems = [
  _FeatureShowcaseItem(
    title: 'Interactive Constructions',
    description:
        'Construct perpendiculars, bisectors and more. Visual updates are mirrored in symbolic form in real-time.',
    visualBuilder: (context) => const _FeatureIllustration(
        icon: Icons.architecture,
        label: 'Geometry construction GIF placeholder'),
  ),
  _FeatureShowcaseItem(
    title: 'Automated Proofs & Steps',
    description:
        'Collapse panels with compact, human-readable proofs. Toggle between intuition and formal verification.',
    visualBuilder: (context) => const _FeatureIllustration(
        icon: Icons.description_outlined,
        label: 'Symbolic steps animation placeholder'),
  ),
  _FeatureShowcaseItem(
    title: 'API & SDK',
    description:
        'Integrate with your stack using REST or SDK. Request solutions, receive symbolic traces, integrate with classroom tools.',
    codeSnippet: '''POST /api/solve
Content-Type: application/json

{
  "problem": "circumcenter",
  "points": ["A","B","C"],
  "constraints": ["AB = AC"]
}''',
    visualBuilder: (context) => const _FeatureIllustration(
        icon: Icons.cloud_sync_outlined, label: 'API diagram placeholder'),
  ),
  _FeatureShowcaseItem(
    title: 'Deploy Anywhere',
    description:
        'Ship on Akshara Cloud, private VPC, or fully on-prem. SOC2-ready with granular data controls.',
    visualBuilder: (context) => const _FeatureIllustration(
        icon: Icons.cloud_done_outlined, label: 'Cloud / on-prem icons'),
  ),
];

class _FeatureIllustration extends StatelessWidget {
  const _FeatureIllustration({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 16)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _Palette.secondary),
            const SizedBox(height: 12),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: _Palette.neutralDark.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

class _UseCase {
  const _UseCase(
      {required this.title, required this.description, required this.icon});

  final String title;
  final String description;
  final IconData icon;
}

const List<_UseCase> useCases = [
  _UseCase(
      title: 'Today: Olympiad Training',
      description:
          'IMO, USAMO, and competitive geometry problems with verified proofs.',
      icon: Icons.emoji_events_outlined),
  _UseCase(
      title: 'Today: Advanced Math Education',
      description:
          'Interactive geometry for universities and self-paced learners.',
      icon: Icons.school_outlined),
  _UseCase(
      title: 'Next: Physics & EM Simulation',
      description:
          'Mechanics, electromagnetics, and physical systems with symbolic certainty.',
      icon: Icons.science_outlined),
  _UseCase(
      title: 'Next: AI-Integrated Reasoning',
      description:
          'Natural language understanding backed by verifiable computation.',
      icon: Icons.psychology_outlined),
  _UseCase(
      title: 'Future: Robotics R&D',
      description:
          'Motion planning and control with provable constraints.',
      icon: Icons.precision_manufacturing_outlined),
  _UseCase(
      title: 'Future: Autonomous Systems',
      description: 'Real-time verified computation for industrial automation.',
      icon: Icons.smart_toy_outlined),
];

class _Testimonial {
  const _Testimonial(
      {required this.quote, required this.name, required this.role});

  final String quote;
  final String name;
  final String role;
}

const List<_Testimonial> testimonials = [
  _Testimonial(
    quote:
        'Akshara bridges the gap between interactive geometry and formal algebra like nothing else we have tried.',
    name: 'Dr. Meera Singh',
    role: 'Dean of Mathematics, NIS Bengaluru',
  ),
  _Testimonial(
    quote:
        'The symbolic trace lets our instructors verify every construction our students attempt.',
    name: 'Jonathan Wright',
    role: 'Head of Product, Euclid Labs',
  ),
  _Testimonial(
    quote:
        'Finally, a solver we can embed with confidence in our STEM curriculum.',
    name: 'Larissa Chu',
    role: 'Director of Learning Science, ThinkEd',
  ),
];

class _ProcessStep {
  const _ProcessStep(
      {required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;
}

const List<_ProcessStep> processSteps = [
  _ProcessStep(
      icon: Icons.functions_outlined,
      title: '1. Prove Geometry (Now)',
      description:
          'Solve IMO and Olympiad problems with verifiable, symbolic proofs.'),
  _ProcessStep(
      icon: Icons.waves_outlined,
      title: '2. Simulate Physics (Next)',
      description:
          'Extend to mechanics and electromagnetics using the same algebraic core.'),
  _ProcessStep(
      icon: Icons.psychology_outlined,
      title: '3. Integrate AI (Soon)',
      description:
          'Combine LLM natural language with symbolic certainty—no hallucinations.'),
  _ProcessStep(
      icon: Icons.precision_manufacturing_outlined,
      title: '4. Power Robotics (Vision)',
      description: 'Real-time autonomous systems with provable constraints.'),
];

class _TeamMember {
  const _TeamMember(
      {required this.name, required this.role, required this.bio});

  String get initials => name
      .trim()
      .split(RegExp(r"\s+"))
      .map((part) => part.isEmpty ? '' : part[0])
      .take(2)
      .join();

  final String name;
  final String role;
  final String bio;
}

const List<_TeamMember> teamMembers = [
  _TeamMember(
      name: 'Ananya Rao',
      role: 'Founder & CEO',
      bio: 'Built computational geometry platforms for global classrooms.'),
  _TeamMember(
      name: 'Dr. Kiran Deshpande',
      role: 'Chief Scientist',
      bio: '20+ years in symbolic algebra and theorem provers.'),
  _TeamMember(
      name: 'Priya Chandrasekhar',
      role: 'Head of Engineering',
      bio: 'Previously led visual computing at top EdTech unicorn.'),
  _TeamMember(
      name: 'Prof. Luis Alvarez',
      role: 'Academic Advisor',
      bio: 'Geometry educator & author of “Proofs for Intuitionists”.'),
];

const Map<String, List<String>> footerLinks = {
  'Product': ['Live Demo', 'Geometry Playground', 'Symbolic Core'],
  'Resources': ['Docs', 'API Reference', 'Pricing'],
  'Company': ['About', 'Careers', 'Contact'],
  'Legal': ['Privacy', 'Terms', 'Security'],
};

const List<String> useCaseOptions = [
  'IMO/Olympiad Geometry (Available Now)',
  'Advanced Math Education (Available Now)',
  'Physics Simulation (Early Access)',
  'AI-Integrated Reasoning (Coming Soon)',
  'Robotics Applications (Long-term Partnership)',
  'Research Collaboration (All Phases)',
  'Other',
];

class _GeometryScenePainter extends CustomPainter {
  _GeometryScenePainter({required this.animationValue});

  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = _Palette.secondary;

    final offset1 = Offset(size.width * 0.25,
        size.height * (0.65 - 0.05 * math.sin(animationValue * math.pi)));
    final offset2 = Offset(size.width * 0.7,
        size.height * (0.7 + 0.04 * math.sin(animationValue * math.pi)));
    final offset3 = Offset(size.width * 0.55,
        size.height * (0.3 + 0.03 * math.cos(animationValue * math.pi)));

    final trianglePath = Path()
      ..moveTo(offset1.dx, offset1.dy)
      ..lineTo(offset2.dx, offset2.dy)
      ..lineTo(offset3.dx, offset3.dy)
      ..close();

    canvas.drawPath(trianglePath, paint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _Palette.secondary.withOpacity(0.1);
    canvas.drawPath(trianglePath, fillPaint);

    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _Palette.accent;
    for (final point in [offset1, offset2, offset3]) {
      canvas.drawCircle(point, 6, pointPaint);
    }

    final bisectorPaint = Paint()
      ..color = _Palette.primary.withOpacity(0.4)
      ..strokeWidth = 1.6;

    final midpoint1 =
        Offset((offset1.dx + offset2.dx) / 2, (offset1.dy + offset2.dy) / 2);
    final midpoint2 =
        Offset((offset2.dx + offset3.dx) / 2, (offset2.dy + offset3.dy) / 2);

    canvas.drawLine(midpoint1.translate(-80, -120),
        midpoint1.translate(80, 120), bisectorPaint);
    canvas.drawLine(midpoint2.translate(-120, 40),
        midpoint2.translate(120, -40), bisectorPaint);

    final circumcenter = _lineIntersection(
        midpoint1.translate(-80, -120),
        midpoint1.translate(80, 120),
        midpoint2.translate(-120, 40),
        midpoint2.translate(120, -40));
    if (circumcenter != null) {
      final radius = (circumcenter - offset1).distance;
      paint
        ..color = _Palette.secondary.withOpacity(0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      paint.strokeWidth = 1.8;
      canvas.drawCircle(circumcenter, radius, paint);
      canvas.drawCircle(circumcenter, 7, pointPaint..color = _Palette.primary);
    }
  }

  @override
  bool shouldRepaint(covariant _GeometryScenePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

Offset? _lineIntersection(Offset a1, Offset a2, Offset b1, Offset b2) {
  final denominator =
      (a1.dx - a2.dx) * (b1.dy - b2.dy) - (a1.dy - a2.dy) * (b1.dx - b2.dx);
  if (denominator.abs() < 0.01) {
    return null;
  }
  final x = ((a1.dx * a2.dy - a1.dy * a2.dx) * (b1.dx - b2.dx) -
          (a1.dx - a2.dx) * (b1.dx * b2.dy - b1.dy * b2.dx)) /
      denominator;
  final y = ((a1.dx * a2.dy - a1.dy * a2.dx) * (b1.dy - b2.dy) -
          (a1.dy - a2.dy) * (b1.dx * b2.dy - b1.dy * b2.dx)) /
      denominator;
  return Offset(x, y);
}

class _GeoPlaygroundPainter extends CustomPainter {
  const _GeoPlaygroundPainter({required this.stepIndex});

  final int stepIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _Palette.primary.withOpacity(0.06)
      ..strokeWidth = 1;
    const gridSize = 30.0;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(size.width * 0.25, size.height * 0.7),
      Offset(size.width * 0.75, size.height * 0.7),
      Offset(size.width * 0.45, size.height * 0.28),
    ];

    final stroke = Paint()
      ..color = _Palette.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = _Palette.secondary.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    final pointPaint = Paint()..color = _Palette.accent;
    for (final point in points) {
      canvas.drawCircle(point, 6, pointPaint);
    }

    if (stepIndex >= 1) {
      final midpoint1 = Offset(
          (points[0].dx + points[1].dx) / 2, (points[0].dy + points[1].dy) / 2);
      final midpoint2 = Offset(
          (points[1].dx + points[2].dx) / 2, (points[1].dy + points[2].dy) / 2);
      final bisectorPaint = Paint()
        ..color = _Palette.primary.withOpacity(0.5)
        ..strokeWidth = 1.5;
      canvas.drawLine(midpoint1.translate(-100, -120),
          midpoint1.translate(100, 120), bisectorPaint);
      if (stepIndex >= 2) {
        canvas.drawLine(midpoint2.translate(-140, 60),
            midpoint2.translate(140, -60), bisectorPaint);
        final center = _lineIntersection(
            midpoint1.translate(-100, -120),
            midpoint1.translate(100, 120),
            midpoint2.translate(-140, 60),
            midpoint2.translate(140, -60));
        if (center != null) {
          final radius = (center - points.first).distance;
          canvas.drawCircle(center, radius,
              bisectorPaint..color = _Palette.secondary.withOpacity(0.3));
          canvas.drawCircle(center, 8, pointPaint..color = _Palette.primary);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GeoPlaygroundPainter oldDelegate) =>
      oldDelegate.stepIndex != stepIndex;
}
