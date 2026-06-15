import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/programas.dart';
import '../constants/dia_semana.dart';
import '../models/departamento.dart';
import '../models/voluntario_departamento_horario.dart';
import '../providers/auth_provider.dart';
import '../utils/hora_formatter.dart';
import '../utils/hora_validator.dart';
import '../utils/form_enter_focus.dart';
import '../utils/snackbar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_form_text_field.dart';
import '../widgets/record_action_buttons.dart';

/// Vínculos voluntário ↔ departamento (dia da semana e horário).
class VoluntarioDepartamentoHorariosEditor extends ConsumerStatefulWidget {
  const VoluntarioDepartamentoHorariosEditor({
    super.key,
    required this.voluntarioId,
  });

  final String voluntarioId;

  @override
  ConsumerState<VoluntarioDepartamentoHorariosEditor> createState() =>
      _VoluntarioDepartamentoHorariosEditorState();
}

class _VoluntarioDepartamentoHorariosEditorState
    extends ConsumerState<VoluntarioDepartamentoHorariosEditor> {
  List<VoluntarioDepartamentoHorario>? _horarios;
  List<Departamento> _departamentos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.listVoluntarioDepartamentoHorarios(widget.voluntarioId),
        api.listDepartamentos(ativo: true),
      ]);
      if (!mounted) return;
      setState(() {
        _horarios = List<VoluntarioDepartamentoHorario>.from(results[0] as List);
        _departamentos = List<Departamento>.from(results[1] as List)
          ..sort((a, b) => a.descricao.compareTo(b.descricao));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _openDialog([VoluntarioDepartamentoHorario? horario]) async {
    final auth = ref.read(authProvider);
    final isEdit = horario != null;
    if (!isEdit && !auth.podeIncluir(Programas.voluntarios)) return;
    if (isEdit && !auth.podeAlterar(Programas.voluntarios)) return;

    if (_departamentos.isEmpty) {
      showErrorSnackBar(
        context,
        'Cadastre ao menos um departamento ativo antes de vincular.',
      );
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _HorarioDialog(
        departamentos: _departamentos,
        horario: horario,
        voluntarioId: widget.voluntarioId,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _excluir(VoluntarioDepartamentoHorario horario) async {
    if (!ref.read(authProvider).podeExcluir(Programas.voluntarios)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir vínculo?'),
        content: Text(
          '${horario.departamentoDescricao ?? horario.departamentoCodigo} · '
          '${horario.diaSemanaRotulo ?? horario.diaSemana}\n'
          '${horario.horaInicio} — ${horario.horaTermino}',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(apiClientProvider)
          .deleteVoluntarioDepartamentoHorario(horario.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Vínculo excluído');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.voluntarios);
    final podeAlterar = auth.podeAlterar(Programas.voluntarios);
    final podeExcluir = auth.podeExcluir(Programas.voluntarios);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Departamentos e horários',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (podeIncluir)
              TextButton.icon(
                onPressed: _loading ? null : () => _openDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'O mesmo voluntário pode ter vários horários no mesmo departamento.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_horarios == null || _horarios!.isEmpty)
          Text(
            'Nenhum vínculo cadastrado.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          ..._horarios!.map((h) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${h.departamentoCodigo} — ${h.departamentoDescricao ?? ''}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${h.diaSemanaRotulo ?? DiaSemana.rotulo(h.diaSemana)} · '
                      '${h.horaInicio} às ${h.horaTermino}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    RecordActionButtons(
                      onEdit: podeAlterar ? () => _openDialog(h) : null,
                      onDelete: podeExcluir ? () => _excluir(h) : null,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _HorarioDialog extends ConsumerStatefulWidget {
  const _HorarioDialog({
    required this.departamentos,
    required this.voluntarioId,
    this.horario,
  });

  final List<Departamento> departamentos;
  final String voluntarioId;
  final VoluntarioDepartamentoHorario? horario;

  @override
  ConsumerState<_HorarioDialog> createState() => _HorarioDialogState();
}

class _HorarioDialogState extends ConsumerState<_HorarioDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _departamentoCodigo;
  late String _diaSemana;
  late final TextEditingController _horaInicioController;
  late final TextEditingController _horaTerminoController;
  late final FormEnterFocus _enterFocus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.horario;
    _departamentoCodigo =
        h?.departamentoCodigo ?? widget.departamentos.first.codigo;
    _diaSemana = h?.diaSemana ?? DiaSemana.segundaFeira;
    _horaInicioController = TextEditingController(text: h?.horaInicio ?? '');
    _horaTerminoController = TextEditingController(text: h?.horaTermino ?? '');
    _enterFocus = FormEnterFocus.count(2);
  }

  @override
  void dispose() {
    _horaInicioController.dispose();
    _horaTerminoController.dispose();
    _enterFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      aplicarFormatoHoraAoSair(_horaInicioController);
      aplicarFormatoHoraAoSair(_horaTerminoController);

      final payload = VoluntarioDepartamentoHorario(
        id: widget.horario?.id ?? '',
        voluntarioId: widget.voluntarioId,
        departamentoCodigo: _departamentoCodigo,
        diaSemana: _diaSemana,
        horaInicio: formatHoraOnBlur(_horaInicioController.text),
        horaTermino: formatHoraOnBlur(_horaTerminoController.text),
      );

      if (widget.horario != null) {
        await api.updateVoluntarioDepartamentoHorario(payload);
      } else {
        await api.createVoluntarioDepartamentoHorario(
          widget.voluntarioId,
          payload,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.horario != null ? 'Editar vínculo' : 'Novo vínculo',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _departamentoCodigo,
                  decoration: const InputDecoration(labelText: 'Departamento'),
                  items: widget.departamentos
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.codigo,
                          child: Text('${d.codigo} — ${d.descricao}'),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _departamentoCodigo = v);
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _diaSemana,
                  decoration: const InputDecoration(labelText: 'Dia da semana'),
                  items: DiaSemana.opcoes.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _diaSemana = v);
                        },
                ),
                const SizedBox(height: 12),
                AppFormTextField(
                  enterFocus: _enterFocus,
                  enterIndex: 0,
                  controller: _horaInicioController,
                  decoration: const InputDecoration(
                    labelText: 'Hora início',
                    hintText: '0800 ou 08:00',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [HoraInputFormatter()],
                  validator: validateHoraObrigatoria,
                  onEnterAdvance: () {
                    aplicarFormatoHoraAoSair(_horaInicioController);
                    _formKey.currentState?.validate();
                    _enterFocus.onSubmitted(0);
                  },
                ),
                const SizedBox(height: 12),
                AppFormTextField(
                  enterFocus: _enterFocus,
                  enterIndex: 1,
                  controller: _horaTerminoController,
                  decoration: const InputDecoration(
                    labelText: 'Hora término',
                    hintText: '1200 ou 12:00',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [HoraInputFormatter()],
                  validator: (v) => validateHoraTerminoAposInicio(
                    v,
                    _horaInicioController.text,
                  ),
                  onEnterAdvance: () {
                    aplicarFormatoHoraAoSair(_horaTerminoController);
                    _formKey.currentState?.validate();
                    _enterFocus.onSubmitted(1);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        Focus(
          focusNode: _enterFocus.submitFocusNode,
          child: AppButton(
            label: 'Salvar',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ),
      ],
    );
  }
}
