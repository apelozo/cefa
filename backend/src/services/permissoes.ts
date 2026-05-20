import { PerfilTipoUsuario } from "@prisma/client";
import type { AcaoPermissao } from "../lib/programas.js";
import { prisma } from "../lib/prisma.js";

export type PermissaoFlags = {
  podeIncluir: boolean;
  podeAlterar: boolean;
  podeConsultar: boolean;
  podeExcluir: boolean;
};

export type PermissaoMap = Record<string, PermissaoFlags>;

const TODAS_PERMITIDAS: PermissaoFlags = {
  podeIncluir: true,
  podeAlterar: true,
  podeConsultar: true,
  podeExcluir: true,
};

export async function loadUsuarioComTipo(usuarioId: string) {
  return prisma.usuario.findUnique({
    where: { id: usuarioId },
    include: { tipoUsuario: true },
  });
}

export async function buildPermissaoMap(usuarioId: string): Promise<PermissaoMap> {
  const usuario = await loadUsuarioComTipo(usuarioId);
  if (!usuario || !usuario.ativo) return {};

  const programas = await prisma.programa.findMany();
  const [permissoesTipo, permissoesUsuario] = await Promise.all([
    prisma.tipoUsuarioPermissao.findMany({
      where: { tipoUsuarioId: usuario.tipoUsuarioId },
    }),
    prisma.usuarioPermissao.findMany({ where: { usuarioId } }),
  ]);

  const tipoPorPrograma = new Map(
    permissoesTipo.map((p) => [p.programaId, p]),
  );
  const usuarioPorPrograma = new Map(
    permissoesUsuario.map((p) => [p.programaId, p]),
  );

  const isAdmin =
    usuario.tipoUsuario.perfil === PerfilTipoUsuario.ADMINISTRADOR;

  const map: PermissaoMap = {};
  for (const prog of programas) {
    if (isAdmin) {
      map[prog.codigo] = { ...TODAS_PERMITIDAS };
      continue;
    }

    const override = usuarioPorPrograma.get(prog.id);
    if (override) {
      map[prog.codigo] = {
        podeIncluir: override.podeIncluir,
        podeAlterar: override.podeAlterar,
        podeConsultar: override.podeConsultar,
        podeExcluir: override.podeExcluir,
      };
      continue;
    }

    const tipo = tipoPorPrograma.get(prog.id);
    if (tipo) {
      map[prog.codigo] = {
        podeIncluir: tipo.podeIncluir,
        podeAlterar: tipo.podeAlterar,
        podeConsultar: tipo.podeConsultar,
        podeExcluir: tipo.podeExcluir,
      };
    } else {
      map[prog.codigo] = {
        podeIncluir: false,
        podeAlterar: false,
        podeConsultar: false,
        podeExcluir: false,
      };
    }
  }

  return map;
}

export function temAcessoPrograma(
  map: PermissaoMap,
  codigoPrograma: string,
): boolean {
  const flags = map[codigoPrograma];
  if (!flags) return false;
  return (
    flags.podeIncluir ||
    flags.podeAlterar ||
    flags.podeConsultar ||
    flags.podeExcluir
  );
}

export function podeAcao(
  map: PermissaoMap,
  codigoPrograma: string,
  acao: AcaoPermissao,
): boolean {
  const flags = map[codigoPrograma];
  if (!flags) return false;
  switch (acao) {
    case "incluir":
      return flags.podeIncluir;
    case "alterar":
      return flags.podeAlterar;
    case "consultar":
      return flags.podeConsultar;
    case "excluir":
      return flags.podeExcluir;
  }
}

/** GET/listagem: qualquer permissão no programa permite visualizar. */
export function podeAcaoHttp(
  map: PermissaoMap,
  codigoPrograma: string,
  acao: AcaoPermissao,
): boolean {
  if (acao === "consultar") {
    return podeAcao(map, codigoPrograma, "consultar") || temAcessoPrograma(map, codigoPrograma);
  }
  return podeAcao(map, codigoPrograma, acao);
}

export async function usuarioPode(
  usuarioId: string,
  codigoPrograma: string,
  acao: AcaoPermissao,
): Promise<boolean> {
  const map = await buildPermissaoMap(usuarioId);
  return podeAcao(map, codigoPrograma, acao);
}

export function mapPermissaoFlags(p: PermissaoFlags) {
  return {
    podeIncluir: p.podeIncluir,
    podeAlterar: p.podeAlterar,
    podeConsultar: p.podeConsultar,
    podeExcluir: p.podeExcluir,
  };
}
