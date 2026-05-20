import { Prisma, TipoCampo } from "@prisma/client";
import { auditAlteracao, auditInclusao, mapAuditoria } from "../lib/auditoria.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { prisma } from "../lib/prisma.js";
import type {
  CreatePerguntaInput,
  OpcaoPerguntaInput,
  UpdatePerguntaInput,
} from "../validators/perguntas.js";

const includeTipoFormulario = {
  tipoFormulario: {
    select: { id: true, nome: true },
  },
};

const opcoesOrderBy: Prisma.PerguntaOpcaoOrderByWithRelationInput[] = [
  { ordem: "asc" },
  { dataHoraInclusao: "asc" },
];

const includeOpcoes = {
  opcoes: {
    orderBy: opcoesOrderBy,
  },
};

export async function listPerguntas(filters?: {
  ativo?: boolean;
  tipoFormularioId?: string;
  opcoesAtivas?: boolean;
}) {
  return prisma.pergunta.findMany({
    where: {
      ...(filters?.ativo !== undefined && { ativo: filters.ativo }),
      ...(filters?.tipoFormularioId && {
        tipoFormularioId: filters.tipoFormularioId,
      }),
    },
    include: {
      ...includeTipoFormulario,
      opcoes: {
        where: filters?.opcoesAtivas ? { ativo: true } : undefined,
        orderBy: [{ ordem: "asc" }, { dataHoraInclusao: "asc" }],
      },
    },
    orderBy: [{ ordem: "asc" }, { dataHoraInclusao: "asc" }],
  });
}

export async function getPerguntaById(id: string) {
  return prisma.pergunta.findUnique({
    where: { id },
    include: {
      ...includeTipoFormulario,
      ...includeOpcoes,
    },
  });
}

async function assertOrdemUnica(
  tipoFormularioId: string,
  ordem: number,
  excludePerguntaId?: string,
) {
  const existing = await prisma.pergunta.findFirst({
    where: {
      tipoFormularioId,
      ordem,
      ...(excludePerguntaId ? { id: { not: excludePerguntaId } } : {}),
    },
    select: { id: true },
  });
  if (existing) {
    throw new OrdemDuplicadaError();
  }
}

export async function getProximaOrdem(tipoFormularioId: string) {
  const result = await prisma.pergunta.aggregate({
    where: { tipoFormularioId },
    _max: { ordem: true },
  });
  return (result._max.ordem ?? -1) + 1;
}

async function assertTipoFormularioExists(id: string) {
  const tipo = await prisma.tipoFormulario.findUnique({ where: { id } });
  if (!tipo) {
    throw new TipoFormularioNaoEncontradoError();
  }
  if (!tipo.ativo) {
    throw new TipoFormularioInativoError();
  }
}

async function assertOpcoesListaValidas(opcoes: OpcaoPerguntaInput[]) {
  const ativas = opcoes.filter((o) => o.ativo !== false);
  if (opcoes.length === 0 || ativas.length === 0) {
    throw new OpcoesListaInvalidasError();
  }
}

async function syncOpcoes(
  perguntaId: string,
  opcoes: OpcaoPerguntaInput[],
  tx: Prisma.TransactionClient,
  usuarioId: string,
) {
  await assertOpcoesListaValidas(opcoes);

  const existing = await tx.perguntaOpcao.findMany({
    where: { perguntaId },
    select: { id: true },
  });
  const existingIds = new Set(existing.map((o) => o.id));

  for (const [index, opcao] of opcoes.entries()) {
    const ordem = opcao.ordem ?? index;
    if (opcao.id) {
      if (!existingIds.has(opcao.id)) {
        throw new OpcaoNaoEncontradaError();
      }
      await tx.perguntaOpcao.update({
        where: { id: opcao.id },
        data: {
          rotulo: opcao.rotulo,
          ordem,
          ativo: opcao.ativo ?? true,
          ...auditAlteracao(usuarioId),
        },
      });
    } else {
      await tx.perguntaOpcao.create({
        data: {
          perguntaId,
          rotulo: opcao.rotulo,
          ordem,
          ativo: opcao.ativo ?? true,
          ...auditInclusao(usuarioId),
        },
      });
    }
  }

  const merged = await tx.perguntaOpcao.findMany({ where: { perguntaId } });
  const ativas = merged.filter((o) => o.ativo);
  if (ativas.length === 0) {
    throw new OpcoesListaInvalidasError();
  }
}

