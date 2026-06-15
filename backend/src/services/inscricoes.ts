import { Prisma } from "@prisma/client";

import {

  auditAlteracao,

  auditInclusao,

  mapAuditoria,

  type UsuarioAuditoriaMap,

} from "../lib/auditoria.js";

import { formatDataBr } from "../lib/campo.js";

import { DeleteBlockedError } from "../lib/delete-guard.js";

import { formatCpf, normalizeCpf } from "../lib/cpf.js";

import { rotuloPeriodoInscricao } from "../lib/periodo-inscricao.js";

import { prisma } from "../lib/prisma.js";

import { assertTurmaCodigo } from "./turmas.js";

import type {

  CreateInscricaoInput,

} from "../validators/inscricoes.js";

import { parseDtCurso } from "../validators/inscricoes.js";



export type ListInscricoesFilters = {

  ativo?: boolean;

  codigo?: number;

  alunoId?: string;

  alunoNome?: string;

  alunoCpf?: string;

  turmaCodigo?: number;

  turmaNome?: string;

  cursoCodigo?: number;

  cursoDescricao?: string;

};



const inscricaoInclude = {

  aluno: { select: { id: true, nome: true, cpf: true } },

  turma: {

    select: {

      codigo: true,

      nome: true,

      periodo: true,

      curso: { select: { codigo: true, descricao: true } },

    },

  },

  rendaFamiliar: { orderBy: { ordem: "asc" as const } },

} satisfies Prisma.InscricaoAlunoCursoInclude;



type InscricaoComRelacoes = Prisma.InscricaoAlunoCursoGetPayload<{

  include: typeof inscricaoInclude;

}>;



const TX_OPTS = {

  maxWait: 10_000,

  timeout: 60_000,

} as const;



async function nextInscricaoCodigo(): Promise<number> {

  const result = await prisma.inscricaoAlunoCurso.aggregate({

    _max: { codigo: true },

  });

  return (result._max.codigo ?? 0) + 1;

}



async function assertAlunoAtivo(alunoId: string) {

  const aluno = await prisma.aluno.findUnique({ where: { id: alunoId } });

  if (!aluno) {

    throw new InscricaoReferenciaError("Aluno não encontrado");

  }

  if (!aluno.ativo) {

    throw new InscricaoReferenciaError("Aluno inativo não pode ser utilizado");

  }

  return aluno;

}



function dadosCondicionaisFromInput(

  data: Pick<

    CreateInscricaoInput,

    | "jaFezCursoSenacSenai"

    | "cursoSenacSenaiDescricao"

    | "possuiEncaminhamento"

    | "orgaoEncaminhamento"

    | "telefoneEncaminhamento"

    | "possuiNecessidadeEspecial"

    | "qualNecessidade"

    | "fazAcompanhamentoMedico"

    | "tomaMedicacao"

    | "quaisMedicacoes"

    | "vacinacao"

    | "alergias"

  >,

) {

  const jaFez = data.jaFezCursoSenacSenai ?? false;

  const encaminhamento = data.possuiEncaminhamento ?? false;

  const necessidade = data.possuiNecessidadeEspecial ?? false;

  const acompanhamento = data.fazAcompanhamentoMedico ?? false;

  const tomaMed = data.tomaMedicacao ?? false;



  return {

    jaFezCursoSenacSenai: jaFez,

    cursoSenacSenaiDescricao: jaFez

      ? (data.cursoSenacSenaiDescricao ?? null)

      : null,

    possuiEncaminhamento: encaminhamento,

    orgaoEncaminhamento: encaminhamento

      ? (data.orgaoEncaminhamento ?? null)

      : null,

    telefoneEncaminhamento: encaminhamento

      ? (data.telefoneEncaminhamento ?? null)

      : null,

    possuiNecessidadeEspecial: necessidade,

    qualNecessidade: necessidade ? (data.qualNecessidade ?? null) : null,

    fazAcompanhamentoMedico: acompanhamento,

    tomaMedicacao: tomaMed,

    quaisMedicacoes: tomaMed ? (data.quaisMedicacoes ?? null) : null,

    vacinacao: data.vacinacao ?? null,

    alergias: data.alergias ?? null,

  };

}



