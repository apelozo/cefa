import type { FastifyPluginAsync } from "fastify";
import { replyMapped } from "../lib/resposta-api.js";
import { ZodError } from "zod";
import {
  AlunoConflictError,
  AlunoInativoError,
  AlunoReferenciaError,
  AlunoValidationError,
  createAluno,
  desativarAluno,
  getAlunoById,
  listAlunos,
  mapAluno,
  updateAluno,
} from "../services/alunos.js";
import { createAlunoSchema } from "../validators/alunos.js";

export const alunosRoutes: FastifyPluginAsync = async (app) => {
  app.get("/alunos", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      nome?: string;
      cpf?: string;
    };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    const items = await listAlunos({
      ativo,
      nome: query.nome,
      cpf: query.cpf,
    });
    return reply.send(items);
  });

  app.get("/alunos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getAlunoById(id);
    if (!item) {
      return reply.status(404).send({ error: "Aluno não encontrado" });
    }
    return replyMapped(reply, item, mapAluno);
  });

  app.post("/alunos", async (request, reply) => {
    try {
      const body = createAlunoSchema.parse(request.body);
      const item = await createAluno(body, request.usuarioId!);
      return replyMapped(reply, item, mapAluno, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof AlunoConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof AlunoReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      if (err instanceof AlunoValidationError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/alunos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = createAlunoSchema.parse(request.body);
      const item = await updateAluno(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Aluno não encontrado" });
      }
      return replyMapped(reply, item, mapAluno);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof AlunoConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof AlunoInativoError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof AlunoReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/alunos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await desativarAluno(id, request.usuarioId!);
    if (!item) {
      return reply.status(404).send({ error: "Aluno não encontrado" });
    }
    return replyMapped(reply, item, mapAluno);
  });
};
