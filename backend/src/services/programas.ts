import { mapAuditoria } from "../lib/auditoria.js";
import { prisma } from "../lib/prisma.js";

export async function listProgramas() {
  return prisma.programa.findMany({
    orderBy: [{ nome: "asc" }],
    include: {
      moduloSistema: {
        select: { id: true, codigo: true, nome: true },
      },
    },
  });
}

export function mapPrograma(p: {
  id: string;
  codigo: string;
  nome: string;
  autoListagem: boolean;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
  moduloSistemaId?: string | null;
  moduloSistema?: { id: string; codigo: number; nome: string } | null;
}) {
  return {
    id: p.id,
    codigo: p.codigo,
    nome: p.nome,
    autoListagem: p.autoListagem,
    moduloSistemaId: p.moduloSistemaId ?? p.moduloSistema?.id ?? null,
    moduloCodigo: p.moduloSistema?.codigo ?? null,
    moduloNome: p.moduloSistema?.nome ?? null,
    ...mapAuditoria(p),
  };
}
