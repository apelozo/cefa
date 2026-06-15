import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { Prisma } from "@prisma/client";
import { ZodError } from "zod";
import { isUfBrasil } from "../lib/uf-brasil.js";
import {
  CidadeConflictError,
  CidadeInativaError,
  createCidade,
  getCidadeById,
  listCidades,
  mapCidade,
  softDeleteCidade,
  updateCidade,
} from "../services/cidades.js";
import { createCidadeSchema, updateCidadeSchema } from "../validators/cidades.js";

export const cidadesRoutes: FastifyPluginAsync = async (app) => {
  app.get("/cidades", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      nome?: string;
      estado?: string;
    };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    let estado: string | undefined;
    if (query.estado?.trim()) {
      const uf = query.estado.trim().toUpperCase();
      if (!isUfBrasil(uf)) {
        return reply.status(400).send({ error: "Estado inválido" });
      }
      estado = uf;
    }

    const items = await listCidades({
      ativo,
      nome: query.nome,
      estado,
    });
    return replyMappedList(reply, items, mapCidade);
  });

  app.get("/cidades/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getCidadeById(id);
    if (!item) {
      return reply.status(404).send({ error: "Cidade não encontrada" });
    }
    return replyMapped(reply, item, mapCidade);
  });

  app.post("/cidades", async (request, reply) => {
    try {
      const body = createCidadeSchema.parse(request.body);
      const item = await createCidade(body, request.usuarioId!);
      return replyMapped(reply, item, mapCidade, 201);
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
        return reply.status(409).send({
          error: "Já existe uma cidade com este município e estado",
        });
      }
      throw err;
    }
  });

  app.put("/cidades/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateCidadeSchema.parse(request.body);
      const item = await updateCidade(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Cidade não encontrada" });
      }
      return replyMapped(reply, item, mapCidade);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof CidadeConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof CidadeInativaError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/cidades/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await softDeleteCidade(id, request.usuarioId!);
    if (!item) {
      return reply.status(404).send({ error: "Cidade não encontrada" });
    }
    return replyMapped(reply, item, mapCidade);
  });
};
