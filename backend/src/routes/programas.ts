import type { FastifyPluginAsync } from "fastify";
import { listProgramas, mapPrograma } from "../services/programas.js";

export const programasRoutes: FastifyPluginAsync = async (app) => {
  app.get("/programas", async (_request, reply) => {
    const items = await listProgramas();
    return reply.send(items.map(mapPrograma));
  });
};
