import type { FastifyPluginAsync } from "fastify";
import { ZodError } from "zod";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import {
  createTipoUsuario,
  deleteTipoUsuario,
  getPermissoesTipoUsuario,
  getTipoUsuarioById,
  listTiposUsuario,
  mapTipoUsuario,
  setPermissoesTipoUsuario,
  updateTipoUsuario,
} from "../services/tipos-usuario.js";
import {
  createTipoUsuarioSchema,
  permissoesBodySchema,
  updateTipoUsuarioSchema,
} from "../validators/tipos-usuario.js";

export const tiposUsuarioRoutes: FastifyPluginAsync = async (app) => {
  app.get("/tipos-usuario", async (request, reply) => {
    const query = request.query as { ativo?: string };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    const items = await listTiposUsuario(ativo);
    return reply.send(items.map(mapTipoUsuario));
  });

  app.get("/tipos-usuario/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getTipoUsuarioById(id);
    if (!item) {
      return reply.status(404).send({ error: "Tipo de usuário não encontrado" });
    }
    return reply.send(mapTipoUsuario(item));
  });

  app.post("/tipos-usuario", async (request, reply) => {
    try {
      const body = createTipoUsuarioSchema.parse(request.body);
      const item = await createTipoUsuario(body, request.usuarioId!);
      return reply.status(201).send(mapTipoUsuario(item));
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

  app.put("/tipos-usuario/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateTipoUsuarioSchema.parse(request.body);
      const item = await updateTipoUsuario(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Tipo de usuário não encontrado" });
      }
      return reply.send(mapTipoUsuario(item));
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

  app.delete("/tipos-usuario/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await deleteTipoUsuario(id);
      if (!item) {
        return reply.status(404).send({ error: "Tipo de usuário não encontrado" });
      }
      return reply.send(mapTipoUsuario(item));
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.get("/tipos-usuario/:id/permissoes", async (request, reply) => {
    const { id } = request.params as { id: string };
    const data = await getPermissoesTipoUsuario(id);
    if (!data) {
      return reply.status(404).send({ error: "Tipo de usuário não encontrado" });
    }
    return reply.send({
      tipoUsuario: mapTipoUsuario(data.tipo),
      permissoes: data.permissoes,
    });
  });

  app.put("/tipos-usuario/:id/permissoes", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = permissoesBodySchema.parse(request.body);
      const data = await setPermissoesTipoUsuario(id, body, request.usuarioId!);
      if (!data) {
        return reply.status(404).send({ error: "Tipo de usuário não encontrado" });
      }
      return reply.send({
        tipoUsuario: mapTipoUsuario(data.tipo),
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
};
