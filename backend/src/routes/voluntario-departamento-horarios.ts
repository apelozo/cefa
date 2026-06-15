import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { ZodError } from "zod";
import {
  VoluntarioDepartamentoHorarioReferenciaError,
  createHorario,
  deleteHorario,
  getHorarioById,
  listHorariosPorVoluntario,
  mapVoluntarioDepartamentoHorario,
  updateHorario,
} from "../services/voluntario-departamento-horarios.js";
import {
  createVoluntarioDepartamentoHorarioSchema,
  updateVoluntarioDepartamentoHorarioSchema,
} from "../validators/voluntario-departamento-horarios.js";

export const voluntarioDepartamentoHorariosRoutes: FastifyPluginAsync = async (
  app,
) => {
  app.get("/voluntarios/:voluntarioId/departamento-horarios", async (request, reply) => {
    const { voluntarioId } = request.params as { voluntarioId: string };
    const items = await listHorariosPorVoluntario(voluntarioId);
    return replyMappedList(reply, items, mapVoluntarioDepartamentoHorario);
  });

  app.post("/voluntarios/:voluntarioId/departamento-horarios", async (request, reply) => {
    const { voluntarioId } = request.params as { voluntarioId: string };
    try {
      const body = createVoluntarioDepartamentoHorarioSchema.parse(request.body);
      const item = await createHorario(voluntarioId, body, request.usuarioId!);
      return replyMapped(reply, item, mapVoluntarioDepartamentoHorario, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof VoluntarioDepartamentoHorarioReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.get("/voluntario-departamento-horarios/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getHorarioById(id);
    if (!item) {
      return reply.status(404).send({ error: "Vínculo não encontrado" });
    }
    return replyMapped(reply, item, mapVoluntarioDepartamentoHorario);
  });

  app.put("/voluntario-departamento-horarios/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateVoluntarioDepartamentoHorarioSchema.parse(request.body);
      const item = await updateHorario(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Vínculo não encontrado" });
      }
      return replyMapped(reply, item, mapVoluntarioDepartamentoHorario);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof VoluntarioDepartamentoHorarioReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      if (err instanceof Error && err.message.includes("Hora término")) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/voluntario-departamento-horarios/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await deleteHorario(id);
    if (!item) {
      return reply.status(404).send({ error: "Vínculo não encontrado" });
    }
    return replyMapped(reply, item, mapVoluntarioDepartamentoHorario);
  });
};
