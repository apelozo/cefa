/** Idade em anos completos a partir de data de nascimento (UTC, coerente com @db.Date). */
export function calcularIdade(dtNascimento: Date, referencia: Date = new Date()): number {
  let age = referencia.getUTCFullYear() - dtNascimento.getUTCFullYear();
  const monthDiff = referencia.getUTCMonth() - dtNascimento.getUTCMonth();
  if (
    monthDiff < 0 ||
    (monthDiff === 0 && referencia.getUTCDate() < dtNascimento.getUTCDate())
  ) {
    age--;
  }
  return Math.max(0, age);
}
