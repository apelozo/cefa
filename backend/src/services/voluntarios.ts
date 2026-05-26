import { Prisma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  mapAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { formatDataBr } from "../lib/campo.js";
import { formatCpf } from "../lib/cpf.js";
import { rotuloEstadoCivilVoluntario } from "../lib/estado-civil-voluntario.js";
import { prisma } from "../lib/prisma.js";
import { formatRg } from "../lib/rg.js";
import type {
  CreateVoluntarioInput,
  UpdateVoluntarioInput,
} from "../validators/voluntarios.js";
import { parseDtNascimentoVoluntario } from "../validators/voluntarios.js";

export type ListVoluntariosFilters = {
  ativo?: boolean;
  codigo?: number;
  /** Busca parcial em `nome` e `nomeCracha`. */
  nome?: string;
  /** @deprecated Use `nome` */
  nomeCracha?: string;
  empresa?: string;
  cpf?: string;
  /** Voluntários com ao menos um vínculo em `voluntario_departamento_horarios`. */
  departamentoCodigo?: number;
};

const voluntarioInclude = {
  cidade: { select: { codigo: true, nomeMunicipio: true, estado: true } },
} satisfies Prisma.VoluntarioInclude;

type VoluntarioComRelacoes = Prisma.VoluntarioGetPayload<{
  include: typeof voluntarioInclude;
}>;

async function nextVoluntarioCodigo(): Promise<number> {
  const result = await prisma.voluntario.aggregate({
    _max: { codigo: true },
  });
  return (result._max.codigo ?? 0) + 1;
}

async function validarCidade(cidadeCodigo?: number | null) {
  if (!cidadeCodigo) return;
  const cidade = await prisma.cidade.findUnique({
    where: { codigo: cidadeCodigo },
  });
  if (!cidade || !cidade.ativo) {
    throw new VoluntarioReferenciaError("Município inválido ou inativo");
  }
}

function dadosPrismaFromInput(
  data: CreateVoluntarioInput | UpdateVoluntarioInput,
) {
  return {
    ...(data.empresa !== undefined && { empresa: data.empresa }),
    ...(data.funcao !== undefined && { funcao: data.funcao }),
    ...(data.estadoCivil !== undefined && { estadoCivil: data.estadoCivil }),
    ...(data.dtNascimento !== undefined && {
      dtNascimento: parseDtNascimentoVoluntario(data.dtNascimento),
    }),
    ...(data.endereco !== undefined && { endereco: data.endereco }),
    ...(data.enderecoNumero !== undefined && {
      enderecoNumero: data.enderecoNumero,
    }),
    ...(data.bairro !== undefined && { bairro: data.bairro }),
    ...(data.cep !== undefined && { cep: data.cep }),
    ...(data.cidadeCodigo != null && {
      cidadeCodigo: data.cidadeCodigo,
    }),
    ...(data.enderecoComplemento !== undefined && {
      enderecoComplemento: data.enderecoComplemento,
    }),
    ...(data.rg !== undefined && { rg: data.rg }),
    ...(data.cpf !== undefined && { cpf: data.cpf }),
    ...(data.cnh !== undefined && { cnh: data.cnh }),
    ...(data.celular !== undefined && { celular: data.celular }),
    ...(data.telefoneResidencial !== undefined && {
      telefoneResidencial: data.telefoneResidencial,
    }),
    ...(data.telefoneComercial !== undefined && {
      telefoneComercial: data.telefoneComercial,
    }),
    ...(data.email !== undefined && { email: data.email }),
    ...(data.valorContribuicao !== undefined && {
      valorContribuicao:
        data.valorContribuicao === null
          ? null
          : new Prisma.Decimal(data.valorContribuicao),
    }),
    ...(data.diaVencimento !== undefined && {
      diaVencimento: data.diaVencimento,
    }),
    ...(data.tempoTrabalhoCentro !== undefined && {
      tempoTrabalhoCentro: data.tempoTrabalhoCentro,
    }),
    ...(data.nome !== undefined && { nome: data.nome }),
    ...(data.nomeCracha !== undefined && { nomeCracha: data.nomeCracha }),
    ...(data.fichaMedica !== undefined && { fichaMedica: data.fichaMedica }),
    ...("ativo" in data &&
      data.ativo !== undefined && { ativo: data.ativo }),
  };
}

export async function listVoluntarios(filters: ListVoluntariosFilters = {}) {
  const where: Prisma.VoluntarioWhereInput = {};

  if (filters.ativo !== undefined) {
    where.ativo = filters.ativo;
  }

  if (filters.codigo !== undefined) {
    where.codigo = filters.codigo;
  }

  const nomeBusca = (filters.nome ?? filters.nomeCracha)?.trim();
  if (nomeBusca) {
    where.OR = [
      { nome: { contains: nomeBusca, mode: "insensitive" } },
      { nomeCracha: { contains: nomeBusca, mode: "insensitive" } },
    ];
  }

  const empresa = filters.empresa?.trim();
  if (empresa) {
    where.empresa = { contains: empresa, mode: "insensitive" };
  }

  const cpfDigits = filters.cpf?.replace(/\D/g, "") ?? "";
  if (cpfDigits.length > 0) {
    where.cpf = { contains: cpfDigits };
  }

  if (filters.departamentoCodigo !== undefined) {
    where.departamentoHorarios = {
      some: { departamentoCodigo: filters.departamentoCodigo },
    };
  }

  return prisma.voluntario.findMany({
    where,
    include: voluntarioInclude,
    orderBy: [{ nome: "asc" }, { codigo: "asc" }],
  });
}

export async function getVoluntarioById(id: string) {
  return prisma.voluntario.findUnique({
    where: { id },
    include: voluntarioInclude,
  });
}

export async function createVoluntario(
  data: CreateVoluntarioInput,
  usuarioId: string,
) {
  await validarCidade(data.cidadeCodigo);
  const codigo = await nextVoluntarioCodigo();

  try {
    return await prisma.voluntario.create({
      data: {
        codigo,
        ativo: true,
        ...dadosPrismaFromInput(data),
        ...auditInclusao(usuarioId),
      } as Prisma.VoluntarioUncheckedCreateInput,
      include: voluntarioInclude,
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new VoluntarioConflictError("CPF já cadastrado");
    }
    throw err;
  }
}

export async function updateVoluntario(
  id: string,
  data: UpdateVoluntarioInput,
  usuarioId: string,
) {
  const existing = await prisma.voluntario.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo && data.ativo !== true) {
    throw new VoluntarioInativoError(
      "Não é possível alterar um voluntário desativado",
    );
  }

  const cidadeCodigo =
    data.cidadeCodigo !== undefined ? data.cidadeCodigo : existing.cidadeCodigo;
  await validarCidade(cidadeCodigo);

  try {
    return await prisma.voluntario.update({
      where: { id },
      data: {
        ...dadosPrismaFromInput(data),
        ...auditAlteracao(usuarioId),
      },
      include: voluntarioInclude,
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new VoluntarioConflictError("CPF já cadastrado");
    }
    throw err;
  }
}

/** Desativa (`ativo = false`) — registro permanece no banco. */
export async function desativarVoluntario(id: string, usuarioId: string) {
  const existing = await prisma.voluntario.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) {
    return getVoluntarioById(id);
  }

  return prisma.voluntario.update({
    where: { id },
    data: {
      ativo: false,
      ...auditAlteracao(usuarioId),
    },
    include: voluntarioInclude,
  });
}

export class VoluntarioConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "VoluntarioConflictError";
  }
}

