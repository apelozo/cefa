import type { PrismaClient } from "@prisma/client";

/** Código do módulo **Relatórios** no catálogo (`modulos_sistema.codigo`). */
export const MODULO_RELATORIOS_CODIGO = 3;

type PrismaModuloReader = Pick<PrismaClient, "moduloSistema">;

export async function getModuloRelatoriosId(
  prisma: PrismaModuloReader,
): Promise<string | null> {
  const modulo = await prisma.moduloSistema.findFirst({
    where: { codigo: MODULO_RELATORIOS_CODIGO, ativo: true },
    select: { id: true },
  });
  return modulo?.id ?? null;
}

export async function isModuloRelatoriosId(
  prisma: PrismaModuloReader,
  moduloSistemaId: string | null | undefined,
): Promise<boolean> {
  if (!moduloSistemaId) return false;
  const modulo = await prisma.moduloSistema.findUnique({
    where: { id: moduloSistemaId },
    select: { codigo: true },
  });
  return modulo?.codigo === MODULO_RELATORIOS_CODIGO;
}
