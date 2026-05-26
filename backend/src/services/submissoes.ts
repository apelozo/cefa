import { Prisma, TipoCampo } from "@prisma/client";
import { auditInclusao, mapAuditoria } from "../lib/auditoria.js";
import {
  formatDataBr,
  isRespostaVazia,
  validateValorForTipo,
} from "../lib/campo.js";
import { formatCpf, normalizeCpf } from "../lib/cpf.js";
import { prisma } from "../lib/prisma.js";
import type { CreateSubmissaoInput } from "../validators/submissoes.js";
import { assertUsuarioAcessoTipoFormulario } from "./tipos-formulario-acesso.js";

export class SubmissaoValidationError extends Error {
  constructor(
    message: string,
    public readonly details?: { perguntaId?: string }[],
  ) {
    super(message);
    this.name = "SubmissaoValidationError";
  }
}

export type ListSubmissoesFilters = {
  tipoFormularioId?: string;
  tipoFormularioIds?: string[];
  pessoaId?: string;
  nome?: string;
  cpf?: string;
};

export async function listSubmissoes(filters: ListSubmissoesFilters = {}) {
  const where: Prisma.SubmissaoWhereInput = {};

  if (filters.tipoFormularioId) {
    where.tipoFormularioId = filters.tipoFormularioId;
  } else if (filters.tipoFormularioIds) {
    if (filters.tipoFormularioIds.length === 0) {
      return [];
    }
    where.tipoFormularioId = { in: filters.tipoFormularioIds };
  }
  if (filters.pessoaId) {
    where.pessoaId = filters.pessoaId;
  }

  const nome = filters.nome?.trim();
  const cpfDigits = filters.cpf ? normalizeCpf(filters.cpf) : "";
  if (nome || cpfDigits.length > 0) {
    const pessoaWhere: Prisma.PessoaWhereInput = {};
    if (nome) {
      pessoaWhere.nome = { contains: nome, mode: "insensitive" };
    }
    if (cpfDigits.length > 0) {
      pessoaWhere.cpf = { contains: cpfDigits };
    }
    where.pessoa = pessoaWhere;
  }

  return prisma.submissao.findMany({
    where,
    include: {
      tipoFormulario: { select: { id: true, nome: true } },
      pessoa: { select: { id: true, nome: true, cpf: true } },
      _count: { select: { respostas: true } },
    },
    orderBy: { dataHoraInclusao: "desc" },
  });
}

export async function createSubmissao(
  input: CreateSubmissaoInput,
  usuarioId: string,
) {
  const respostasPreenchidas = input.respostas.filter((r) => !isRespostaVazia(r));

  const perguntaIds = respostasPreenchidas.map((r) => r.perguntaId);
  const uniqueIds = new Set(perguntaIds);
  if (uniqueIds.size !== perguntaIds.length) {
    throw new SubmissaoValidationError(
      "Não é permitido repetir a mesma pergunta na submissão",
    );
  }

  const perguntas =
    perguntaIds.length > 0
      ? await prisma.pergunta.findMany({
          where: { id: { in: perguntaIds } },
          include: { opcoes: true },
        })
      : [];

  if (perguntas.length !== perguntaIds.length) {
    const found = new Set(perguntas.map((p) => p.id));
    const missing = perguntaIds.filter((id) => !found.has(id));
    throw new SubmissaoValidationError("Pergunta não encontrada", [
      { perguntaId: missing[0] },
    ]);
  }

  const tipoFormulario = await prisma.tipoFormulario.findUnique({
    where: { id: input.tipoFormularioId },
  });
  if (!tipoFormulario) {
    throw new SubmissaoValidationError("Tipo de formulário não encontrado");
  }
  if (!tipoFormulario.ativo) {
    throw new SubmissaoValidationError("Tipo de formulário inativo");
  }

  await assertUsuarioAcessoTipoFormulario(usuarioId, input.tipoFormularioId);

  const pessoa = await prisma.pessoa.findUnique({
    where: { id: input.pessoaId },
  });
  if (!pessoa) {
    throw new SubmissaoValidationError("Assistido não encontrado");
  }
  if (!pessoa.ativo) {
    throw new SubmissaoValidationError("Assistido inativo");
  }

  const perguntaMap = new Map(perguntas.map((p) => [p.id, p]));
  const parsedRespostas: Array<{
    perguntaId: string;
    valorInteiro: number | null;
    valorDecimal: Prisma.Decimal | null;
    valorTexto: string | null;
    valorLogico: boolean | null;
    valorData: Date | null;
    valorOpcaoId: string | null;
  }> = [];

  for (const item of respostasPreenchidas) {
    const pergunta = perguntaMap.get(item.perguntaId)!;
    if (pergunta.tipoFormularioId !== input.tipoFormularioId) {
      throw new SubmissaoValidationError(
        "Pergunta não pertence ao tipo de formulário informado",
        [{ perguntaId: item.perguntaId }],
      );
    }
    if (!pergunta.ativo) {
      throw new SubmissaoValidationError(
        "Pergunta inativa não aceita novas respostas",
        [{ perguntaId: item.perguntaId }],
      );
    }
    try {
      const valores = validateValorForTipo(
        pergunta.tipoCampo,
        pergunta.tamanhoCampo,
        item,
      );

      if (pergunta.tipoCampo === TipoCampo.LISTA) {
        const opcaoId = valores.valorOpcaoId!;
        const opcao = pergunta.opcoes.find((o) => o.id === opcaoId);
        if (!opcao) {
          throw new Error("Opção inválida para esta pergunta");
        }
        if (!opcao.ativo) {
          throw new Error("Opção inativa não pode ser selecionada");
        }
      }

      parsedRespostas.push({ perguntaId: item.perguntaId, ...valores });
    } catch (err) {
      throw new SubmissaoValidationError(
        err instanceof Error ? err.message : "Valor inválido",
        [{ perguntaId: item.perguntaId }],
      );
    }
  }

  const inclusao = auditInclusao(usuarioId);

  return prisma.$transaction(async (tx) => {
    const submissao = await tx.submissao.create({
      data: {
        tipoFormularioId: input.tipoFormularioId,
        pessoaId: input.pessoaId,
        ...inclusao,
      },
    });

    await tx.resposta.createMany({
      data: parsedRespostas.map((r) => ({
        submissaoId: submissao.id,
        perguntaId: r.perguntaId,
        valorInteiro: r.valorInteiro,
        valorDecimal: r.valorDecimal,
        valorTexto: r.valorTexto,
        valorLogico: r.valorLogico,
        valorData: r.valorData,
        valorOpcaoId: r.valorOpcaoId,
        ...inclusao,
      })),
    });

    return tx.submissao.findUniqueOrThrow({
      where: { id: submissao.id },
      include: {
        tipoFormulario: { select: { id: true, nome: true } },
        pessoa: { select: { id: true, nome: true, cpf: true } },
        respostas: {
          include: { pergunta: true, valorOpcao: true },
          orderBy: { pergunta: { ordem: "asc" } },
        },
      },
    });
  });
}

