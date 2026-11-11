import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../core/app_preferences.dart';
import '../models/recommendation_result.dart';
import '../providers/history_provider.dart';
import '../providers/recommendation_provider.dart';
import '../utils/agro_options.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/app_banner.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/selectable_card.dart';

/// Formulario guiado del terreno en 5 pasos.
class FarmFormScreen extends StatefulWidget {
  const FarmFormScreen({super.key, this.initialDepartment});

  final String? initialDepartment;

  @override
  State<FarmFormScreen> createState() => _FarmFormScreenState();
}

class _FarmFormScreenState extends State<FarmFormScreen> {
  static const _titles = ['Ubicación', 'Altitud', 'Tipo de suelo', 'Agua disponible', 'Confirmar'];
  static const _subtitles = [
    'Los promedios de clima y precios dependen del departamento.',
    'La altitud define qué cultivos se adaptan a la temperatura y al riesgo de heladas.',
    'Cada cultivo rinde mejor en ciertos suelos.',
    'Algunos cultivos necesitan más agua que otros.',
    'Revisa tus datos antes de obtener la recomendación.',
  ];

  final _altitudeController = TextEditingController();
  final _altitudeFormKey = GlobalKey<FormState>();
  int _step = 0;
  bool _forward = true;
  String? _department;
  String? _soil;
  String? _water;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<AppPreferences>();
    final initial = widget.initialDepartment ?? prefs.lastDepartment;
    if (initial != null && AgroOptions.departments.contains(initial)) _department = initial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecommendationProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _altitudeController.dispose();
    super.dispose();
  }

  double? get _altitude {
    final v = Validators.parseAltitude(_altitudeController.text);
    return Validators.altitude(_altitudeController.text) == null ? v : null;
  }

  bool get _canContinue => switch (_step) {
    0 => _department != null,
    1 => _altitude != null,
    2 => _soil != null,
    3 => _water != null,
    _ => true,
  };

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = step > _step;
      _step = step;
    });
  }

  void _next() {
    if (_step == 1 && !(_altitudeFormKey.currentState?.validate() ?? false)) return;
    if (!_canContinue) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Elige una opción para continuar.')));
      return;
    }
    if (_step < _titles.length - 1) {
      _goTo(_step + 1);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final input = FarmInput(
      department: _department!,
      altitude: _altitude!,
      soilType: _soil!,
      waterAvailability: _water!,
    );
    final provider = context.read<RecommendationProvider>();
    final history = context.read<HistoryProvider>();
    final prefs = context.read<AppPreferences>();
    final result = await provider.submit(input);
    if (!mounted || result == null) return;
    await prefs.setLastDepartment(input.department);
    unawaited(history.refresh());
    if (mounted) context.pushReplacement('/results');
  }

  Future<bool> _confirmExit() async {
    final untouched = _department == null && _soil == null && _water == null && _altitudeController.text.isEmpty;
    if (untouched) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir del formulario?'),
        content: const Text('Perderás los datos que ingresaste.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Seguir editando')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir')),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();
    final isLast = _step == _titles.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_step > 0) {
          _goTo(_step - 1);
          return;
        }
        if (await _confirmExit() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nueva recomendación'),
          leading: IconButton(
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              if (await _confirmExit() && context.mounted) context.pop();
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StepHeader(step: _step, total: _titles.length, title: _titles[_step], subtitle: _subtitles[_step]),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppDurations.normal,
                      switchInCurve: AppDurations.curve,
                      transitionBuilder: (child, animation) {
                        final dx = _forward ? 0.08 : -0.08;
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
                    ),
                  ),
                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                      child: AppBanner(
                        tone: BannerTone.error,
                        message: provider.errorMessage!,
                        onClose: provider.clearError,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                    child: Row(
                      children: [
                        if (_step > 0) ...[
                          Expanded(
                            child: AppButton(
                              label: 'Atrás',
                              variant: AppButtonVariant.secondary,
                              onPressed: provider.isLoading ? null : () => _goTo(_step - 1),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm + 4),
                        ],
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            label: isLast ? 'Obtener recomendación' : 'Continuar',
                            icon: isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                            isLoading: provider.isLoading,
                            onPressed: _canContinue ? _next : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
    0 => _OptionList(
      children: [
        for (final d in AgroOptions.departments)
          SelectableCard(
            dense: true,
            icon: Icons.place_outlined,
            title: d,
            selected: _department == d,
            onTap: () => setState(() => _department = d),
          ),
      ],
    ),
    1 => _AltitudeStep(formKey: _altitudeFormKey, controller: _altitudeController, onChanged: () => setState(() {})),
    2 => _OptionList(
      footer:
          'Si no conoces tu tipo de suelo, la agencia agraria o un análisis de suelo pueden ayudarte. '
          'Elige el que mejor describa tu parcela.',
      children: [
        for (final s in AgroOptions.soils)
          SelectableCard(
            icon: Icons.layers_outlined,
            title: s.name,
            subtitle: s.description,
            selected: _soil == s.name,
            onTap: () => setState(() => _soil = s.name),
          ),
      ],
    ),
    3 => _OptionList(
      children: [
        for (final w in AgroOptions.waterLevels)
          SelectableCard(
            icon: switch (w.level) {
              'Baja' => Icons.water_drop_outlined,
              'Media' => Icons.opacity_rounded,
              _ => Icons.water_rounded,
            },
            title: 'Disponibilidad ${w.level.toLowerCase()}',
            subtitle: w.description,
            selected: _water == w.level,
            onTap: () => setState(() => _water = w.level),
          ),
      ],
    ),
    _ => _SummaryStep(
      items: [
        (Icons.place_outlined, 'Departamento', _department ?? '—', 0),
        (
          Icons.terrain_rounded,
          'Altitud',
          _altitude == null
              ? '—'
              : '${Formatters.altitude(_altitude!)} (banda ${AgroOptions.bandFor(_altitude!).toLowerCase()})',
          1,
        ),
        (Icons.layers_outlined, 'Tipo de suelo', _soil ?? '—', 2),
        (Icons.water_drop_outlined, 'Disponibilidad de agua', _water ?? '—', 3),
      ],
      onEdit: _goTo,
    ),
  };
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.total, required this.title, required this.subtitle});

  final int step;
  final int total;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Paso ${step + 1} de $total',
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (step + 1) / total),
              duration: AppDurations.normal,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(value: value, minHeight: 6),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Paso ${step + 1} de $total', style: context.text.labelLarge?.copyWith(color: context.colors.primary)),
          const SizedBox(height: AppSpacing.xxs),
          Semantics(header: true, child: Text(title, style: context.text.headlineSmall)),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({required this.children, this.footer});

  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
    children: [
      for (final c in children) ...[c, const SizedBox(height: AppSpacing.sm)],
      if (footer != null)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: AppBanner(message: footer!),
        ),
    ],
  );
}