export class VoluntarioInativoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "VoluntarioInativoError";
  }
}

export class VoluntarioReferenciaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "VoluntarioReferenciaError";
  }
}

function formatTelefoneExibicao(tel: string | null | undefined): string | null {
  if (!tel) return null;
  const d = tel.replace(/\D/g, "");
  if (d.length === 11) {
    return `(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}`;
  }
  if (d.length === 10) {
    return `(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}`;
  }
  return tel;
}

function formatCepExibicao(cep: string | null | undefined): string | null {
  if (!cep) return null;
  const d = cep.replace(/\D/g, "");
  if (d.length === 8) {
    return `${d.substring(0, 5)}-${d.substring(5)}`;
  }
  return cep;
}

export function mapVoluntario(v: VoluntarioComRelacoes, usuarios?: UsuarioAuditoriaMap) {
  return {
    id: v.id,
    codigo: v.codigo,
    empresa: v.empresa,
    funcao: v.funcao,
    estadoCivil: v.estadoCivil,
    estadoCivilRotulo: v.estadoCivil
      ? rotuloEstadoCivilVoluntario(v.estadoCivil)
      : null,
    dtNascimento: v.dtNascimento ? formatDataBr(v.dtNascimento) : null,
    endereco: v.endereco,
    enderecoNumero: v.enderecoNumero,
    bairro: v.bairro,
    cep: v.cep,
    cepFormatado: formatCepExibicao(v.cep),
    cidadeCodigo: v.cidadeCodigo,
    cidadeNome: v.cidade?.nomeMunicipio ?? null,
    cidadeEstado: v.cidade?.estado ?? null,
    enderecoComplemento: v.enderecoComplemento,
    rg: v.rg,
    rgFormatado: v.rg ? formatRg(v.rg) : null,
    cpf: v.cpf,
    cpfFormatado: v.cpf ? formatCpf(v.cpf) : null,
    cnh: v.cnh,
    celular: v.celular,
    celularFormatado: formatTelefoneExibicao(v.celular),
    telefoneResidencial: v.telefoneResidencial,
    telefoneResidencialFormatado: formatTelefoneExibicao(
      v.telefoneResidencial,
    ),
    telefoneComercial: v.telefoneComercial,
    telefoneComercialFormatado: formatTelefoneExibicao(v.telefoneComercial),
    email: v.email,
    valorContribuicao: v.valorContribuicao?.toString() ?? null,
    diaVencimento: v.diaVencimento,
    tempoTrabalhoCentro: v.tempoTrabalhoCentro,
    nome: v.nome,
    nomeCracha: v.nomeCracha,
    fichaMedica: v.fichaMedica,
    ativo: v.ativo,
    ...mapAuditoria(v, usuarios),
  };
}