export async function getSubmissaoById(id: string) {
  return prisma.submissao.findUnique({
    where: { id },
    include: {
      tipoFormulario: { select: { id: true, nome: true } },
      pessoa: { select: { id: true, nome: true, cpf: true } },
      respostas: {
        include: { pergunta: true, valorOpcao: true },
        orderBy: { pergunta: { ordem: "asc" } },
      },
    },
  });
}

function mapValorResposta(r: {
  valorInteiro: number | null;
  valorDecimal: { toString: () => string } | null;
  valorTexto: string | null;
  valorLogico: boolean | null;
  valorData: Date | null;
  valorOpcaoId: string | null;
  valorOpcao?: { id: string; rotulo: string; ativo: boolean } | null;
}) {
  return {
    valorInteiro: r.valorInteiro,
    valorDecimal: r.valorDecimal?.toString() ?? null,
    valorTexto: r.valorTexto,
    valorLogico: r.valorLogico,
    valorData: r.valorData ? formatDataBr(r.valorData) : null,
    valorOpcaoId: r.valorOpcaoId,
    opcao: r.valorOpcao
      ? {
          id: r.valorOpcao.id,
          rotulo: r.valorOpcao.rotulo,
          ativo: r.valorOpcao.ativo,
        }
      : null,
  };
}

export function mapSubmissaoResumo(submissao: {
  id: string;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
  tipoFormularioId: string;
  pessoaId: string;
  tipoFormulario?: { id: string; nome: string };
  pessoa?: { id: string; nome: string; cpf: string };
  _count?: { respostas: number };
}) {
  return {
    id: submissao.id,
    ...mapAuditoria(submissao),
    tipoFormularioId: submissao.tipoFormularioId,
    pessoaId: submissao.pessoaId,
    tipoFormulario: submissao.tipoFormulario,
    pessoa: submissao.pessoa
      ? {
          id: submissao.pessoa.id,
          nome: submissao.pessoa.nome,
          cpf: submissao.pessoa.cpf,
          cpfFormatado: formatCpf(submissao.pessoa.cpf),
        }
      : undefined,
    totalRespostas: submissao._count?.respostas ?? 0,
  };
}

export function mapSubmissao(submissao: {
  id: string;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
  tipoFormularioId: string;
  pessoaId: string;
  tipoFormulario?: { id: string; nome: string };
  pessoa?: { id: string; nome: string; cpf: string };
  respostas: Array<{
    id: string;
    perguntaId: string;
    valorInteiro: number | null;
    valorDecimal: { toString: () => string } | null;
    valorTexto: string | null;
    valorLogico: boolean | null;
    valorData: Date | null;
    valorOpcaoId: string | null;
    valorOpcao?: { id: string; rotulo: string; ativo: boolean } | null;
    pergunta: {
      id: string;
      enunciado: string;
      tipoCampo: TipoCampo;
      tamanhoCampo: number | null;
      ordem: number;
    };
  }>;
}) {
  return {
    id: submissao.id,
    ...mapAuditoria(submissao),
    tipoFormularioId: submissao.tipoFormularioId,
    pessoaId: submissao.pessoaId,
    tipoFormulario: submissao.tipoFormulario,
    pessoa: submissao.pessoa
      ? {
          id: submissao.pessoa.id,
          nome: submissao.pessoa.nome,
          cpf: submissao.pessoa.cpf,
          cpfFormatado: formatCpf(submissao.pessoa.cpf),
        }
      : undefined,
    respostas: submissao.respostas.map((r) => ({
      id: r.id,
      perguntaId: r.perguntaId,
      ...mapValorResposta(r),
      pergunta: {
        id: r.pergunta.id,
        enunciado: r.pergunta.enunciado,
        tipoCampo: r.pergunta.tipoCampo,
        tamanhoCampo: r.pergunta.tamanhoCampo,
        ordem: r.pergunta.ordem,
      },
    })),
  };
}
