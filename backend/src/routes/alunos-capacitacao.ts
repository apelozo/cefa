import type { FastifyPluginAsync } from "fastify";
import { ZodError } from "zod";
import {
  AlunoCapacitacaoConflictError,
  AlunoCapacitacaoInativoError,
  AlunoCapacitacaoReferenciaError,
  AlunoCapacitacaoValidationError,
  createAlunoCapacitacao,
  desativarAlunoCapacitacao,
  getAlunoCapacitacaoById,
  listAlunosCapacitacao,
  mapAlunoCapacitacao,
  updateAlunoCapacitacao,
} from "../services/alunos-capacitacao.js";
import { createAlunoCapacitacaoSchema } from "../validators/alunos-capacitacao.js";

export const alunosCapacitacaoRoutes: FastifyPluginAsync = async (app) => {
  app.get("/alunos-capacitacao", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      nome?: string;
      cpf?: string;
    };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    const items = await listAlunosCapacitacao({
      ativo,
      nome: query.nome,
      cpf: query.cpf,
    });
    return reply.send(items);
  });

  app.get("/alunos-capacitacao/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getAlunoCapacitacaoById(id);
    if (!item) {
      return reply
        .status(404)
        .send({ error: "Aluno de capacitação não encontrado" });
    }
    return reply.send(mapAlunoCapacitacao(item));
  });

  app.post("/alunos-capacitacao", async (request, reply) => {
    try {
      const body = createAlunoCapacitacaoSchema.parse(request.body);
      const item = await createAlunoCapacitacao(body, request.usuarioId!);
      return reply.status(201).send(mapAlunoCapacitacao(item));
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof AlunoCapacitacaoConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof AlunoCapacitacaoReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      if (err instanceof AlunoCapacitacaoValidationError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/alunos-capacitacao/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = createAlunoCapacitacaoSchema.parse(request.body);
      const item = await updateAlunoCapacitacao(id, body, request.usuarioId!);
      if (!item) {
        return reply
          .status(404)
          .send({ error: "Aluno de capacitação não encontrado" });
      }
      return reply.send(mapAlunoCapacitacao(item));
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof AlunoCapacitacaoConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof AlunoCapacitacaoInativoError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof AlunoCapacitacaoReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/alunos-capacitacao/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await desativarAlunoCapacitacao(id, request.usuarioId!);
    if (!item) {
      return reply
        .status(404)
        .send({ error: "Aluno de capacitação não encontrado" });
    }
    return reply.send(mapAlunoCapacitacao(item));
  });
};
