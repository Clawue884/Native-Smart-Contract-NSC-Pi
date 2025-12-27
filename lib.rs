// =====================================================
// Pi Network - GCV Consensus Engine
// Epoch-Based Guarded WASM Contract
// =====================================================
//
// - NOT a price oracle
// - NOT a currency
// - NOT financial advice
// - Narrative-safe for Pi Network
//
// =====================================================

#![no_std]

extern crate alloc;

// =====================================================
// CONSTANTS
// =====================================================

/// Symbolic base value (scaled, non-fiat)
const BASE_GCV: u64 = 314_159;

/// Fixed-point scale
const SCALE: u64 = 1000;

// =====================================================
// ENUMS
// =====================================================

#[repr(u32)]
pub enum Epoch {
    Enclosed   = 0,
    Transition = 1,
    Open       = 2,
}

#[repr(u32)]
pub enum UsageContext {
    InternalUtility = 0,
    ReferenceOnly   = 1,
    ExternalPricing = 2,
    InvestmentClaim = 3,
}

#[repr(u32)]
pub enum GuardResult {
    Allow = 0,
    Flag  = 1,
    Deny  = 2,
}

// =====================================================
// STRUCT
// =====================================================

pub struct GCVFactors {
    pub utility: u32,
    pub network: u32,
    pub trust: u32,
    pub contribution: u32,
    pub governance: u32,
}

// =====================================================
// VALIDATION
// =====================================================

fn validate_factors(f: &GCVFactors) -> bool {
    let max = 1000;
    f.utility <= max &&
    f.network <= max &&
    f.trust <= max &&
    f.contribution <= max &&
    f.governance <= max
}

// =====================================================
// CORE CALCULATION
// =====================================================

fn compute_gcv(f: &GCVFactors) -> u64 {
    let mut value = BASE_GCV;

    value = value * f.utility as u64      / SCALE;
    value = value * f.network as u64      / SCALE;
    value = value * f.trust as u64        / SCALE;
    value = value * f.contribution as u64 / SCALE;
    value = value * f.governance as u64   / SCALE;

    value
}

// =====================================================
// EPOCH-BASED GCV GUARD
// =====================================================

fn epoch_guard(epoch: Epoch, context: UsageContext) -> GuardResult {
    match epoch {

        // 🔒 Enclosed Network
        Epoch::Enclosed => match context {
            UsageContext::InternalUtility => GuardResult::Allow,
            _ => GuardResult::Deny,
        },

        // 🔄 Transition Network
        Epoch::Transition => match context {
            UsageContext::InternalUtility => GuardResult::Allow,
            UsageContext::ReferenceOnly   => GuardResult::Allow,
            _ => GuardResult::Deny,
        },

        // 🌐 Open Network
        Epoch::Open => match context {
            UsageContext::InternalUtility => GuardResult::Allow,
            UsageContext::ReferenceOnly   => GuardResult::Allow,

            // ❌ STILL FORBIDDEN
            UsageContext::ExternalPricing |
            UsageContext::InvestmentClaim => GuardResult::Deny,
        },
    }
}

// =====================================================
// WASM ENTRYPOINT
// =====================================================

#[no_mangle]
pub extern "C" fn calculate_gcv_epoch_guarded(
    epoch_code: u32,
    context_code: u32,

    utility: u32,
    network: u32,
    trust: u32,
    contribution: u32,
    governance: u32,
) -> u64 {

    // Epoch decode
    let epoch = match epoch_code {
        0 => Epoch::Enclosed,
        1 => Epoch::Transition,
        2 => Epoch::Open,
        _ => return 0,
    };

    // Context decode
    let context = match context_code {
        0 => UsageContext::InternalUtility,
        1 => UsageContext::ReferenceOnly,
        2 => UsageContext::ExternalPricing,
        3 => UsageContext::InvestmentClaim,
        _ => return 0,
    };

    // Guard check
    if let GuardResult::Deny = epoch_guard(epoch, context) {
        return 0;
    }

    // Factor validation
    let factors = GCVFactors {
        utility,
        network,
        trust,
        contribution,
        governance,
    };

    if !validate_factors(&factors) {
        return 0;
    }

    // Compute symbolic GCV
    compute_gcv(&factors)
}

// =====================================================
// END
// =====================================================
