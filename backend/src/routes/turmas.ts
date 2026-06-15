import type { FastifyPluginAsync } from "fastify";
import type { PeriodoInscricao, SituacaoTurma } from "@prisma/client";
import { ZodError } from "zod";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { PERIODO_INSCRICAO_VALUES } from "../lib/periodo-inscricao.js";
import { SITUACAO_TURMA_VALUES } from "../lib/situacao-turma.js";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import {
  TurmaAbertaConflitoError,
  TurmaConflictError,
  TurmaInativaError,
  createTurma,
  desativarTurma,
  getTurmaById,
  listTurmas,
  mapTurma,
  updateTurma,
} from "../services/turmas.js";
import { createTurmaSchema, updateTurmaSchema } from "../validators/turmas.js";

function parsePeriodoQuery(value: string | undefined): PeriodoInscricao | undefined {
  if (!value?.trim()) return undefined;
  const v = value.trim().toUpperCase();
  if ((PERIODO_INSCRICAO_VALUES as readonly string[]).includes(v)) {
    return v as PeriodoInscricao;
  }
  return undefined;
}

function parseSituacaoQuery(value: string | undefined): SituacaoTurma | undefined {
  if (!value?.trim()) return undefined;
  const v = value.trim().toUpperCase();
  if ((SITUACAO_TURMA_VALUES as readonly string[]).includes(v)) {
    return v as SituacaoTurma;
  }
  return undefined;
}

export const turmasRoutes: FastifyPluginAsync = async (app) => {
  app.get("/turmas", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      codigo?: string;
      nome?: string;
      cursoCodigo?: string;
      cursoDescricao?: string;
      periodo?: string;
      situacao?: string;
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

    let cursoCodigo: number | undefined;
    if (query.cursoCodigo?.trim()) {
      const parsed = Number.parseInt(query.cursoCodigo.trim(), 10);
      if (!Number.isNaN(parsed) && parsed > 0) {
        cursoCodigo = parsed;
      }
    }

    const items = await listTurmas({
      ativo,
      codigo,
      nome: query.nome,
      cursoCodigo,
      cursoDescricao: query.cursoDescricao,
      periodo: parsePeriodoQuery(query.periodo),
      situacao: parseSituacaoQuery(query.situacao),
    });
    return reply.send(items);
  });

  app.get("/turmas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getTurmaById(id);
    if (!item) {
      return reply.status(404).send({ error: "Turma não encontrada" });
    }
    return replyMapped(reply, item, mapTurma);
  });

  app.post("/turmas", async (request, reply) => {
    try {
      const body = createTurmaSchema.parse(request.body);
      const item = await createTurma(body, request.usuarioId!);
      return replyMapped(reply, item, mapTurma, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (
        err instanceof TurmaConflictError ||
        err instanceof TurmaAbertaConflitoError
      ) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/turmas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateTurmaSchema.parse(request.body);
      const item = await updateTurma(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Turma não encontrada" });
      }
      return replyMapped(reply, item, mapTurma);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (
        err instanceof TurmaConflictError ||
        err instanceof TurmaAbertaConflitoError ||
        err instanceof TurmaInativaError
      ) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/turmas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await desativarTurma(id, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Turma não encontrada" });
      }
      return replyMapped(reply, item, mapTurma);
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });
};
