import { Prisma } from "@prisma/client";

import type { FastifyPluginAsync } from "fastify";

import { ZodError } from "zod";

import {

  createEntrevistaAssistido,

  deleteEntrevistaAssistido,

  EntrevistaAssistidoValidationError,

  getEntrevistaAssistidoById,

  listEntrevistasAssistido,

  mapEntrevistaAssistido,

  mapEntrevistaAssistidoResumo,

  updateEntrevistaAssistido,

} from "../services/entrevistas-assistido.js";
import {
  EscolaridadeInativaError,
  EscolaridadeNaoEncontradaError,
} from "../services/escolaridades.js";

import {

  createEntrevistaAssistidoSchema,

  listEntrevistasAssistidoQuerySchema,

  updateEntrevistaAssistidoSchema,

} from "../validators/entrevistas-assistido.js";



function handleEntrevistaError(

  err: unknown,

  request: { log: { error: (e: unknown) => void } },

  reply: { status: (code: number) => { send: (body: unknown) => unknown } },

) {

  if (err instanceof ZodError) {

    return reply.status(400).send({

      error: "Validação falhou",

      details: err.flatten(),

    });

  }

  if (err instanceof EntrevistaAssistidoValidationError) {

    return reply.status(400).send({

      error: err.message,

      details: err.details,

    });

  }

  if (
    err instanceof EscolaridadeInativaError ||
    err instanceof EscolaridadeNaoEncontradaError
  ) {
    return reply.status(400).send({ error: err.message });
  }

  if (

    err instanceof Prisma.PrismaClientKnownRequestError &&

    (err.code === "P2021" || err.code === "P2022")

  ) {

    return reply.status(503).send({

      error:

        "Estrutura de entrevistas não disponível no banco. Execute: npx prisma migrate deploy",

    });

  }

  if (
    err instanceof Prisma.PrismaClientKnownRequestError &&
    err.code === "P2028"
  ) {
    return reply.status(503).send({
      error:
        "A operação demorou demais no banco de dados. Tente novamente em instantes.",
    });
  }

  request.log.error(err);

  throw err;

}



export const entrevistasAssistidoRoutes: FastifyPluginAsync = async (app) => {

  app.get("/entrevistas-assistido", async (request, reply) => {

    try {

      const query = listEntrevistasAssistidoQuerySchema.parse(request.query);

      const items = await listEntrevistasAssistido(query);

      return reply.send(items.map(mapEntrevistaAssistidoResumo));

    } catch (err) {

      return handleEntrevistaError(err, request, reply);

    }

  });



  app.post("/entrevistas-assistido", async (request, reply) => {

    try {

      const body = createEntrevistaAssistidoSchema.parse(request.body);

      const entrevista = await createEntrevistaAssistido(

        body,

        request.usuarioId!,

      );

      return reply.status(201).send(mapEntrevistaAssistido(entrevista));

    } catch (err) {

      return handleEntrevistaError(err, request, reply);

    }

  });



  app.get("/entrevistas-assistido/:id", async (request, reply) => {

    const { id } = request.params as { id: string };

    const entrevista = await getEntrevistaAssistidoById(id);

    if (!entrevista) {

      return reply.status(404).send({ error: "Entrevista não encontrada" });

    }

    return reply.send(mapEntrevistaAssistido(entrevista));

  });



  app.put("/entrevistas-assistido/:id", async (request, reply) => {

    try {

      const { id } = request.params as { id: string };

      const body = updateEntrevistaAssistidoSchema.parse(request.body);

      const entrevista = await updateEntrevistaAssistido(

        id,

        body,

        request.usuarioId!,

      );

      if (!entrevista) {

        return reply.status(404).send({ error: "Entrevista não encontrada" });

      }

      return reply.send(mapEntrevistaAssistido(entrevista));

    } catch (err) {

      return handleEntrevistaError(err, request, reply);

    }

  });



  app.delete("/entrevistas-assistido/:id", async (request, reply) => {

    const { id } = request.params as { id: string };

    const deleted = await deleteEntrevistaAssistido(id);

    if (!deleted) {

      return reply.status(404).send({ error: "Entrevista não encontrada" });

    }

    return reply.status(204).send();

  });

};

