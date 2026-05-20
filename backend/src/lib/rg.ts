/** Remove pontuação e padroniza para busca/gravação (maiúsculas). */
export function normalizeRg(rg: string): string {
  return rg.replace(/[^a-zA-Z0-9]/g, "").toUpperCase();
}

/** Formata para exibição quando o RG tem 9 dígitos numéricos. */
export function formatRg(rg: string): string {
  const n = normalizeRg(rg);
  if (n.length === 9 && /^\d+$/.test(n)) {
    return `${n.slice(0, 2)}.${n.slice(2, 5)}.${n.slice(5, 8)}-${n.slice(8)}`;
  }
  return n;
}