class _AltitudeStep extends StatelessWidget {
  const _AltitudeStep({required this.formKey, required this.controller, required this.onChanged});

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final parsed = Validators.parseAltitude(controller.text);
    final valid = parsed != null && Validators.altitude(controller.text) == null;
    final sliderValue = valid ? parsed : 3000.0;
    final band = valid ? AgroOptions.bandFor(parsed) : null;

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        children: [
          AppTextField(
            controller: controller,
            label: 'Altitud del terreno',
            hint: 'Ej. 3200',
            icon: Icons.terrain_rounded,
            suffixText: 'm s. n. m.',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
            validator: Validators.altitude,
            onChanged: (_) => onChanged(),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: sliderValue.clamp(AppConfig.minAltitude, AppConfig.maxAltitude),
            max: AppConfig.maxAltitude,
            divisions: 100,
            label: Formatters.altitude(sliderValue),
            semanticFormatterCallback: (v) => Formatters.altitude(v),
            onChanged: (v) {
              controller.text = v.round().toString();
              onChanged();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final b in AgroOptions.altitudeBands)
                Expanded(
                  child: AnimatedContainer(
                    duration: AppDurations.normal,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: band == b.name ? context.colors.primaryContainer : context.colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: band == b.name ? context.colors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Altitud ${b.name.toLowerCase()}',
                          style: context.text.labelLarge,
                          textAlign: TextAlign.center,
                        ),
                        Text(b.label, style: context.text.bodySmall, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppBanner(
            message:
                '¿No conoces la altitud? Puedes verla en una aplicación de mapas con GPS '
                'o consultarla en la agencia agraria de tu zona.',
          ),
        ],
      ),
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({required this.items, required this.onEdit});

  final List<(IconData, String, String, int)> items;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
    children: [
      Card(
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              ListTile(
                leading: Icon(items[i].$1, color: context.colors.primary),
                title: Text(items[i].$2, style: context.text.bodySmall),
                subtitle: Text(items[i].$3, style: context.text.titleMedium),
                trailing: TextButton(onPressed: () => onEdit(items[i].$4), child: const Text('Editar')),
              ),
              if (i < items.length - 1) const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const AppBanner(
        message:
            'La recomendación se basa en datos referenciales y se guardará en tu historial. '
            'No reemplaza la asesoría de un técnico agrario.',
      ),
    ],
  );
}
