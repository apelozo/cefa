import type { FastifyReply } from "fastify";
import {
  enrichUsuarioMap,
  type RegistroComAuditoriaIds,
  type UsuarioAuditoriaMap,
} from "./auditoria.js";

export type { UsuarioAuditoriaMap };

export async function replyMappedList<T extends object>(
  reply: FastifyReply,
  items: T[],
  mapper: (item: T, usuarios: UsuarioAuditoriaMap) => unknown,
) {
  const usuarios = await enrichUsuarioMap(
    items as Parameters<typeof enrichUsuarioMap>[0],
  );
  return reply.send(items.map((item) => mapper(item, usuarios)));
}

export async function replyMapped<T extends object>(
  reply: FastifyReply,
  item: T,
  mapper: (item: T, usuarios: UsuarioAuditoriaMap) => unknown,
  statusCode = 200,
) {
  const usuarios = await enrichUsuarioMap([item as RegistroComAuditoriaIds]);
  const body = mapper(item, usuarios);
  if (statusCode === 201) {
    return reply.status(201).send(body);
  }
  return reply.send(body);
}
