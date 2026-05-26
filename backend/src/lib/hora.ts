/** Converte `HH:mm` ou `HH:mm:ss` para Date compatível com `@db.Time`. */
export function parseHora(value: string): Date {
  const trimmed = value.trim();
  const match = trimmed.match(/^(\d{1,2}):(\d{2})(?::(\d{2}))?$/);
  if (!match) {
    throw new Error("Hora inválida. Use o formato HH:mm");
  }
  const hours = Number.parseInt(match[1]!, 10);
  const minutes = Number.parseInt(match[2]!, 10);
  if (hours > 23 || minutes > 59) {
    throw new Error("Hora inválida");
  }
  return new Date(Date.UTC(1970, 0, 1, hours, minutes, 0));
}

export function formatHora(date: Date): string {
  const h = date.getUTCHours().toString().padStart(2, "0");
  const m = date.getUTCMinutes().toString().padStart(2, "0");
  return `${h}:${m}`;
}

export function minutosDesdeMeiaNoite(date: Date): number {
  return date.getUTCHours() * 60 + date.getUTCMinutes();
}

export function validarIntervaloHorario(inicio: Date, termino: Date): void {
  if (minutosDesdeMeiaNoite(termino) <= minutosDesdeMeiaNoite(inicio)) {
    throw new Error("Hora término deve ser posterior à hora início");
  }
}