function dadosPrismaFromInput(data: CreateInscricaoInput) {

  return {

    alunoId: data.alunoId,

    turmaCodigo: data.turmaCodigo,

    dtCurso: parseDtCurso(data.dtCurso)!,

    ...dadosCondicionaisFromInput(data),

  };

}



async function salvarRendaFamiliar(

  tx: Prisma.TransactionClient,

  inscricaoId: string,

  items: CreateInscricaoInput["rendaFamiliar"] | undefined,

  usuarioId: string,

) {

  await tx.inscricaoRendaFamiliar.deleteMany({ where: { inscricaoId } });



  const rows = items ?? [];

  if (rows.length === 0) return;



  await tx.inscricaoRendaFamiliar.createMany({

    data: rows.map((item, index) => ({

      inscricaoId,

      ordem: index,

      nome: item.nome.trim(),

      idade: item.idade ?? null,

      renda: new Prisma.Decimal(item.renda ?? 0),

      parentesco: item.parentesco ?? null,

      profissao: item.profissao ?? null,

      ...auditInclusao(usuarioId),

    })),

  });

}



export async function listInscricoes(filters: ListInscricoesFilters = {}) {

  const where: Prisma.InscricaoAlunoCursoWhereInput = {};



  if (filters.ativo !== undefined) {

    where.ativo = filters.ativo;

  }



  if (filters.codigo !== undefined) {

    where.codigo = filters.codigo;

  }



  const alunoNome = filters.alunoNome?.trim();

  const cpfDigits = filters.alunoCpf ? normalizeCpf(filters.alunoCpf) : "";

  const turmaNome = filters.turmaNome?.trim();

  const cursoDescricao = filters.cursoDescricao?.trim();



  if (filters.alunoId) {

    where.alunoId = filters.alunoId;

  } else if (alunoNome || cpfDigits.length > 0) {

    where.aluno = {

      ...(alunoNome && { nome: { contains: alunoNome, mode: "insensitive" } }),

      ...(cpfDigits.length > 0 && { cpf: { contains: cpfDigits } }),

    };

  }



  if (filters.turmaCodigo !== undefined) {

    where.turmaCodigo = filters.turmaCodigo;

  }



  const turmaFilter: Prisma.TurmaWhereInput = {};

  if (filters.cursoCodigo !== undefined) {

    turmaFilter.curso = { codigo: filters.cursoCodigo };

  } else if (cursoDescricao) {

    turmaFilter.curso = {

      descricao: { contains: cursoDescricao, mode: "insensitive" },

    };

  }

  if (filters.turmaCodigo === undefined && turmaNome) {

    turmaFilter.nome = { contains: turmaNome, mode: "insensitive" };

  }

  if (Object.keys(turmaFilter).length > 0) {

    where.turma = turmaFilter;

  }



  const rows = await prisma.inscricaoAlunoCurso.findMany({

    where,

    include: {

      aluno: { select: { id: true, nome: true, cpf: true } },

      turma: {

        select: {

          codigo: true,

          nome: true,

          periodo: true,

          curso: { select: { codigo: true, descricao: true } },

        },

      },

    },

    orderBy: [{ codigo: "desc" }],

  });



  return rows.map(mapInscricaoLista);

}



export async function getInscricaoById(id: string) {

  return prisma.inscricaoAlunoCurso.findUnique({

    where: { id },

    include: inscricaoInclude,

  });

}



