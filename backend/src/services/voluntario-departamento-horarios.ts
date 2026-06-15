import { Prisma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  mapAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { rotuloDiaSemana } from "../lib/dia-semana.js";
import { formatHora, validarIntervaloHorario } from "../lib/hora.js";
import { prisma } from "../lib/prisma.js";
import type {
  CreateVoluntarioDepartamentoHorarioInput,
  UpdateVoluntarioDepartamentoHorarioInput,
} from "../validators/voluntario-departamento-horarios.js";

const horarioInclude = {
  departamento: { select: { codigo: true, descricao: true, ativo: true } },
  voluntario: {
    select: { id: true, codigo: true, nome: true, nomeCracha: true, ativo: true },
  },
} satisfies Prisma.VoluntarioDepartamentoHorarioInclude;

type HorarioComRelacoes = Prisma.VoluntarioDepartamentoHorarioGetPayload<{
  include: typeof horarioInclude;
}>;

async function assertVoluntarioAtivo(voluntarioId: string) {
  const voluntario = await prisma.voluntario.findUnique({
    where: { id: voluntarioId },
  });
  if (!voluntario) {
    throw new VoluntarioDepartamentoHorarioReferenciaError(
      "Voluntário não encontrado",
    );
  }
  if (!voluntario.ativo) {
    throw new VoluntarioDepartamentoHorarioReferenciaError(
      "Voluntário inativo não pode receber novos vínculos",
    );
  }
  return voluntario;
}

async function assertDepartamentoAtivo(departamentoCodigo: number) {
  const departamento = await prisma.departamento.findUnique({
    where: { codigo: departamentoCodigo },
  });
  if (!departamento || !departamento.ativo) {
    throw new VoluntarioDepartamentoHorarioReferenciaError(
      "Departamento inválido ou inativo",
    );
  }
  return departamento;
}

export async function listHorariosPorVoluntario(voluntarioId: string) {
  return prisma.voluntarioDepartamentoHorario.findMany({
    where: { voluntarioId },
    include: horarioInclude,
    orderBy: [
      { departamentoCodigo: "asc" },
      { diaSemana: "asc" },
      { horaInicio: "asc" },
    ],
  });
}

export async function getHorarioById(id: string) {
  return prisma.voluntarioDepartamentoHorario.findUnique({
    where: { id },
    include: horarioInclude,
  });
}

export async function createHorario(
  voluntarioId: string,
  data: CreateVoluntarioDepartamentoHorarioInput,
  usuarioId: string,
) {
  await assertVoluntarioAtivo(voluntarioId);
  await assertDepartamentoAtivo(data.departamentoCodigo);

  return prisma.voluntarioDepartamentoHorario.create({
    data: {
      voluntarioId,
      departamentoCodigo: data.departamentoCodigo,
      diaSemana: data.diaSemana,
      horaInicio: data.horaInicio,
      horaTermino: data.horaTermino,
      ...auditInclusao(usuarioId),
    },
    include: horarioInclude,
  });
}

export async function updateHorario(
  id: string,
  data: UpdateVoluntarioDepartamentoHorarioInput,
  usuarioId: string,
) {
  const existing = await prisma.voluntarioDepartamentoHorario.findUnique({
    where: { id },
    include: horarioInclude,
  });
  if (!existing) return null;

  const departamentoCodigo =
    data.departamentoCodigo ?? existing.departamentoCodigo;
  if (data.departamentoCodigo !== undefined) {
    await assertDepartamentoAtivo(departamentoCodigo);
  }

  const horaInicio = data.horaInicio ?? existing.horaInicio;
  const horaTermino = data.horaTermino ?? existing.horaTermino;
  validarIntervaloHorario(horaInicio, horaTermino);

  return prisma.voluntarioDepartamentoHorario.update({
    where: { id },
    data: {
      ...(data.departamentoCodigo !== undefined && {
        departamentoCodigo: data.departamentoCodigo,
      }),
      ...(data.diaSemana !== undefined && { diaSemana: data.diaSemana }),
      ...(data.horaInicio !== undefined && { horaInicio: data.horaInicio }),
      ...(data.horaTermino !== undefined && { horaTermino: data.horaTermino }),
      ...auditAlteracao(usuarioId),
    },
    include: horarioInclude,
  });
}

export async function deleteHorario(id: string) {
  const existing = await prisma.voluntarioDepartamentoHorario.findUnique({
    where: { id },
    include: horarioInclude,
  });
  if (!existing) return null;

  await prisma.voluntarioDepartamentoHorario.delete({ where: { id } });
  return existing;
}

export async function countHorariosPorDepartamentoCodigo(
  departamentoCodigo: number,
) {
  return prisma.voluntarioDepartamentoHorario.count({
    where: { departamentoCodigo },
  });
}

export class VoluntarioDepartamentoHorarioReferenciaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "VoluntarioDepartamentoHorarioReferenciaError";
  }
}

export function mapVoluntarioDepartamentoHorario(h: HorarioComRelacoes, usuarios?: UsuarioAuditoriaMap) {
  return {
    id: h.id,
    voluntarioId: h.voluntarioId,
    voluntarioCodigo: h.voluntario.codigo,
    voluntarioNome: h.voluntario.nome,
    voluntarioNomeCracha: h.voluntario.nomeCracha,
    departamentoCodigo: h.departamentoCodigo,
    departamentoDescricao: h.departamento.descricao,
    diaSemana: h.diaSemana,
    diaSemanaRotulo: rotuloDiaSemana(h.diaSemana),
    horaInicio: formatHora(h.horaInicio),
    horaTermino: formatHora(h.horaTermino),
    ...mapAuditoria(h, usuarios),
  };
}
