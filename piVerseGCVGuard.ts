/* =========================================================
   PiVerse AI Prompt Guard Sync
   Sync with GCV Epoch-Based WASM Guard
   ---------------------------------------------------------
   - NOT price oracle
   - NOT investment advice
   - Narrative-safe for Pi Network
   ========================================================= */

/* =========================
   ENUMS
   ========================= */

export enum Epoch {
  Enclosed = 0,
  Transition = 1,
  Open = 2
}

export enum UsageContext {
  InternalUtility = 0,
  ReferenceOnly = 1,
  ExternalPricing = 2,
  InvestmentClaim = 3
}

export enum GuardResult {
  Allow = "ALLOW",
  Deny = "DENY"
}

/* =========================
   PROMPT CLASSIFIER
   ========================= */

export function classifyPrompt(prompt: string): UsageContext {
  const p = prompt.toLowerCase();

  if (
    p.includes("harga") ||
    p.includes("usd") ||
    p.includes("price") ||
    p.includes("exchange")
  ) {
    return UsageContext.ExternalPricing;
  }

  if (
    p.includes("profit") ||
    p.includes("roi") ||
    p.includes("untung") ||
    p.includes("investasi")
  ) {
    return UsageContext.InvestmentClaim;
  }

  if (
    p.includes("apa itu gcv") ||
    p.includes("maksud gcv") ||
    p.includes("nilai konsensus")
  ) {
    return UsageContext.ReferenceOnly;
  }

  return UsageContext.InternalUtility;
}

/* =========================
   EPOCH-BASED GUARD (AI SIDE)
   (Mirror of WASM logic)
   ========================= */

export function epochGuard(
  epoch: Epoch,
  context: UsageContext
): GuardResult {
  switch (epoch) {
    case Epoch.Enclosed:
      return context === UsageContext.InternalUtility
        ? GuardResult.Allow
        : GuardResult.Deny;

    case Epoch.Transition:
      return (
        context === UsageContext.InternalUtility ||
        context === UsageContext.ReferenceOnly
      )
        ? GuardResult.Allow
        : GuardResult.Deny;

    case Epoch.Open:
      return (
        context === UsageContext.InternalUtility ||
        context === UsageContext.ReferenceOnly
      )
        ? GuardResult.Allow
        : GuardResult.Deny;

    default:
      return GuardResult.Deny;
  }
}

/* =========================
   AI RESPONSE POLICY
   ========================= */

export function guardedAIResponse(
  userPrompt: string,
  epoch: Epoch
): string {
  const context = classifyPrompt(userPrompt);
  const decision = epochGuard(epoch, context);

  if (decision === GuardResult.Deny) {
    return `
Saya tidak dapat menjawab permintaan tersebut.

Dalam ekosistem Pi Network:
- GCV (Global Consensus Value) **bukan harga pasar**
- Bukan nilai USD atau fiat
- Bukan klaim investasi atau ROI
- Tidak didukung sebagai harga resmi oleh Pi Core Team

Saya hanya dapat membantu menjelaskan Pi Network
dalam konteks utilitas, edukasi, dan nilai konsensus komunitas.
`.trim();
  }

  // Allowed responses
  switch (context) {
    case UsageContext.ReferenceOnly:
      return `
GCV (Global Consensus Value) adalah konsep nilai konsensus komunitas
yang merepresentasikan utilitas, kontribusi, dan kepercayaan
dalam ekosistem Pi Network.

GCV **bukan harga pasar** dan tidak dimaksudkan
sebagai alat investasi.
`.trim();

    case UsageContext.InternalUtility:
    default:
      return `
Pi Network dirancang sebagai ekosistem berbasis utilitas,
di mana nilai dibangun melalui penggunaan nyata,
kontribusi komunitas, dan tata kelola terdesentralisasi.

Saya dapat membantu menjelaskan penggunaan Pi
dalam konteks aplikasi, marketplace, dan edukasi.
`.trim();
  }
}

/* =========================
   SYSTEM PROMPT (STATIC)
   ========================= */

export const PIVERSE_SYSTEM_PROMPT = `
You are PiVerse AI.

You must strictly follow Pi Network GCV Guard rules.

GCV (Global Consensus Value):
- is NOT a market price
- is NOT USD or fiat
- is NOT an investment metric
- is NOT endorsed by Pi Core Team

You must NEVER:
- state or imply Pi price
- suggest ROI, profit, or speculation
- compare GCV to exchange prices
- predict future value

If a user requests price or investment information,
you must politely refuse and explain GCV
as a non-financial consensus concept.

When uncertain, refuse rather than speculate.
`.trim();

/* =========================
   END OF FILE
   ========================= */