export async function createInscricao(

  data: CreateInscricaoInput,

  usuarioId: string,

) {

  await assertAlunoAtivo(data.alunoId);

  await assertTurmaCodigo(data.turmaCodigo, {

    somenteAtivo: true,

    somenteAberta: true,

  });



  const codigo = await nextInscricaoCodigo();



  return prisma.$transaction(async (tx) => {

    const inscricao = await tx.inscricaoAlunoCurso.create({

      data: {

        codigo,

        ...dadosPrismaFromInput(data),

        ativo: true,

        ...auditInclusao(usuarioId),

      },

    });



    await salvarRendaFamiliar(tx, inscricao.id, data.rendaFamiliar, usuarioId);



    const loaded = await tx.inscricaoAlunoCurso.findUnique({

      where: { id: inscricao.id },

      include: inscricaoInclude,

    });

    if (!loaded) {

      throw new InscricaoValidationError(

        "Falha ao carregar inscrição após o registro",

      );

    }

    return loaded;

  }, TX_OPTS);

}



export async function updateInscricao(

  id: string,

  data: CreateInscricaoInput,

  usuarioId: string,

) {

  const existing = await prisma.inscricaoAlunoCurso.findUnique({ where: { id } });

  if (!existing) return null;

  if (!existing.ativo) {

    throw new InscricaoInativaError(

      "Não é possível alterar uma inscrição desativada",

    );

  }



  await assertAlunoAtivo(data.alunoId);

  if (data.turmaCodigo !== existing.turmaCodigo) {

    await assertTurmaCodigo(data.turmaCodigo, {

      somenteAtivo: true,

      somenteAberta: true,

    });

  } else {

    await assertTurmaCodigo(data.turmaCodigo, { somenteAtivo: true });

  }



  return prisma.$transaction(async (tx) => {

    await tx.inscricaoAlunoCurso.update({

      where: { id },

      data: {

        ...dadosPrismaFromInput(data),

        ...auditAlteracao(usuarioId),

      },

    });



    await salvarRendaFamiliar(tx, id, data.rendaFamiliar, usuarioId);



    return tx.inscricaoAlunoCurso.findUnique({

      where: { id },

      include: inscricaoInclude,

    });

  }, TX_OPTS);

}