export async function createPergunta(
  data: CreatePerguntaInput,
  usuarioId: string,
) {
  await assertTipoFormularioExists(data.tipoFormularioId);
  await assertOrdemUnica(data.tipoFormularioId, data.ordem);

  if (data.tipoCampo === "LISTA") {
    await assertOpcoesListaValidas(data.opcoes ?? []);
  }

  return prisma.$transaction(async (tx) => {
    const pergunta = await tx.pergunta.create({
      data: {
        enunciado: data.enunciado,
        tipoCampo: data.tipoCampo as TipoCampo,
        tamanhoCampo: data.tipoCampo === "TEXTO" ? data.tamanhoCampo! : null,
        linhasCampo: data.tipoCampo === "TEXTO" ? data.linhasCampo! : null,
        tipoFormularioId: data.tipoFormularioId,
        ordem: data.ordem,
        ativo: data.ativo,
        ...auditInclusao(usuarioId),
      },
    });

    if (data.tipoCampo === "LISTA" && data.opcoes) {
      await syncOpcoes(pergunta.id, data.opcoes, tx, usuarioId);
    }

    return tx.pergunta.findUniqueOrThrow({
      where: { id: pergunta.id },
      include: {
        ...includeTipoFormulario,
        ...includeOpcoes,
      },
    });
  });
}

export async function updatePergunta(
  id: string,
  data: UpdatePerguntaInput,
  usuarioId: string,
) {
  const existing = await prisma.pergunta.findUnique({
    where: { id },
    include: includeOpcoes,
  });
  if (!existing) return null;

  if (data.tipoFormularioId) {
    await assertTipoFormularioExists(data.tipoFormularioId);
  }

  const newTipo = data.tipoCampo ?? existing.tipoCampo;
  const tipoChanged =
    data.tipoCampo !== undefined && data.tipoCampo !== existing.tipoCampo;

  if (tipoChanged) {
    const hasAnswers = await prisma.resposta.count({
      where: { perguntaId: id },
    });
    if (hasAnswers > 0) {
      throw new TipoCampoImutavelError();
    }
  }

  if (newTipo === "LISTA" && data.opcoes) {
    await assertOpcoesListaValidas(data.opcoes);
  } else if (newTipo !== "LISTA" && data.opcoes) {
    throw new OpcoesListaInvalidasError(
      "opcoes só se aplica a perguntas do tipo LISTA",
    );
  }

  let tamanhoCampo: number | null | undefined = data.tamanhoCampo;
  if (data.tamanhoCampo === null) tamanhoCampo = null;
  if (data.tipoCampo !== undefined) {
    tamanhoCampo =
      newTipo === TipoCampo.TEXTO
        ? (data.tamanhoCampo ?? existing.tamanhoCampo)
        : null;
  } else if (
    data.tamanhoCampo !== undefined &&
    existing.tipoCampo !== TipoCampo.TEXTO
  ) {
    tamanhoCampo = null;
  }

  let linhasCampo: number | null | undefined = data.linhasCampo;
  if (data.linhasCampo === null) linhasCampo = null;
  if (data.tipoCampo !== undefined) {
    linhasCampo =
      newTipo === TipoCampo.TEXTO
        ? (data.linhasCampo ?? existing.linhasCampo)
        : null;
  } else if (
    data.linhasCampo !== undefined &&
    existing.tipoCampo !== TipoCampo.TEXTO
  ) {
    linhasCampo = null;
  }

  const tipoFormularioId =
    data.tipoFormularioId ?? existing.tipoFormularioId;
  const ordem = data.ordem ?? existing.ordem;
  await assertOrdemUnica(tipoFormularioId, ordem, id);

  return prisma.$transaction(async (tx) => {
    await tx.pergunta.update({
      where: { id },
      data: {
        ...(data.enunciado !== undefined && { enunciado: data.enunciado }),
        ...(data.tipoCampo !== undefined && {
          tipoCampo: data.tipoCampo as TipoCampo,
        }),
        ...(data.tipoFormularioId !== undefined && {
          tipoFormularioId: data.tipoFormularioId,
        }),
        ...(tamanhoCampo !== undefined && { tamanhoCampo }),
        ...(linhasCampo !== undefined && { linhasCampo }),
        ...(data.ordem !== undefined && { ordem: data.ordem }),
        ...(data.ativo !== undefined && { ativo: data.ativo }),
        ...auditAlteracao(usuarioId),
      },
    });

    if (newTipo === TipoCampo.LISTA && data.opcoes) {
      await syncOpcoes(id, data.opcoes, tx, usuarioId);
    }

    return tx.pergunta.findUniqueOrThrow({
      where: { id },
      include: {
        ...includeTipoFormulario,
        ...includeOpcoes,
      },
    });
  });
}

