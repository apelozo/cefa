import type { FastifyPluginAsync } from "fastify";
import { ZodError } from "zod";
import {
  createSubmissao,
  getSubmissaoById,
  listSubmissoes,
  mapSubmissao,
  mapSubmissaoResumo,
  SubmissaoValidationError,
} from "../services/submissoes.js";
import { createSubmissaoSchema } from "../validators/submissoes.js";

export const submissoesRoutes: FastifyPluginAsync = async (app) => {
  app.get("/submissoes", async (request, reply) => {
    const query = request.query as {
      tipoFormularioId?: string;
      pessoaId?: string;
      nome?: string;
      cpf?: string;
    };
    const items = await listSubmissoes({
      tipoFormularioId: query.tipoFormularioId,
      pessoaId: query.pessoaId,
      nome: query.nome,
      cpf: query.cpf,
    });
    return reply.send(items.map(mapSubmissaoResumo));
  });

  app.post("/submissoes", async (request, reply) => {
    try {
      const body = createSubmissaoSchema.parse(request.body);
      const submissao = await createSubmissao(body, request.usuarioId!);
      return reply.status(201).send(mapSubmissao(submissao));
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof SubmissaoValidationError) {
        return reply.status(400).send({
          error: err.message,
          details: err.details,
        });
      }
      throw err;
    }
  });

  app.get("/submissoes/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const submissao = await getSubmissaoById(id);
    if (!submissao) {
      return reply.status(404).send({ error: "Submissão não encontrada" });
    }
    return reply.send(mapSubmissao(submissao));
  });
};
