export type ModuloDef = {
  codigo: number;
  nome: string;
  descricao?: string;
  ordem: number;
};

export const MODULOS_CATALOGO: ModuloDef[] = [
  {
    codigo: 1,
    nome: "Formulários",
    descricao: "Cadastros, lançamento e consulta de respostas",
    ordem: 1,
  },
  {
    codigo: 2,
    nome: "Administração",
    descricao: "Usuários, permissões e configuração do sistema",
    ordem: 2,
  },
];
