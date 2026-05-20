import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/uf_brasil.dart';
import '../../models/cidade.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/datetime_display.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';

class CidadeFormScreen extends ConsumerStatefulWidget {
  const CidadeFormScreen({super.key, this.cidade});

  final Cidade? cidade;

  bool get isEditing => cidade != null;

  @override
  ConsumerState<CidadeFormScreen> createState() => _CidadeFormScreenState();
}

class _CidadeFormScreenState extends ConsumerState<CidadeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final FormEnterFocus _enterFocus;
  late String _estado;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(1);
    _nomeController =
        TextEditingController(text: widget.cidade?.nomeMunicipio ?? '');
    _estado = widget.cidade?.estado ?? 'SP';
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.isEditing && widget.cidade!.id.isEmpty) {
        showErrorSnackBar(context, 'Registro inválido. Volte e tente novamente.');
        return;
      }

      final api = ref.read(apiClientProvider);

      if (widget.isEditing) {
        final cidade = Cidade(
          id: widget.cidade!.id,
          codigo: widget.cidade!.codigo,
          nomeMunicipio: _nomeController.text.trim(),
          estado: _estado,
          ativo: widget.cidade!.ativo,
          usuarioInclusaoId: widget.cidade?.usuarioInclusaoId,
          dataHoraInclusao: widget.cidade?.dataHoraInclusao,
          usuarioAlteracaoId: widget.cidade?.usuarioAlteracaoId,
          dataHoraAlteracao: widget.cidade?.dataHoraAlteracao,
          usuarioExclusaoId: widget.cidade?.usuarioExclusaoId,
          dataHoraExclusao: widget.cidade?.dataHoraExclusao,
          createdAt: widget.cidade?.createdAt,
        );
        await api.updateCidade(cidade);
      } else {
        final created = await api.createCidade(
          Cidade(
            id: '',
            codigo: 0,
            nomeMunicipio: _nomeController.text.trim(),
            estado: _estado,
            ativo: true,
          ),
        );
        if (mounted) {
          showSuccessSnackBar(context, 'Cidade criada');
          Navigator.pop(context, created);
        }
        return;
      }

      if (mounted) {
        showSuccessSnackBar(context, 'Cidade atualizada');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _auditLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cidade;

    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing ? 'Editar cidade' : 'Nova cidade',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppLayout.screenPadding,
          children: [
            if (widget.isEditing && c != null) ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Código',
                ),
                child: Text(
                  c.codigo.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                'O código será gerado automaticamente ao salvar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nomeController,
              focusNode: _enterFocus.fields[0],
              textInputAction: _enterFocus.inputAction(0),
              onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                  onEditingComplete: _enterFocus.editingComplete(0),
              decoration: const InputDecoration(
                labelText: 'Nome do município',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe o nome do município';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _estado,
              decoration: const InputDecoration(labelText: 'Estado (UF)'),
              items: UfBrasil.ufs
                  .map(
                    (uf) => DropdownMenuItem(value: uf, child: Text(uf)),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v != null) setState(() => _estado = v);
                    },
            ),
            const SizedBox(height: 24),
            if (widget.isEditing && c != null) ...[
              Text(
                'Auditoria',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _auditLine(
                'Inclusão',
                '${formatDateTimeBr(c.dataHoraInclusao)}'
                '${c.usuarioInclusaoId != null ? ' · usuário ${c.usuarioInclusaoId}' : ''}',
              ),
              _auditLine(
                'Última alteração',
                '${formatDateTimeBr(c.dataHoraAlteracao)}'
                '${c.usuarioAlteracaoId != null ? ' · usuário ${c.usuarioAlteracaoId}' : ''}',
              ),
              if (!c.ativo) ...[
                _auditLine(
                  'Desativação (soft delete)',
                  '${formatDateTimeBr(c.dataHoraExclusao)}'
                  '${c.usuarioExclusaoId != null ? ' · usuário ${c.usuarioExclusaoId}' : ''}',
                ),
              ],
              const SizedBox(height: 16),
            ],
            AppButton(
              focusNode: _enterFocus.submitFocusNode,
              label: widget.isEditing ? 'Salvar' : 'Criar',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
