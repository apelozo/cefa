import type { FastifyPluginAsync } from "fastify";
import { ZodError } from "zod";
import { verificarSenha } from "../lib/password.js";
import { prisma } from "../lib/prisma.js";
import {
  buildPermissaoMap,
  loadUsuarioComTipo,
  mapPermissaoFlags,
} from "../services/permissoes.js";
import { enrichUsuarioMap } from "../lib/auditoria.js";
import { mapUsuario } from "../services/usuarios.js";
import { loginSchema } from "../validators/usuarios.js";

export const authRoutes: FastifyPluginAsync = async (app) => {
  app.post("/auth/login", async (request, reply) => {
    try {
      const body = loginSchema.parse(request.body);
      const usuario = await prisma.usuario.findUnique({
        where: { nomeUsuario: body.nomeUsuario },
        include: { tipoUsuario: true },
      });

      if (!usuario || !usuario.ativo) {
        return reply.status(401).send({ error: "Usuário ou senha inválidos" });
      }

      const ok = await verificarSenha(body.senha, usuario.senhaHash);
      if (!ok) {
        return reply.status(401).send({ error: "Usuário ou senha inválidos" });
      }

      const token = await app.jwt.sign({ sub: usuario.id });
      const permissoes = await buildPermissaoMap(usuario.id);
      const usuariosAuditoria = await enrichUsuarioMap([usuario]);

      return reply.send({
        token,
        usuario: mapUsuario(usuario, usuariosAuditoria),
        permissoes: Object.fromEntries(
          Object.entries(permissoes).map(([codigo, flags]) => [
            codigo,
            mapPermissaoFlags(flags),
          ]),
        ),
      });
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      throw err;
    }
  });

  app.get("/auth/me", async (request, reply) => {
    if (!request.usuarioId) {
      return reply.status(401).send({ error: "Não autenticado" });
    }

    const usuario = await loadUsuarioComTipo(request.usuarioId);
    if (!usuario || !usuario.ativo) {
      return reply.status(401).send({ error: "Não autenticado" });
    }

    const permissoes =
      request.permissaoMap ?? (await buildPermissaoMap(usuario.id));
    const usuariosAuditoria = await enrichUsuarioMap([usuario]);

    return reply.send({
      usuario: mapUsuario(usuario, usuariosAuditoria),
      permissoes: Object.fromEntries(
        Object.entries(permissoes).map(([codigo, flags]) => [
          codigo,
          mapPermissaoFlags(flags),
        ]),
      ),
    });
  });
};
