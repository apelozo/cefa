import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { ZodError } from "zod";
import {
  CursoConflictError,
  CursoInativoError,
  createCurso,
  desativarCurso,
  getCursoById,
  listCursos,
  mapCurso,
  updateCurso,
} from "../services/cursos.js";
import { createCursoSchema, updateCursoSchema } from "../validators/cursos.js";

export const cursosRoutes: FastifyPluginAsync = async (app) => {
  app.get("/cursos", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      codigo?: string;
      descricao?: string;
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

    const items = await listCursos({
      ativo,
      codigo,
      descricao: query.descricao,
    });
    return replyMappedList(reply, items, mapCurso);
  });

  app.get("/cursos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getCursoById(id);
    if (!item) {
      return reply.status(404).send({ error: "Curso não encontrado" });
    }
    return replyMapped(reply, item, mapCurso);
  });

  app.post("/cursos", async (request, reply) => {
    try {
      const body = createCursoSchema.parse(request.body);
      const item = await createCurso(body, request.usuarioId!);
      return replyMapped(reply, item, mapCurso, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof CursoConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/cursos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateCursoSchema.parse(request.body);
      const item = await updateCurso(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Curso não encontrado" });
      }
      return replyMapped(reply, item, mapCurso);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof CursoConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof CursoInativoError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/cursos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await desativarCurso(id, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Curso não encontrado" });
      }
      return replyMapped(reply, item, mapCurso);
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });
};
