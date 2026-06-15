import type { FastifyPluginAsync } from "fastify";

import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";

import { ZodError } from "zod";

import {
  TurmaFechadaError,
  TurmaInativaError,
  TurmaNaoEncontradaError,
} from "../services/turmas.js";

import {

  createInscricao,

  desativarInscricao,

  getInscricaoById,

  InscricaoInativaError,

  InscricaoReferenciaError,

  InscricaoValidationError,

  listInscricoes,

  mapInscricao,

  updateInscricao,

} from "../services/inscricoes.js";

import {

  createInscricaoSchema,

} from "../validators/inscricoes.js";

import {

  gravarMatricula,

  listMatriculaCandidatos,

  MatriculaTurmaError,

  MatriculaValidationError,

  MatriculaVagasPreenchidasError,

} from "../services/inscricao-matricula.js";

import {

  gravarMatriculaSchema,

  listMatriculaCandidatosQuerySchema,

} from "../validators/inscricao-matricula.js";

import {

  gravarCancelamentoMatricula,

  listCancelamentoMatriculaMatriculados,

  CancelamentoMatriculaTurmaError,

  CancelamentoMatriculaValidationError,

} from "../services/inscricao-cancelamento-matricula.js";

import {

  gravarCancelamentoMatriculaSchema,

  listCancelamentoMatriculaQuerySchema,

} from "../validators/inscricao-cancelamento-matricula.js";

import {
  gerarRelatorioAlunosTurma,
  RelatorioAlunosTurmaError,
} from "../services/relatorio-alunos-turma.js";

import { relatorioAlunosTurmaQuerySchema } from "../validators/relatorio-alunos-turma.js";

import { listCursos, mapCurso } from "../services/cursos.js";
import { listTurmas } from "../services/turmas.js";



