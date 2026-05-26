# Configuração, scripts e escopo v1

## 6. Configuração e execução

### Pré-requisitos

- Node.js 20+
- Flutter 3.x
- PostgreSQL (Neon na nuvem **ou** Docker local)

Não é necessário Visual Studio se rodar apenas no **Chrome** ou **emulador Android** (sem build Windows desktop).

### Banco de dados

**Opção A — Neon (recomendado no projeto atual)**

Configure `backend/.env`:

```env
# Neon com pooler (-pooler. no host): inclua pgbouncer=true (evita erro após migrations)
DATABASE_URL="postgresql://usuario:senha@host-pooler/neondb?sslmode=require&pgbouncer=true"
PORT=3000
JWT_SECRET="altere-em-producao"
ADMIN_INITIAL_PASSWORD="admin123"
```

```bash
cd backend
npx prisma migrate deploy
```

Inclui, entre outras: `20260520110000_texto_linhas_e_valor_text` (`perguntas.linhas_campo`, `respostas.valor_texto` → `TEXT`); `20260521100000_tipos_formulario_acesso` (liberação por tipo de formulário); `20260525100000_escolaridades` (tabela `escolaridades`, FK na entrevista); `20260525110000_departamentos`; `20260525120000_voluntarios`; `20260525130000_voluntario_departamento_horarios`; `20260525140000_voluntario_nome`; `20260525150000_voluntario_estado_civil_separado` (enum `SEPARADO`); `20260525160000_cursos`; `20260525170000_alunos_capacitacao_profissional` (tabela principal + `aluno_capacitacao_renda_familiar`). Após `migrate deploy`, usuários não admin precisam marcar tipos em **Liberação de acesso** (aba **Tipos de formulário**) e liberar programas novos (`escolaridades`, `departamentos`, `cursos`, `voluntarios`, `alunos_capacitacao`) conforme necessário. Ver [modelo-dados.md](./modelo-dados.md).

**Opção B — Docker local**

```bash
cd backend
docker compose up -d
cp .env.example .env
npx prisma migrate deploy
```

### API

```bash
cd backend
npm install
npm run dev
```

Verifique: [http://localhost:3000/health](http://localhost:3000/health)

### App

```bash
cd mobile
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

### Produção (Render + Neon)

API publicada: **`https://cefa-api.onrender.com`**. Guia completo: **[deploy-render.md](./deploy-render.md)**.

Testar o app (Chrome ou Android):

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=https://cefa-api.onrender.com
```

Chrome explicitamente: acrescente `-d chrome` ao comando acima.

---

## 8. Fora do escopo (v1)

- Recuperação de senha / MFA / refresh token longo
- Exportação em massa (CSV, planilhas, ZIP de vários lançamentos)
- Relatório PDF com **layout fixo por pergunta** (molde fundo + mapa) — especificado em [relatorios.md](./relatorios.md); implementação futura
- Rotas nomeadas / deep links no Flutter (`go_router`)
- Questionários com versionamento
- Modo offline / sincronização
- App Windows desktop (não é foco; Flutter web/Android cobre o uso atual)

---

## 9. Scripts úteis

```bash
# Backend
cd backend
npm run dev              # API com hot reload
npm run db:migrate       # Nova migration em dev
npm run db:generate      # Regenerar Prisma Client
npx tsc --noEmit         # Checagem TypeScript

# Flutter
cd mobile
flutter analyze
flutter test
```

---
