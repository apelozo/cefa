import type { FastifyPluginAsync } from "fastify";
import { ZodError } from "zod";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import {
  DepartamentoConflictError,
  DepartamentoInativoError,
  createDepartamento,
  desativarDepartamento,
  getDepartamentoById,
  listDepartamentos,
  mapDepartamento,
  updateDepartamento,
} from "../services/departamentos.js";
import {
  createDepartamentoSchema,
  updateDepartamentoSchema,
} from "../validators/departamentos.js";

export const departamentosRoutes: FastifyPluginAsync = async (app) => {
  app.get("/departamentos", async (request, reply) => {
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

    const items = await listDepartamentos({
      ativo,
      codigo,
      descricao: query.descricao,
    });
    return reply.send(items.map(mapDepartamento));
  });

  app.get("/departamentos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getDepartamentoById(id);
    if (!item) {
      return reply.status(404).send({ error: "Departamento não encontrado" });
    }
    return reply.send(mapDepartamento(item));
  });

  app.post("/departamentos", async (request, reply) => {
    try {
      const body = createDepartamentoSchema.parse(request.body);
      const item = await createDepartamento(body, request.usuarioId!);
      return reply.status(201).send(mapDepartamento(item));
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof DepartamentoConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/departamentos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateDepartamentoSchema.parse(request.body);
      const item = await updateDepartamento(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Departamento não encontrado" });
      }
      return reply.send(mapDepartamento(item));
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof DepartamentoConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof DepartamentoInativoError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/departamentos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await desativarDepartamento(id, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Departamento não encontrado" });
      }
      return reply.send(mapDepartamento(item));
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });
};
