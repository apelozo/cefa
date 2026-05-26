import { PerfilTipoUsuario } from "@prisma/client";
import type { FastifyPluginAsync, FastifyReply, FastifyRequest } from "fastify";
import fp from "fastify-plugin";
import {
  PROGRAMA_POR_ROTA,
  rotaPermissaoKey,
  type AcaoPermissao,
} from "../lib/programas.js";
import {
  buildPermissaoMap,
  loadUsuarioComTipo,
  podeAcao,
  podeAcaoHttp,
} from "../services/permissoes.js";

declare module "fastify" {
  interface FastifyRequest {
    usuarioId?: string;
    permissaoMap?: Awaited<ReturnType<typeof buildPermissaoMap>>;
    isAdmin?: boolean;
  }
  interface FastifyInstance {
    authenticate: (
      request: FastifyRequest,
      reply: FastifyReply,
    ) => Promise<void>;
    requirePermissao: (
      codigoPrograma: string,
      acao: AcaoPermissao,
    ) => (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}

const ROTAS_PUBLICAS = new Set(["GET /health", "POST /auth/login"]);

const authPlugin: FastifyPluginAsync = async (app) => {
  app.decorate(
    "authenticate",
    async (request: FastifyRequest, reply: FastifyReply) => {
      try {
        const payload = await request.jwtVerify<{ sub: string }>();
        const usuario = await loadUsuarioComTipo(payload.sub);
        if (!usuario || !usuario.ativo) {
          return reply.status(401).send({ error: "Não autenticado" });
        }
        request.usuarioId = payload.sub;
        request.isAdmin =
          usuario.tipoUsuario.perfil === PerfilTipoUsuario.ADMINISTRADOR;
        request.permissaoMap = await buildPermissaoMap(payload.sub);
      } catch {
        return reply.status(401).send({ error: "Não autenticado" });
      }
    },
  );

  app.decorate(
    "requirePermissao",
    (codigoPrograma: string, acao: AcaoPermissao) =>
      async (request: FastifyRequest, reply: FastifyReply) => {
        if (!request.usuarioId || !request.permissaoMap) {
          return reply.status(401).send({ error: "Não autenticado" });
        }
        if (!podeAcao(request.permissaoMap, codigoPrograma, acao)) {
          return reply.status(403).send({ error: "Sem permissão para esta ação" });
        }
      },
  );

  app.addHook("onRequest", async (request, reply) => {
    const path = request.url.split("?")[0] ?? request.url;
    const key = `${request.method.toUpperCase()} ${path}`;
    if (ROTAS_PUBLICAS.has(key)) return;

    await app.authenticate(request, reply);
    if (reply.sent) return;

    const permKey = rotaPermissaoKey(request.method, path);
    if (!permKey) return;

    if (request.isAdmin) return;

    const { programa, acao } = PROGRAMA_POR_ROTA[permKey]!;
    if (!request.permissaoMap) return;

    let allowed = podeAcaoHttp(request.permissaoMap, programa, acao);
    if (
      !allowed &&
      path.startsWith("/programas") &&
      acao === "consultar"
    ) {
      allowed =
        podeAcaoHttp(request.permissaoMap, "liberacao_usuario", "consultar") ||
        podeAcaoHttp(request.permissaoMap, "liberacao_tipo_usuario", "consultar") ||
        podeAcaoHttp(request.permissaoMap, "modulos_sistema", "consultar") ||
        podeAcaoHttp(request.permissaoMap, "modulos_sistema", "alterar") ||
        podeAcaoHttp(request.permissaoMap, "modulos_sistema", "incluir");
    }

    if (
      !allowed &&
      path.startsWith("/escolaridades") &&
      acao === "consultar"
    ) {
      allowed = podeAcaoHttp(
        request.permissaoMap,
        "entrevista_assistido",
        "consultar",
      );
    }

    if (!allowed) {
      return reply.status(403).send({ error: "Sem permissão para esta ação" });
    }
  });
};

export const authPluginRegistered = fp(authPlugin, { name: "cefa-auth" });
