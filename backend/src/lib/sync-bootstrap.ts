import bcrypt from "bcryptjs";

import { PerfilTipoUsuario } from "@prisma/client";

import { auditSistema } from "./auditoria.js";

import { MODULOS_CATALOGO } from "./modulos.js";

import { PROGRAMAS_CATALOGO } from "./programas.js";

import { prisma } from "./prisma.js";

/**
 * Garante que módulos do catálogo existam no banco (primeira instalação).
 * Não altera nome, descrição nem ordem de módulos já cadastrados — mudanças
 * feitas em "Módulos do sistema" na UI são preservadas ao reiniciar a API.
 */
export async function syncModulos() {
  for (const m of MODULOS_CATALOGO) {
    const existing = await prisma.moduloSistema.findFirst({
      where: { codigo: m.codigo },
    });
    if (existing) continue;

    await prisma.moduloSistema.create({
      data: {
        codigo: m.codigo,
        nome: m.nome,
        descricao: m.descricao ?? null,
        ordem: m.ordem,
        ativo: true,
        ...auditSistema(),
      },
    });
  }
}

/**
 * Garante que programas do catálogo existam no banco.
 * Em registros já existentes, atualiza apenas nome e autoListagem do catálogo.
 * O vínculo programa ↔ módulo (moduloSistemaId) definido na UI não é sobrescrito.
 * Submódulo de relatório: aplicado na criação ou quando ainda null (ex.: programa
 * criado após a migration que só faz UPDATE em linhas já existentes).
 */
export async function syncProgramas() {
  const modulos = await prisma.moduloSistema.findMany();
  const moduloPorCodigo = new Map(modulos.map((m) => [m.codigo, m.id]));

  const submodulos = await prisma.relatorioSubmodulo.findMany({
    where: { ativo: true },
    select: { id: true, codigo: true },
  });
  const submoduloIdPorCodigo = new Map(
    submodulos.map((s) => [s.codigo, s.id]),
  );

  for (const p of PROGRAMAS_CATALOGO) {
    const moduloSistemaId = moduloPorCodigo.get(p.moduloCodigo) ?? null;
    const audit = auditSistema();
    const relatorioSubmoduloIdPadrao = p.relatorioSubmoduloCodigo
      ? (submoduloIdPorCodigo.get(p.relatorioSubmoduloCodigo) ?? null)
      : null;

    const existing = await prisma.programa.findUnique({
      where: { codigo: p.codigo },
      select: { relatorioSubmoduloId: true },
    });

    const relatorioSubmoduloIdCreate = relatorioSubmoduloIdPadrao;
    const relatorioSubmoduloIdUpdate =
      relatorioSubmoduloIdPadrao && !existing?.relatorioSubmoduloId
        ? relatorioSubmoduloIdPadrao
        : undefined;

    await prisma.programa.upsert({
      where: { codigo: p.codigo },
      create: {
        codigo: p.codigo,
        nome: p.nome,
        autoListagem: p.autoListagem,
        moduloSistemaId,
        relatorioSubmoduloId: relatorioSubmoduloIdCreate,
        ...audit,
      },
      update: {
        nome: p.nome,
        autoListagem: p.autoListagem,
        ...(relatorioSubmoduloIdUpdate !== undefined && {
          relatorioSubmoduloId: relatorioSubmoduloIdUpdate,
        }),
      },
    });
  }
}

export async function ensureAdminUser() {
  const senha = process.env.ADMIN_INITIAL_PASSWORD ?? "admin123";

  const senhaHash = await bcrypt.hash(senha, 10);

  let tipoAdmin = await prisma.tipoUsuario.findFirst({
    where: { perfil: PerfilTipoUsuario.ADMINISTRADOR },
  });

  if (!tipoAdmin) {
    tipoAdmin = await prisma.tipoUsuario.create({
      data: {
        descricao: "Administrador",
        perfil: PerfilTipoUsuario.ADMINISTRADOR,
        ativo: true,
        ...auditSistema(),
      },
    });
  }

  const existing = await prisma.usuario.findUnique({
    where: { nomeUsuario: "admin" },
  });

  if (!existing) {
    const usuario = await prisma.usuario.create({
      data: {
        nomeUsuario: "admin",
        nome: "Administrador do Sistema",
        email: "admin@cefa.local",
        senhaHash,
        tipoUsuarioId: tipoAdmin.id,
        ativo: true,
        ...auditSistema(),
      },
    });

    await prisma.usuario.update({
      where: { id: usuario.id },
      data: {
        usuarioInclusaoId: usuario.id,
        usuarioAlteracaoId: usuario.id,
      },
    });
  }
}
