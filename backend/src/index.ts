import cors from "@fastify/cors";
import jwt from "@fastify/jwt";
import Fastify from "fastify";

import { authPluginRegistered } from "./plugins/auth.js";

import { ensureAdminUser, syncModulos, syncProgramas } from "./lib/sync-bootstrap.js";

import { authRoutes } from "./routes/auth.js";
import { bairrosRoutes } from "./routes/bairros.js";
import { departamentosRoutes } from "./routes/departamentos.js";
import { cursosRoutes } from "./routes/cursos.js";
import { turmasRoutes } from "./routes/turmas.js";
import { alunosRoutes } from "./routes/alunos.js";
import { inscricaoAtendimentosRoutes } from "./routes/inscricao-atendimentos.js";
import { inscricoesRoutes } from "./routes/inscricoes.js";
import { voluntariosRoutes } from "./routes/voluntarios.js";
import { voluntarioDepartamentoHorariosRoutes } from "./routes/voluntario-departamento-horarios.js";
import { escolaridadesRoutes } from "./routes/escolaridades.js";
import { cidadesRoutes } from "./routes/cidades.js";

import { perguntasRoutes } from "./routes/perguntas.js";

import { pessoasRoutes } from "./routes/pessoas.js";

import { programasRoutes } from "./routes/programas.js";

import { entrevistasAssistidoRoutes } from "./routes/entrevistas-assistido.js";
import { submissoesRoutes } from "./routes/submissoes.js";

import { tiposFormularioRoutes } from "./routes/tipos-formulario.js";

import { tiposUsuarioRoutes } from "./routes/tipos-usuario.js";

import { modulosSistemaRoutes } from "./routes/modulos-sistema.js";
import { relatorioSubmodulosRoutes } from "./routes/relatorio-submodulos.js";

import { usuariosRoutes } from "./routes/usuarios.js";



const port = Number(process.env.PORT) || 3000;



const app = Fastify({ logger: true });



await app.register(cors, {

  origin: true,

  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],

  allowedHeaders: ["Content-Type", "Authorization"],

});

await app.register(jwt, {
  secret: process.env.JWT_SECRET ?? "cefa-dev-secret-change-in-production",
});

await app.register(authPluginRegistered);

await app.register(authRoutes);

await app.register(tiposFormularioRoutes);

await app.register(perguntasRoutes);

await app.register(pessoasRoutes);
await app.register(cidadesRoutes);
await app.register(bairrosRoutes);
await app.register(escolaridadesRoutes);
await app.register(departamentosRoutes);
await app.register(cursosRoutes);
await app.register(turmasRoutes);
await app.register(alunosRoutes);
await app.register(inscricoesRoutes);
await app.register(inscricaoAtendimentosRoutes);
await app.register(voluntarioDepartamentoHorariosRoutes);
await app.register(voluntariosRoutes);

await app.register(submissoesRoutes);
await app.register(entrevistasAssistidoRoutes);

await app.register(tiposUsuarioRoutes);

await app.register(usuariosRoutes);

await app.register(programasRoutes);

await app.register(modulosSistemaRoutes);
await app.register(relatorioSubmodulosRoutes);



app.get("/health", async () => ({ status: "ok" }));



await syncModulos();

await syncProgramas();

await ensureAdminUser();



try {

  await app.listen({ port, host: "0.0.0.0" });

} catch (err) {

  app.log.error(err);

  process.exit(1);

}

