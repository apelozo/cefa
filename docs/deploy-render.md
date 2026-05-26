# Deploy da API no Render (Neon)

Guia para publicar o **backend** do Cefa no [Render](https://render.com), usando **PostgreSQL no Neon** (recomendado no projeto). O app **Flutter** continua rodando localmente ou em outro host; ele aponta para a URL da API via `API_BASE_URL`.

## Arquitetura

```text
[Flutter Web / Android / Chrome]
        │  HTTPS
        ▼
[Render — Web Service (pasta backend/)]
        │  DATABASE_URL
        ▼
[Neon — PostgreSQL com pooler (-pooler no host)]
```

Na subida, a API executa `prisma migrate deploy`, sincroniza módulos/programas e cria o usuário `admin` se ainda não existir (`ensureAdminUser` em `backend/src/lib/sync-bootstrap.ts`).

---

## Pré-requisitos

1. Repositório **Cefa** no GitHub (ou GitLab/Bitbucket conectado ao Render).
2. Projeto **Neon** com connection string do **pooler** (host contém `-pooler`).
3. Conta no Render.

Não commite `backend/.env` — apenas `.env.example`.

---

## 1. Connection string no Neon → `DATABASE_URL`

No painel Neon, copie a URL do **pooler**. Ajuste os parâmetros da query:

| Parâmetro | Ação |
|-----------|------|
| `sslmode=require` | Manter |
| `channel_binding=require` | **Remover** (não é usado pelo Cefa no Render) |
| `pgbouncer=true` | **Adicionar** (obrigatório com host `-pooler`; evita erro *cached plan* após migrations — ver [troubleshooting.md](./troubleshooting.md)) |

**Formato:**

```text
postgresql://USUARIO:SENHA@HOST-pooler.REGION.aws.neon.tech/neondb?sslmode=require&pgbouncer=true
```

Substitua `USUARIO`, `SENHA` e `HOST` pelos valores do Neon. Cole **uma linha**, sem aspas, em **Environment → `DATABASE_URL`** no Render.

---

## 2. Criar o Web Service no Render

1. **Dashboard** → **New +** → **Web Service**.
2. Conecte o repositório do Cefa.
3. Preencha:

| Campo | Valor |
|--------|--------|
| **Root Directory** | `backend` |
| **Runtime** | Node |
| **Build Command** | `npm install && npx prisma generate && npm run build` |
| **Start Command** | `npx prisma migrate deploy && npm start` |

A API escuta `0.0.0.0` e `process.env.PORT` (`backend/src/index.ts`) — compatível com o Render. **Não** defina `PORT` manualmente no painel.

**Plano free:** o serviço pode “dormir”; o primeiro acesso após inatividade demora mais (cold start).

---

## 3. Variáveis de ambiente

| Variável | Obrigatório | Descrição |
|----------|-------------|-----------|
| `DATABASE_URL` | Sim | URL Neon pooler com `pgbouncer=true` (§1) |
| `JWT_SECRET` | Sim | String longa e aleatória para assinar tokens JWT. **Não** use o default de desenvolvimento. Se mudar depois do deploy, todos precisam fazer login de novo. |
| `ADMIN_INITIAL_PASSWORD` | Sim | Senha do usuário **`admin`** na **primeira** criação no banco. Se `admin` já existir, alterar esta variável **não** troca a senha. |
| `PORT` | Não | O Render injeta automaticamente |

### Gerar `JWT_SECRET` (Windows CMD)

```cmd
powershell -Command "[Convert]::ToBase64String((1..64 | ForEach-Object { Get-Random -Maximum 256 }))"
```

Cole só o resultado no campo `JWT_SECRET` (sem prefixo `JWT_SECRET=`).

Alternativa com OpenSSL, se instalado:

```cmd
openssl rand -base64 48
```

### `ADMIN_INITIAL_PASSWORD`

- Usada só quando **não** existe usuário `nomeUsuario = admin`.
- Login após o primeiro deploy: usuário **`admin`**, senha = valor definido nesta variável.
- Em produção use senha forte (não use `admin123` do `.env.example` local).

---

## 4. Validar o deploy

**URL pública (produção):** `https://cefa-api.onrender.com`

1. Navegador ou cliente HTTP:

   ```http
   GET https://cefa-api.onrender.com/health
   ```

   Resposta esperada: `{"status":"ok"}`

2. Login:

   ```http
   POST https://cefa-api.onrender.com/auth/login
   Content-Type: application/json

   {"login":"admin","senha":"SUA_ADMIN_INITIAL_PASSWORD"}
   ```

Se o build falhar, confira os logs: `prisma generate` no build e `migrate deploy` no start.

---

## 5. App Flutter apontando para o Render

Defina a base da API na compilação/execução (`mobile/lib/config/api_config.dart`).

**Produção (API no Render):** `https://cefa-api.onrender.com` — use **https**, sem barra no final. O backend usa CORS com `origin: true` — aceita o app em Chrome, Android ou outro host.

```powershell
cd mobile
flutter pub get
```

**Chrome:**

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://cefa-api.onrender.com
```

**Android** (emulador ou celular físico):

```powershell
flutter run --dart-define=API_BASE_URL=https://cefa-api.onrender.com
```

**Build web:**

```powershell
flutter build web --dart-define=API_BASE_URL=https://cefa-api.onrender.com
```

**APK de teste:**

```powershell
flutter build apk --dart-define=API_BASE_URL=https://cefa-api.onrender.com
```

**API local (desenvolvimento):** Chrome `http://127.0.0.1:3000`; Android emulador `http://10.0.2.2:3000`; celular na mesma Wi‑Fi `http://SEU_IP:3000` — ver [setup.md](./setup.md) e [mobile.md](./mobile.md).

---

## 6. (Opcional) Flutter Web estático no Render

1. **New +** → **Static Site**.
2. **Root Directory:** `mobile`
3. **Build Command** (exemplo; exige Flutter no ambiente de build do Render ou CI externo):

   ```bash
   flutter pub get
   flutter build web --dart-define=API_BASE_URL=https://cefa-api.onrender.com
   ```

4. **Publish directory:** `build/web`

Na prática, muitos times rodam o Flutter localmente e publicam só a API no Render; o passo acima é opcional.

---

## 7. Segurança

- Nunca commite senhas, `JWT_SECRET` nem `DATABASE_URL` no Git.
- Se uma connection string ou senha vazar, **rotacione** a senha no Neon e atualize `DATABASE_URL` no Render.
- Troque `ADMIN_INITIAL_PASSWORD` antes do primeiro deploy em produção; guarde a senha em local seguro.

---

## 8. Problemas comuns

Ver também [troubleshooting.md](./troubleshooting.md) (seção Render).

| Sintoma | O que verificar |
|---------|------------------|
| Build falha | `npx prisma generate` no Build Command |
| 500 / erro de banco | `DATABASE_URL` com `pgbouncer=true`; migrations nos logs do `migrate deploy` |
| Login inválido após redeploy | `JWT_SECRET` mudou → relogar |
| Senha `admin` não bate | Usuário já existia → senha não vem de `ADMIN_INITIAL_PASSWORD`; alterar senha pelo fluxo de usuários ou no banco |
| App não conecta | `API_BASE_URL=https://cefa-api.onrender.com` (HTTPS, sem `/` no fim); cold start no plano free |

---

## Referências no repositório

- Variáveis locais: `backend/.env.example`
- Setup local: [setup.md](./setup.md)
- Bootstrap admin: `backend/src/lib/sync-bootstrap.ts`
