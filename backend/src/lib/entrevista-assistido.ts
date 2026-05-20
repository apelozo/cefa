import { FormaAcessoInstituicao } from "@prisma/client";

export const FORMAS_ACESSO_INSTITUICAO = [
  "DEMANDA_ESPONTANEA",
  "BUSCA_ATIVA",
  "ENCAMINHAMENTO_ASSISTENCIA_SOCIAL",
  "ENCAMINHAMENTO_SAUDE",
  "ENCAMINHAMENTO_EDUCACAO",
  "ENCAMINHAMENTO_CONSELHO_TUTELAR",
  "ENCAMINHAMENTO_GARANTIA_DIREITOS",
  "OUTROS",
] as const satisfies readonly FormaAcessoInstituicao[];

export const ROTULO_FORMA_ACESSO: Record<FormaAcessoInstituicao, string> = {
  DEMANDA_ESPONTANEA: "Por Demanda Espontânea",
  BUSCA_ATIVA: "Busca Ativa Realizada",
  ENCAMINHAMENTO_ASSISTENCIA_SOCIAL: "Encaminhamento da Assistência Social",
  ENCAMINHAMENTO_SAUDE: "Encaminhamento da Saúde",
  ENCAMINHAMENTO_EDUCACAO: "Encaminhamento da Educação",
  ENCAMINHAMENTO_CONSELHO_TUTELAR: "Encaminhamento do Conselho Tutelar",
  ENCAMINHAMENTO_GARANTIA_DIREITOS:
    "Encaminhamento Sistema de Garantia de Direitos",
  OUTROS: "Outros",
};
