import type { FastifyPluginAsync } from "fastify";
import { Prisma } from "@prisma/client";
import { ZodError } from "zod";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import {
  createPessoa,
  getPessoaById,
  listPessoas,
  mapPessoa,
  PessoaConflictError,
  PessoaReferenciaError,
  deletePessoa,
  updatePessoa,
} from "../services/pessoas.js";
import { createPessoaSchema, updatePessoaSchema } from "../validators/pessoas.js";

export const pessoasRoutes: FastifyPluginAsync = async (app) => {
  app.get("/pessoas", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      q?: string;
      nome?: string;
      cpf?: string;
      rg?: string;
    };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    const items = await listPessoas({
      ativo,
      q: query.q,
      nome: query.nome,
      cpf: query.cpf,
      rg: query.rg,
    });
    return reply.send(items.map(mapPessoa));
  });

  app.get("/pessoas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getPessoaById(id);
    if (!item) {
      return reply.status(404).send({ error: "Assistido não encontrado" });
    }
    return reply.send(mapPessoa(item));
  });

  app.post("/pessoas", async (request, reply) => {
    try {
      const body = createPessoaSchema.parse(request.body);
      const item = await createPessoa(body, request.usuarioId!);
      return reply.status(201).send(mapPessoa(item));
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
        return reply.status(409).send({ error: "CPF já cadastrado" });
      }
      if (err instanceof PessoaReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/pessoas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updatePessoaSchema.parse(request.body);
      const item = await updatePessoa(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Assistido não encontrado" });
      }
      return reply.send(mapPessoa(item));
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof PessoaConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof PessoaReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/pessoas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await deletePessoa(id);
      if (!item) {
        return reply.status(404).send({ error: "Assistido não encontrado" });
      }
      return reply.send(mapPessoa(item));
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });
};
