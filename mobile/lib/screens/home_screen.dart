import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../constants/modulo_relatorios.dart';
import '../home/home_menu_registry.dart';
import '../models/modulo_sistema.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../utils/snackbar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_screen_chrome.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<ModuloMenuItem>? _modulos;
  int _moduloIndex = 0;
  int _submoduloIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _loading = true);
    try {
      final modulos = await ref.read(apiClientProvider).getMenuModulos();
      if (mounted) {
        setState(() {
          _modulos = modulos;
          if (_moduloIndex >= modulos.length) {
            _moduloIndex = 0;
          }
          _submoduloIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        final isAdmin = ref.read(authProvider).isAdmin;
        if (!isAdmin) {
          showErrorSnackBar(context, e.toString());
        } else {
          setState(() => _modulos = []);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_HomeSubmoduloOpcao> _submodulosDoModulo(ModuloMenuItem modulo) {
    if (modulo.codigo != moduloRelatoriosCodigo) return const [];

    final map = <String, _HomeSubmoduloOpcao>{};
    for (final programa in modulo.programas) {
      final id = programa.relatorioSubmoduloId;
      if (id == null || id.isEmpty) continue;
      map.putIfAbsent(
        id,
        () => _HomeSubmoduloOpcao(
          id: id,
          label: programa.relatorioSubmoduloNome ?? programa.relatorioSubmoduloCodigo ?? id,
          ordem: programa.relatorioSubmoduloOrdem ?? 0,
        ),
      );
    }

    final list = map.values.toList()
      ..sort((a, b) {
        final byOrdem = a.ordem.compareTo(b.ordem);
        if (byOrdem != 0) return byOrdem;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });
    return list;
  }

  List<_HomeProgramaItem> _programasMenu(
    ModuloMenuItem modulo, {
    String? submoduloIdFiltro,
  }) {
    final programasMenu = <_HomeProgramaItem>[];
    for (final programa in modulo.programas) {
      if (submoduloIdFiltro != null &&
          programa.relatorioSubmoduloId != submoduloIdFiltro) {
        continue;
      }
      final entry = HomeMenuRegistry.entryForCodigo(programa.codigo);
      if (entry != null) {
        programasMenu.add(
          _HomeProgramaItem(
            icon: entry.icon,
            label: entry.label,
            subtitle: entry.subtitle,
            screen: entry.screen,
          ),
        );
      }
    }
    programasMenu.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return programasMenu;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final modulos = _modulos ?? [];
    final moduloSelecionado = modulos.isNotEmpty
        ? modulos[_moduloIndex.clamp(0, modulos.length - 1)]
        : null;

    final submodulos = moduloSelecionado != null
        ? _submodulosDoModulo(moduloSelecionado)
        : <_HomeSubmoduloOpcao>[];
    if (_submoduloIndex > submodulos.length) {
      _submoduloIndex = 0;
    }

    final submoduloFiltro = submodulos.isEmpty || _submoduloIndex == 0
        ? null
        : submodulos[_submoduloIndex - 1].id;

    final programasMenu = moduloSelecionado != null
        ? _programasMenu(
            moduloSelecionado,
            submoduloIdFiltro: submoduloFiltro,
          )
        : <_HomeProgramaItem>[];

    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: 'Cefa',
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Atualizar menu',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadMenu,
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.accentOrange,
                onRefresh: _loadMenu,
                child: ListView(
                  padding: AppLayout.screenPadding,
                  children: [
                    Text(
                      'Olá, ${auth.usuario?.nome ?? ''}',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'API: ${ApiConfig.baseUrl}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (modulos.isEmpty)
                      Text(
                        'Nenhum programa liberado para seu usuário.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      )
                    else ...[
                      Text('Módulo', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: modulos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final modulo = modulos[index];
                            final selected = index == _moduloIndex;
                            return ChoiceChip(
                              label: Text(modulo.nome),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _moduloIndex = index;
                                  _submoduloIndex = 0;
                                });
                              },
                              selectedColor: AppColors.lightBlue,
                              labelStyle: theme.textTheme.labelLarge?.copyWith(
                                color: selected
                                    ? AppColors.primaryBlue
                                    : AppColors.neutralGray,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.primaryBlue
                                    : AppColors.mediumGray,
                              ),
                            );
                          },
                        ),
                      ),
                      if (moduloSelecionado?.descricao != null &&
                          moduloSelecionado!.descricao!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          moduloSelecionado.descricao!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.neutralGray,
                          ),
                        ),
                      ],
                      if (submodulos.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Submódulo', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: submodulos.length + 1,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final selected = index == _submoduloIndex;
                              final label = index == 0
                                  ? 'Todos'
                                  : submodulos[index - 1].label;
                              return ChoiceChip(
                                label: Text(label),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() => _submoduloIndex = index);
                                },
                                selectedColor: AppColors.lightBlue,
                                labelStyle:
                                    theme.textTheme.labelLarge?.copyWith(
                                  color: selected
                                      ? AppColors.primaryBlue
                                      : AppColors.neutralGray,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.primaryBlue
                                      : AppColors.mediumGray,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (programasMenu.isEmpty)
                        Text(
                          'Nenhum programa liberado neste módulo.',
                          style: theme.textTheme.bodyLarge,
                        )
                      else
                        ...programasMenu.map(
                          (item) => _HomeMenuCard(
                            icon: item.icon,
                            label: item.label,
                            subtitle: item.subtitle,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => item.screen),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _HomeSubmoduloOpcao {
  const _HomeSubmoduloOpcao({
    required this.id,
    required this.label,
    required this.ordem,
  });

  final String id;
  final String label;
  final int ordem;
}

class _HomeProgramaItem {
  const _HomeProgramaItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.screen,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Widget screen;
}

class _HomeMenuCard extends StatelessWidget {
  const _HomeMenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutralGray,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.primaryBlue),
        ],
      ),
    );
  }
}