export async function desativarInscricao(id: string, usuarioId: string) {

  const existing = await prisma.inscricaoAlunoCurso.findUnique({ where: { id } });

  if (!existing) return null;

  if (!existing.ativo) {

    return getInscricaoById(id);

  }



  const totalAtendimentos = await prisma.inscricaoAtendimento.count({

    where: { inscricaoId: id },

  });

  if (totalAtendimentos > 0) {

    throw new DeleteBlockedError(

      "Não é possível desativar a inscrição — existem atendimentos vinculados",

    );

  }



  await prisma.inscricaoAlunoCurso.update({

    where: { id },

    data: {

      ativo: false,

      ...auditAlteracao(usuarioId),

    },

  });



  return getInscricaoById(id);

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



function calcularRendaPerCapita(

  items: { renda: Prisma.Decimal }[],

): number {

  if (items.length === 0) return 0;

  const total = items.reduce(

    (sum, item) => sum + Number(item.renda.toString()),

    0,

  );

  return total / items.length;

}



function mapRendaFamiliarItem(

  item: InscricaoComRelacoes["rendaFamiliar"][number],

) {

  const rendaNum = Number(item.renda.toString());

  return {

    id: item.id,

    ordem: item.ordem,

    nome: item.nome,

    idade: item.idade,

    renda: rendaNum,

    rendaFormatada: rendaNum.toLocaleString("pt-BR", {

      minimumFractionDigits: 2,

      maximumFractionDigits: 2,

    }),

    parentesco: item.parentesco,

    profissao: item.profissao,

  };

}



function mapTurmaResumo(

  turma: InscricaoComRelacoes["turma"],

) {

  return {

    turmaCodigo: turma.codigo,

    turmaNome: turma.nome,

    cursoCodigo: turma.curso.codigo,

    cursoDescricao: turma.curso.descricao,

    periodo: turma.periodo,

    periodoRotulo: rotuloPeriodoInscricao(turma.periodo),

  };

}



export function mapInscricaoLista(

  row: Prisma.InscricaoAlunoCursoGetPayload<{

    include: {

      aluno: { select: { id: true; nome: true; cpf: true } };

      turma: {

        select: {

          codigo: true;

          nome: true;

          periodo: true;

          curso: { select: { codigo: true; descricao: true } };

        };

      };

    };

  }>,

) {

  return {

    id: row.id,

    codigo: row.codigo,

    alunoId: row.alunoId,

    alunoNome: row.aluno.nome,

    alunoCpf: row.aluno.cpf,

    alunoCpfFormatado: row.aluno.cpf ? formatCpf(row.aluno.cpf) : null,

    ...mapTurmaResumo(row.turma),

    dtCurso: formatDataBr(row.dtCurso),

    matriculado: row.matriculado,

    matriculaCancelada: row.matriculaCancelada,

    ativo: row.ativo,

  };

}



export function mapInscricao(

  row: InscricaoComRelacoes,

  usuarios?: UsuarioAuditoriaMap,

) {

  const usuarioMap = usuarios ?? new Map();



  const rendaItems = row.rendaFamiliar.map(mapRendaFamiliarItem);

  const rendaPerCapita = calcularRendaPerCapita(row.rendaFamiliar);



  return {

    id: row.id,

    codigo: row.codigo,

    alunoId: row.alunoId,

    alunoNome: row.aluno.nome,

    alunoCpf: row.aluno.cpf,

    alunoCpfFormatado: row.aluno.cpf ? formatCpf(row.aluno.cpf) : null,

    ...mapTurmaResumo(row.turma),

    dtCurso: formatDataBr(row.dtCurso),

    jaFezCursoSenacSenai: row.jaFezCursoSenacSenai,

    cursoSenacSenaiDescricao: row.cursoSenacSenaiDescricao,

    possuiEncaminhamento: row.possuiEncaminhamento,

    orgaoEncaminhamento: row.orgaoEncaminhamento,

    telefoneEncaminhamento: row.telefoneEncaminhamento,

    telefoneEncaminhamentoFormatado: formatTelefoneExibicao(

      row.telefoneEncaminhamento,

    ),

    possuiNecessidadeEspecial: row.possuiNecessidadeEspecial,

    qualNecessidade: row.qualNecessidade,

    fazAcompanhamentoMedico: row.fazAcompanhamentoMedico,

    tomaMedicacao: row.tomaMedicacao,

    quaisMedicacoes: row.quaisMedicacoes,

    vacinacao: row.vacinacao,

    alergias: row.alergias,

    rendaFamiliar: rendaItems,

    rendaPerCapita,

    rendaPerCapitaFormatada: rendaPerCapita.toLocaleString("pt-BR", {

      minimumFractionDigits: 2,

      maximumFractionDigits: 2,

    }),

    matriculado: row.matriculado,

    matriculaCancelada: row.matriculaCancelada,

    dtInicioCurso:

      row.dtInicioCurso != null ? formatDataBr(row.dtInicioCurso) : null,

    usuarioMatriculaId: row.usuarioMatriculaId,

    dataHoraMatricula: row.dataHoraMatricula?.toISOString() ?? null,

    usuarioCancelamentoMatriculaId: row.usuarioCancelamentoMatriculaId,

    dataHoraCancelamentoMatricula:
      row.dataHoraCancelamentoMatricula?.toISOString() ?? null,

    ativo: row.ativo,

    ...mapAuditoria(row, usuarioMap),

  };

}



export class InscricaoReferenciaError extends Error {

  constructor(message: string) {

    super(message);

    this.name = "InscricaoReferenciaError";

  }

}



export class InscricaoInativaError extends Error {

  constructor(message: string) {

    super(message);

    this.name = "InscricaoInativaError";

  }

}



export class InscricaoValidationError extends Error {

  constructor(message: string) {

    super(message);

    this.name = "InscricaoValidationError";

  }

}

