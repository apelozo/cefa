import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { Prisma } from "@prisma/client";
import { ZodError } from "zod";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import {
  getTiposFormularioAcessoUsuario,
  setTiposFormularioAcessoUsuario,
} from "../services/tipos-formulario-acesso.js";
import { permissoesBodySchema } from "../validators/tipos-usuario.js";
import { tiposFormularioAcessoBodySchema } from "../validators/tipos-formulario-acesso.js";
import {
  createUsuario,
  deleteUsuario,
  getPermissoesUsuario,
  getUsuarioById,
  listUsuarios,
  mapUsuario,
  setPermissoesUsuario,
  updateUsuario,
} from "../services/usuarios.js";
import {
  createUsuarioSchema,
  updateUsuarioSchema,
} from "../validators/usuarios.js";

export const usuariosRoutes: FastifyPluginAsync = async (app) => {
  app.get("/usuarios", async (request, reply) => {
    const query = request.query as { ativo?: string };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    const items = await listUsuarios(ativo);
    return replyMappedList(reply, items, mapUsuario);
  });

  app.get("/usuarios/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getUsuarioById(id);
    if (!item) {
      return reply.status(404).send({ error: "Usuário não encontrado" });
    }
    return replyMapped(reply, item, mapUsuario);
  });

  app.post("/usuarios", async (request, reply) => {
    try {
      const body = createUsuarioSchema.parse(request.body);
      const item = await createUsuario(body, request.usuarioId!);
      return replyMapped(reply, item, mapUsuario, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof Prisma.PrismaClientKnownRequestError) {
        if (err.code === "P2002") {
          return reply.status(409).send({
            error: "Nome de usuário ou e-mail já cadastrado",
          });
        }
      }
      throw err;
    }
  });

  app.put("/usuarios/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateUsuarioSchema.parse(request.body);
      const item = await updateUsuario(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Usuário não encontrado" });
      }
      return replyMapped(reply, item, mapUsuario);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof Prisma.PrismaClientKnownRequestError) {
        if (err.code === "P2002") {
          return reply.status(409).send({
            error: "Nome de usuário ou e-mail já cadastrado",
          });
        }
      }
      throw err;
    }
  });

  app.delete("/usuarios/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await deleteUsuario(id);
      if (!item) {
        return reply.status(404).send({ error: "Usuário não encontrado" });
      }
      return reply.send(mapUsuario({ ...item, tipoUsuario: item.tipoUsuario }));
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.get("/usuarios/:id/permissoes", async (request, reply) => {
    const { id } = request.params as { id: string };
    const data = await getPermissoesUsuario(id);
    if (!data) {
      return reply.status(404).send({ error: "Usuário não encontrado" });
    }
    return reply.send({
      usuario: mapUsuario(data.usuario),
      permissoes: data.permissoes,
    });
  });

  app.put("/usuarios/:id/permissoes", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = permissoesBodySchema.parse(request.body);
      const data = await setPermissoesUsuario(id, body, request.usuarioId!);
      if (!data) {
        return reply.status(404).send({ error: "Usuário não encontrado" });
      }
      return reply.send({
        usuario: mapUsuario(data.usuario),
        permissoes: data.permissoes,
      });
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof Error && err.message.includes("permissão total")) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.get("/usuarios/:id/tipos-formulario-acesso", async (request, reply) => {
    const { id } = request.params as { id: string };
    const data = await getTiposFormularioAcessoUsuario(id);
    if (!data) {
      return reply.status(404).send({ error: "Usuário não encontrado" });
    }
    return reply.send(data);
  });

  app.put("/usuarios/:id/tipos-formulario-acesso", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = tiposFormularioAcessoBodySchema.parse(request.body);
      const data = await setTiposFormularioAcessoUsuario(
        id,
        body,
        request.usuarioId!,
      );
      if (!data) {
        return reply.status(404).send({ error: "Usuário não encontrado" });
      }
      return reply.send(data);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof Error && err.message.includes("acesso a todos")) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });
};
