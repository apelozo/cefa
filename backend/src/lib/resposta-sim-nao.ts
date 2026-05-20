import { RespostaSimNao } from "@prisma/client";

export const RESPOSTAS_SIM_NAO = ["SIM", "NAO"] as const satisfies readonly RespostaSimNao[];

export const ROTULO_RESPOSTA_SIM_NAO: Record<RespostaSimNao, string> = {
  SIM: "Sim",
  NAO: "Não",
};
