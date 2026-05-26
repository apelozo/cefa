import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { ZodError } from "zod";
import {
  VoluntarioConflictError,
  VoluntarioInativoError,
  VoluntarioReferenciaError,
  createVoluntario,
  desativarVoluntario,
  getVoluntarioById,
  listVoluntarios,
  mapVoluntario,
  updateVoluntario,
} from "../services/voluntarios.js";
import {
  createVoluntarioSchema,
  updateVoluntarioSchema,
} from "../validators/voluntarios.js";

export const voluntariosRoutes: FastifyPluginAsync = async (app) => {
  app.get("/voluntarios", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      codigo?: string;
      nome?: string;
      nomeCracha?: string;
      empresa?: string;
      cpf?: string;
      departamentoCodigo?: string;
    };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    let codigo: number | undefined;
    if (query.codigo?.trim()) {
      const parsed = Number.parseInt(query.codigo.trim(), 10);
      if (!Number.isNaN(parsed) && parsed > 0) {
        codigo = parsed;
      }
    }

    let departamentoCodigo: number | undefined;
    if (query.departamentoCodigo?.trim()) {
      const parsed = Number.parseInt(query.departamentoCodigo.trim(), 10);
      if (!Number.isNaN(parsed) && parsed > 0) {
        departamentoCodigo = parsed;
      }
    }

    const items = await listVoluntarios({
      ativo,
      codigo,
      nome: query.nome ?? query.nomeCracha,
      empresa: query.empresa,
      cpf: query.cpf,
      departamentoCodigo,
    });
    return replyMappedList(reply, items, mapVoluntario);
  });

  app.get("/voluntarios/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getVoluntarioById(id);
    if (!item) {
      return reply.status(404).send({ error: "Voluntário não encontrado" });
    }
    return replyMapped(reply, item, mapVoluntario);
  });

  app.post("/voluntarios", async (request, reply) => {
    try {
      const body = createVoluntarioSchema.parse(request.body);
      const item = await createVoluntario(body, request.usuarioId!);
      return replyMapped(reply, item, mapVoluntario, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof VoluntarioConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof VoluntarioReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/voluntarios/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateVoluntarioSchema.parse(request.body);
      const item = await updateVoluntario(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Voluntário não encontrado" });
      }
      return replyMapped(reply, item, mapVoluntario);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof VoluntarioConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof VoluntarioInativoError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof VoluntarioReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/voluntarios/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await desativarVoluntario(id, request.usuarioId!);
    if (!item) {
      return reply.status(404).send({ error: "Voluntário não encontrado" });
    }
    return replyMapped(reply, item, mapVoluntario);
  });
};
