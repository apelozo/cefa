import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { Prisma } from "@prisma/client";
import { ZodError } from "zod";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import {
  buildMenuModulos,
  createModuloSistema,
  deleteModuloSistema,
  getModuloSistemaById,
  listModulosSistema,
  mapModuloSistema,
  setModuloProgramas,
  updateModuloSistema,
} from "../services/modulos-sistema.js";
import {
  createModuloSistemaSchema,
  modulosProgramasBodySchema,
  updateModuloSistemaSchema,
} from "../validators/modulos-sistema.js";

export const modulosSistemaRoutes: FastifyPluginAsync = async (app) => {
  app.get("/modulos-sistema/menu", async (request, reply) => {
    const menu = await buildMenuModulos(
      request.permissaoMap ?? {},
      request.isAdmin === true,
    );
    return reply.send(menu);
  });

  app.get("/modulos-sistema", async (request, reply) => {
    const query = request.query as { ativo?: string };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    const items = await listModulosSistema(ativo);
    return replyMappedList(reply, items, mapModuloSistema);
  });

  app.get("/modulos-sistema/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getModuloSistemaById(id);
    if (!item) {
      return reply.status(404).send({ error: "Módulo não encontrado" });
    }
    return replyMapped(reply, item, mapModuloSistema);
  });

  app.post("/modulos-sistema", async (request, reply) => {
    try {
      const body = createModuloSistemaSchema.parse(request.body);
      const item = await createModuloSistema(body, request.usuarioId!);
      return replyMapped(reply, item, mapModuloSistema, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === "P2002"
      ) {
        return reply.status(409).send({ error: "Já existe um módulo com este código" });
      }
      throw err;
    }
  });

  app.put("/modulos-sistema/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateModuloSistemaSchema.parse(request.body);
      const item = await updateModuloSistema(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Módulo não encontrado" });
      }
      const full = await getModuloSistemaById(id);
      return reply.send(mapModuloSistema(full!));
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

  app.delete("/modulos-sistema/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await deleteModuloSistema(id);
      if (!item) {
        return reply.status(404).send({ error: "Módulo não encontrado" });
      }
      return replyMapped(reply, item, mapModuloSistema);
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/modulos-sistema/:id/programas", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = modulosProgramasBodySchema.parse(request.body);
      const item = await setModuloProgramas(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Módulo não encontrado" });
      }
      return replyMapped(reply, item, mapModuloSistema);
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
};