export async function deletePergunta(id: string) {
  const existing = await prisma.pergunta.findUnique({
    where: { id },
    include: includeTipoFormulario,
  });
  if (!existing) return null;

  const respostas = await prisma.resposta.count({ where: { perguntaId: id } });
  if (respostas > 0) {
    throw new DeleteBlockedError(
      "Não é possível excluir: existem respostas vinculadas a esta pergunta",
    );
  }

  await prisma.$transaction(async (tx) => {
    await tx.perguntaOpcao.deleteMany({ where: { perguntaId: id } });
    await tx.pergunta.delete({ where: { id } });
  });
  return existing;
}

export class TipoCampoImutavelError extends Error {
  constructor() {
    super(
      "Não é possível alterar o tipo do campo após existirem respostas para esta pergunta",
    );
    this.name = "TipoCampoImutavelError";
  }
}

export class TipoFormularioNaoEncontradoError extends Error {
  constructor() {
    super("Tipo de formulário não encontrado");
    this.name = "TipoFormularioNaoEncontradoError";
  }
}

export class TipoFormularioInativoError extends Error {
  constructor() {
    super("Tipo de formulário inativo");
    this.name = "TipoFormularioInativoError";
  }
}

export class OpcoesListaInvalidasError extends Error {
  constructor(message = "Informe ao menos uma opção ativa para tipo LISTA") {
    super(message);
    this.name = "OpcoesListaInvalidasError";
  }
}

export class OpcaoNaoEncontradaError extends Error {
  constructor() {
    super("Opção não encontrada para esta pergunta");
    this.name = "OpcaoNaoEncontradaError";
  }
}

export class OrdemDuplicadaError extends Error {
  constructor() {
    super(
      "Já existe outra pergunta com esta ordem neste tipo de formulário",
    );
    this.name = "OrdemDuplicadaError";
  }
}

export function mapOpcao(o: {
  id: string;
  rotulo: string;
  ordem: number;
  ativo: boolean;
}) {
  return {
    id: o.id,
    rotulo: o.rotulo,
    ordem: o.ordem,
    ativo: o.ativo,
  };
}

export function mapPergunta(
  p: {
    id: string;
    enunciado: string;
    tipoCampo: TipoCampo;
    tamanhoCampo: number | null;
    linhasCampo: number | null;
    tipoFormularioId: string;
    ordem: number;
    ativo: boolean;
    usuarioInclusaoId: string | null;
    dataHoraInclusao: Date;
    usuarioAlteracaoId: string | null;
    dataHoraAlteracao: Date | null;
  } & {
    tipoFormulario?: { id: string; nome: string };
    opcoes?: Array<{
      id: string;
      rotulo: string;
      ordem: number;
      ativo: boolean;
    }>;
  },
) {
  return {
    id: p.id,
    enunciado: p.enunciado,
    tipoCampo: p.tipoCampo,
    tamanhoCampo: p.tamanhoCampo,
    linhasCampo: p.linhasCampo,
    tipoFormularioId: p.tipoFormularioId,
    tipoFormulario: p.tipoFormulario
      ? { id: p.tipoFormulario.id, nome: p.tipoFormulario.nome }
      : undefined,
    ordem: p.ordem,
    ativo: p.ativo,
    opcoes: p.opcoes?.map(mapOpcao),
    ...mapAuditoria(p),
  };
}
