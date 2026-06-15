import type { FastifyPluginAsync } from "fastify";
import { ZodError } from "zod";

import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import {
  TurmaInativaError,
  TurmaNaoEncontradaError,
} from "../services/turmas.js";
import {
  AtendimentoValidationError,
  createInscricaoAtendimento,
  deleteInscricaoAtendimento,
  getInscricaoAtendimentoById,
  listAlunosMatriculados,
  listInscricaoAtendimentos,
  mapAlunoMatriculadoResumo,
  mapInscricaoAtendimento,
  mapInscricaoAtendimentoLista,
  updateInscricaoAtendimento,
} from "../services/inscricao-atendimentos.js";
import {
  createInscricaoAtendimentoSchema,
  listAlunosMatriculadosQuerySchema,
  listInscricaoAtendimentosQuerySchema,
  updateInscricaoAtendimentoSchema,
} from "../validators/inscricao-atendimentos.js";
import { formatCpf } from "../lib/cpf.js";

export const inscricaoAtendimentosRoutes: FastifyPluginAsync = async (app) => {
  app.get("/inscricao-atendimentos/alunos-matriculados", async (request, reply) => {
    try {
      const query = listAlunosMatriculadosQuerySchema.parse(request.query);
      const items = await listAlunosMatriculados({
        turmaCodigo: query.turmaCodigo,
        nome: query.nome,
        cpf: query.cpf,
      });
      return reply.send(
        items.map((item) => ({
          ...mapAlunoMatriculadoResumo(item),
          alunoCpfFormatado: item.alunoCpf ? formatCpf(item.alunoCpf) : null,
        })),
      );
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof TurmaNaoEncontradaError) {
        return reply.status(404).send({ error: err.message });
      }
      if (err instanceof TurmaInativaError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.get("/inscricao-atendimentos", async (request, reply) => {
    try {
      const query = listInscricaoAtendimentosQuerySchema.parse(request.query);
      const { inscricao, items } = await listInscricaoAtendimentos({
        inscricaoId: query.inscricaoId,
        turmaCodigo: query.turmaCodigo,
        alunoId: query.alunoId,
      });
      return reply.send({
        inscricaoId: inscricao.id,
        inscricaoCodigo: inscricao.codigo,
        alunoId: inscricao.aluno.id,
        alunoNome: inscricao.aluno.nome,
        turmaCodigo: inscricao.turma.codigo,
        turmaNome: inscricao.turma.nome,
        cursoDescricao: inscricao.turma.curso.descricao,
        matriculado: inscricao.matriculado,
        matriculaCancelada: inscricao.matriculaCancelada,
        atendimentos: items.map(mapInscricaoAtendimentoLista),
      });
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof AtendimentoValidationError) {
        return reply.status(400).send({ error: err.message });
      }
      if (err instanceof TurmaNaoEncontradaError) {
        return reply.status(404).send({ error: err.message });
      }
      if (err instanceof TurmaInativaError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.get("/inscricao-atendimentos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getInscricaoAtendimentoById(id);
    if (!item) {
      return reply.status(404).send({ error: "Atendimento não encontrado" });
    }
    return replyMapped(reply, item, mapInscricaoAtendimento);
  });

  app.post("/inscricao-atendimentos", async (request, reply) => {
    try {
      const body = createInscricaoAtendimentoSchema.parse(request.body);
      const item = await createInscricaoAtendimento(body, request.usuarioId!);
      return replyMapped(reply, item, mapInscricaoAtendimento, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof AtendimentoValidationError) {
        return reply.status(400).send({ error: err.message });
      }
      if (err instanceof TurmaNaoEncontradaError) {
        return reply.status(404).send({ error: err.message });
      }
      if (err instanceof TurmaInativaError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/inscricao-atendimentos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateInscricaoAtendimentoSchema.parse(request.body);
      const item = await updateInscricaoAtendimento(
        id,
        body,
        request.usuarioId!,
      );
      if (!item) {
        return reply.status(404).send({ error: "Atendimento não encontrado" });
      }
      return replyMapped(reply, item, mapInscricaoAtendimento);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof AtendimentoValidationError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/inscricao-atendimentos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const removed = await deleteInscricaoAtendimento(id);
    if (!removed) {
      return reply.status(404).send({ error: "Atendimento não encontrado" });
    }
    return reply.status(204).send();
  });
};