export const inscricoesRoutes: FastifyPluginAsync = async (app) => {

  app.get("/inscricoes/relatorio-alunos-turma/cursos", async (_request, reply) => {
    const items = await listCursos({ ativo: true });
    return replyMappedList(reply, items, mapCurso);
  });

  app.get("/inscricoes/relatorio-alunos-turma/turmas", async (request, reply) => {
    const query = request.query as { cursoCodigo?: string };

    let cursoCodigo: number | undefined;
    if (query.cursoCodigo?.trim()) {
      const parsed = Number.parseInt(query.cursoCodigo.trim(), 10);
      if (!Number.isNaN(parsed) && parsed > 0) cursoCodigo = parsed;
    }

    const items = await listTurmas({ ativo: true, cursoCodigo });
    return reply.send(items);
  });

  app.get("/inscricoes/relatorio-alunos-turma", async (request, reply) => {
    try {
      const query = relatorioAlunosTurmaQuerySchema.parse(request.query);
      const result = await gerarRelatorioAlunosTurma(query);
      return reply.send(result);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof RelatorioAlunosTurmaError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.get("/inscricoes/matricula/candidatos", async (request, reply) => {

    try {

      const query = listMatriculaCandidatosQuerySchema.parse(request.query);

      const result = await listMatriculaCandidatos(query.turmaCodigo);

      return reply.send(result);

    } catch (err) {

      if (err instanceof ZodError) {

        return reply.status(400).send({

          error: "Validação falhou",

          details: err.flatten(),

        });

      }

      if (
        err instanceof MatriculaTurmaError ||
        err instanceof TurmaNaoEncontradaError ||
        err instanceof TurmaInativaError
      ) {
        return reply.status(400).send({ error: err.message });
      }

      throw err;

    }

  });



  app.post("/inscricoes/matricula", async (request, reply) => {

    try {

      const body = gravarMatriculaSchema.parse(request.body);

      const result = await gravarMatricula(body, request.usuarioId!);

      return reply.send(result);

    } catch (err) {

      if (err instanceof ZodError) {

        return reply.status(400).send({

          error: "Validação falhou",

          details: err.flatten(),

        });

      }

      if (err instanceof MatriculaValidationError) {

        return reply.status(400).send({ error: err.message });

      }

      if (err instanceof MatriculaVagasPreenchidasError) {

        return reply.status(409).send({ error: err.message });

      }

      if (
        err instanceof MatriculaTurmaError ||
        err instanceof TurmaNaoEncontradaError ||
        err instanceof TurmaInativaError
      ) {
        return reply.status(400).send({ error: err.message });
      }

      throw err;

    }

  });



  app.get("/inscricoes/cancelamento-matricula/matriculados", async (request, reply) => {

    try {

      const query = listCancelamentoMatriculaQuerySchema.parse(request.query);

      const result = await listCancelamentoMatriculaMatriculados(query.turmaCodigo);

      return reply.send(result);

    } catch (err) {

      if (err instanceof ZodError) {

        return reply.status(400).send({

          error: "Validação falhou",

          details: err.flatten(),

        });

      }

      if (
        err instanceof CancelamentoMatriculaTurmaError ||
        err instanceof TurmaNaoEncontradaError ||
        err instanceof TurmaInativaError
      ) {
        return reply.status(400).send({ error: err.message });
      }

      throw err;

    }

  });



  app.post("/inscricoes/cancelamento-matricula", async (request, reply) => {

    try {

      const body = gravarCancelamentoMatriculaSchema.parse(request.body);

      const result = await gravarCancelamentoMatricula(body, request.usuarioId!);

      return reply.send(result);

    } catch (err) {

      if (err instanceof ZodError) {

        return reply.status(400).send({

          error: "Validação falhou",

          details: err.flatten(),

        });

      }

      if (err instanceof CancelamentoMatriculaValidationError) {

        return reply.status(400).send({ error: err.message });

      }

      if (
        err instanceof CancelamentoMatriculaTurmaError ||
        err instanceof TurmaNaoEncontradaError ||
        err instanceof TurmaInativaError
      ) {
        return reply.status(400).send({ error: err.message });
      }

      throw err;

    }

  });



  app.get("/inscricoes", async (request, reply) => {

    const query = request.query as {

      ativo?: string;

      codigo?: string;

      alunoId?: string;

      alunoNome?: string;

      alunoCpf?: string;

      turmaCodigo?: string;

      turmaNome?: string;

      cursoCodigo?: string;

      cursoDescricao?: string;

    };



    let ativo: boolean | undefined;

    if (query.ativo === "true") ativo = true;

    else if (query.ativo === "false") ativo = false;



    let codigo: number | undefined;

    if (query.codigo?.trim()) {

      const parsed = Number.parseInt(query.codigo.trim(), 10);

      if (!Number.isNaN(parsed) && parsed > 0) codigo = parsed;

    }



    let turmaCodigo: number | undefined;

    if (query.turmaCodigo?.trim()) {

      const parsed = Number.parseInt(query.turmaCodigo.trim(), 10);

      if (!Number.isNaN(parsed) && parsed > 0) turmaCodigo = parsed;

    }



    let cursoCodigo: number | undefined;

    if (query.cursoCodigo?.trim()) {

      const parsed = Number.parseInt(query.cursoCodigo.trim(), 10);

      if (!Number.isNaN(parsed) && parsed > 0) cursoCodigo = parsed;

    }



    const alunoId = query.alunoId?.trim() || undefined;



    const items = await listInscricoes({

      ativo,

      codigo,

      alunoId,

      alunoNome: query.alunoNome,

      alunoCpf: query.alunoCpf,

      turmaCodigo,

      turmaNome: query.turmaNome,

      cursoCodigo,

      cursoDescricao: query.cursoDescricao,

    });

    return reply.send(items);

  });



  app.get("/inscricoes/:id", async (request, reply) => {

    const { id } = request.params as { id: string };

    const item = await getInscricaoById(id);

    if (!item) {

      return reply.status(404).send({ error: "Inscrição não encontrada" });

    }

    return replyMapped(reply, item, mapInscricao);

  });



  app.post("/inscricoes", async (request, reply) => {

    try {

      const body = createInscricaoSchema.parse(request.body);

      const item = await createInscricao(body, request.usuarioId!);

      return replyMapped(reply, item, mapInscricao, 201);

    } catch (err) {

      if (err instanceof ZodError) {

        return reply.status(400).send({

          error: "Validação falhou",

          details: err.flatten(),

        });

      }

      if (err instanceof InscricaoReferenciaError) {

        return reply.status(400).send({ error: err.message });

      }

      if (err instanceof TurmaNaoEncontradaError) {

        return reply.status(400).send({ error: err.message });

      }

      if (err instanceof TurmaInativaError || err instanceof TurmaFechadaError) {

        return reply.status(409).send({ error: err.message });

      }

      if (err instanceof InscricaoValidationError) {

        return reply.status(400).send({ error: err.message });

      }

      throw err;

    }

  });



  app.put("/inscricoes/:id", async (request, reply) => {

    const { id } = request.params as { id: string };

    try {

      const body = createInscricaoSchema.parse(request.body);

      const item = await updateInscricao(id, body, request.usuarioId!);

      if (!item) {

        return reply.status(404).send({ error: "Inscrição não encontrada" });

      }

      return replyMapped(reply, item, mapInscricao);

    } catch (err) {

      if (err instanceof ZodError) {

        return reply.status(400).send({

          error: "Validação falhou",

          details: err.flatten(),

        });

      }

      if (err instanceof InscricaoReferenciaError) {

        return reply.status(400).send({ error: err.message });

      }

      if (err instanceof TurmaNaoEncontradaError) {

        return reply.status(400).send({ error: err.message });

      }

      if (err instanceof TurmaInativaError || err instanceof TurmaFechadaError) {

        return reply.status(409).send({ error: err.message });

      }

      if (err instanceof InscricaoInativaError) {

        return reply.status(409).send({ error: err.message });

      }

      throw err;

    }

  });



  app.delete("/inscricoes/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await desativarInscricao(id, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Inscrição não encontrada" });
      }
      return replyMapped(reply, item, mapInscricao);
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

};

