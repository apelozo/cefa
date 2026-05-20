import type { FastifyPluginAsync } from "fastify";
import { ZodError } from "zod";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import {
  createPergunta,
  getPerguntaById,
  listPerguntas,
  mapPergunta,
  deletePergunta,
  OpcaoNaoEncontradaError,
  OpcoesListaInvalidasError,
  OrdemDuplicadaError,
  TipoCampoImutavelError,
  TipoFormularioInativoError,
  TipoFormularioNaoEncontradoError,
  updatePergunta,
} from "../services/perguntas.js";
import {
  createPerguntaSchema,
  updatePerguntaSchema,
} from "../validators/perguntas.js";

export const perguntasRoutes: FastifyPluginAsync = async (app) => {
  app.get("/perguntas", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      tipoFormularioId?: string;
      opcoesAtivas?: string;
    };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    const opcoesAtivas = query.opcoesAtivas === "true";

    const items = await listPerguntas({
      ativo,
      tipoFormularioId: query.tipoFormularioId,
      opcoesAtivas,
    });
    return reply.send(items.map(mapPergunta));
  });

  app.get("/perguntas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const pergunta = await getPerguntaById(id);
    if (!pergunta) {
      return reply.status(404).send({ error: "Pergunta não encontrada" });
    }
    return reply.send(mapPergunta(pergunta));
  });

  app.post("/perguntas", async (request, reply) => {
    try {
      const body = createPerguntaSchema.parse(request.body);
      const pergunta = await createPergunta(body, request.usuarioId!);
      return reply.status(201).send(mapPergunta(pergunta));
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (
        err instanceof TipoFormularioNaoEncontradoError ||
        err instanceof TipoFormularioInativoError ||
        err instanceof OpcoesListaInvalidasError ||
        err instanceof OrdemDuplicadaError
      ) {
        return reply.status(err instanceof OrdemDuplicadaError ? 409 : 400).send({
          error: err.message,
        });
      }
      throw err;
    }
  });

  app.put("/perguntas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updatePerguntaSchema.parse(request.body);
      const pergunta = await updatePergunta(id, body, request.usuarioId!);
      if (!pergunta) {
        return reply.status(404).send({ error: "Pergunta não encontrada" });
      }
      return reply.send(mapPergunta(pergunta));
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (
        err instanceof TipoCampoImutavelError ||
        err instanceof OrdemDuplicadaError
      ) {
        return reply.status(409).send({ error: err.message });
      }
      if (
        err instanceof TipoFormularioNaoEncontradoError ||
        err instanceof TipoFormularioInativoError ||
        err instanceof OpcoesListaInvalidasError ||
        err instanceof OpcaoNaoEncontradaError
      ) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/perguntas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const pergunta = await deletePergunta(id);
      if (!pergunta) {
        return reply.status(404).send({ error: "Pergunta não encontrada" });
      }
      return reply.send(mapPergunta(pergunta));
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });
};
