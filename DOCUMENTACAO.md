# Cefa — Documentação do Projeto

Ponto de entrada da documentação. O conteúdo está **dividido por tema** na pasta [`docs/`](./docs/) para facilitar leitura humana e uso por assistentes de IA.

## Índice

| Documento | Conteúdo |
|-----------|----------|
| [docs/visao-arquitetura.md](./docs/visao-arquitetura.md) | Visão geral do produto, objetivos da v1, stack, escopo do repositório, diagrama e estrutura de pastas |
| [docs/modelo-dados.md](./docs/modelo-dados.md) | Auditoria, entidades, relacionamentos, regras de negócio do banco |
| [docs/api.md](./docs/api.md) | Referência da API REST (rotas, exemplos JSON, regras) |
| [docs/mobile.md](./docs/mobile.md) | App Flutter: navegação, telas, fluxos, permissões, identidade |
| [docs/relatorios.md](./docs/relatorios.md) | PDF: submissões em fluxo; **entrevista** com layout fixo (YAML + fundo); submissões fixas planejadas |
| [docs/setup.md](./docs/setup.md) | Pré-requisitos, Neon/Docker, execução da API e do app; **fora do escopo v1**; scripts úteis |
| [docs/historico.md](./docs/historico.md) | Histórico de evolução do projeto |
| [docs/troubleshooting.md](./docs/troubleshooting.md) | Solução de problemas (FAQ técnico) |

Documentação visual: [`IdentidadeGrafica.md`](./IdentidadeGrafica.md). Regras fixas do projeto: [`.cursor/rules/`](./.cursor/rules/).

---

## Como evoluir esta documentação

- Preferir **editar o arquivo temático** em `docs/` ao acrescentar detalhes longos; mantenha este índice atualizado se criar arquivo novo.
- O **README.md** na raiz continua com início rápido e visão compacta.
- Convenções estáveis (Arial, escopo do repo, sem cascade) ficam em **`.cursor/rules/`**.
- Registros históricos: §7 em [docs/historico.md](./docs/historico.md) — apenas marcos; evite duplicar texto das seções estáveis.

---

*Documentação alinhada ao estado do repositório em maio/2026. Destaques: entrevista **6 abas** e `gestantesFamilia[]`; perguntas **TEXTO** com `tamanhoCampo` (até 5000) e `linhasCampo` (1–20); `valor_texto` **TEXT** (`20260520110000`); **lançamento** sem respostas obrigatórias; PDF de submissões em fluxo (layout compacto, `TextOverflow.span`, numeração **Pág. N** no canto superior direito via `pdf_page_number.dart`); entrevista com PDF fixo + mesma numeração; fontes PDF Open Sans; Neon/`pgbouncer=true`. Ao alterar modelo: migration Prisma + [docs/modelo-dados.md](./docs/modelo-dados.md) e [docs/api.md](./docs/api.md). Ao alterar PDF: [docs/relatorios.md](./docs/relatorios.md) e arquivos em `mobile/lib/utils/` / `mobile/assets/relatorios/`.*
