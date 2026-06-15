import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { ZodError } from "zod";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { temAcessoPrograma } from "../services/permissoes.js";
import {
  assertUsuarioAcessoTipoFormulario,
  TipoFormularioAcessoNegadoError,
} from "../services/tipos-formulario-acesso.js";
import {
  createTipoFormulario,
  getTipoFormularioById,
  listTiposFormulario,
  mapTipoFormulario,
  deleteTipoFormulario,
  updateTipoFormulario,
} from "../services/tipos-formulario.js";
import {
  createTipoFormularioSchema,
  updateTipoFormularioSchema,
} from "../validators/tipos-formulario.js";

export const tiposFormularioRoutes: FastifyPluginAsync = async (app) => {
  app.get("/tipos-formulario", async (request, reply) => {
    const query = request.query as { ativo?: string; todos?: string };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    const todos = query.todos === "true";
    if (todos && !request.isAdmin) {
      const map = request.permissaoMap;
      if (!map || !temAcessoPrograma(map, "tipos_formulario")) {
        return reply.status(403).send({
          error: "Sem permissão para listar todos os tipos de formulário",
        });
      }
    }

    const items = await listTiposFormulario(request.usuarioId!, {
      ativo,
      todos,
    });
    return replyMappedList(reply, items, mapTipoFormulario);
  });

  app.get("/tipos-formulario/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getTipoFormularioById(id);
    if (!item) {
      return reply.status(404).send({ error: "Tipo de formulário não encontrado" });
    }

    const cadastroAdmin =
      request.isAdmin ||
      (request.permissaoMap &&
        temAcessoPrograma(request.permissaoMap, "tipos_formulario"));

    if (!cadastroAdmin) {
      try {
        await assertUsuarioAcessoTipoFormulario(request.usuarioId!, id);
      } catch (err) {
        if (err instanceof TipoFormularioAcessoNegadoError) {
          return reply.status(403).send({ error: err.message });
        }
        throw err;
      }
    }

    return replyMapped(reply, item, mapTipoFormulario);
  });

  app.post("/tipos-formulario", async (request, reply) => {
    try {
      const body = createTipoFormularioSchema.parse(request.body);
      const item = await createTipoFormulario(body, request.usuarioId!);
      return replyMapped(reply, item, mapTipoFormulario, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      throw err;
    }
  });

  app.put("/tipos-formulario/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateTipoFormularioSchema.parse(request.body);
      const item = await updateTipoFormulario(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Tipo de formulário não encontrado" });
      }
      return replyMapped(reply, item, mapTipoFormulario);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      throw err;
    }
  });

  app.delete("/tipos-formulario/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await deleteTipoFormulario(id);
      if (!item) {
        return reply.status(404).send({ error: "Tipo de formulário não encontrado" });
      }
      return replyMapped(reply, item, mapTipoFormulario);
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });
};
