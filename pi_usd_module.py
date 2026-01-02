"""
Pi-USD Internal Settlement Module
---------------------------------
Purpose:
- Stable unit for Pi ecosystem commerce
- Merchant-safe pricing & settlement
- Closed-loop, KYC-bound
- Non-public, non-speculative

Status: Prototype / Reference Implementation
"""

from dataclasses import dataclass
from datetime import datetime
from typing import List


# =========================
# Core Data Structures
# =========================

@dataclass
class PiUSDState:
    total_minted: float = 0.0
    total_burned: float = 0.0
    circulating: float = 0.0
    daily_mint_limit: float = 1_000_000.0
    is_paused: bool = False


@dataclass
class Account:
    account_id: str
    pi_balance: float
    pi_usd_balance: float
    kyc_level: int
    is_merchant: bool = False


@dataclass
class ConversionWindow:
    rate_pi_to_usd: float
    min_pi: float
    max_pi: float
    start_time: datetime
    end_time: datetime


# =========================
# Utility
# =========================

def now() -> datetime:
    return datetime.utcnow()


def log_event(event: str, *args):
    print(f"[EVENT] {event} | {args}")


# =========================
# Core Module
# =========================

class PiUSDModule:
    def __init__(self):
        self.state = PiUSDState()

    # -------------------------
    # Rate Management
    # -------------------------

    @staticmethod
    def calculate_internal_rate(price_history: List[float]) -> float:
        """
        Simple moving average.
        No external oracle, no market feed.
        """
        if len(price_history) < 7:
            raise ValueError("Insufficient price history")
        return sum(price_history[-7:]) / 7

    # -------------------------
    # Mint: Pi → Pi-USD
    # -------------------------

    def convert_pi_to_pi_usd(
        self,
        account: Account,
        pi_amount: float,
        window: ConversionWindow
    ) -> float:
        assert not self.state.is_paused
        assert account.kyc_level >= 2
        assert window.start_time <= now() <= window.end_time
        assert window.min_pi <= pi_amount <= window.max_pi
        assert account.pi_balance >= pi_amount

        pi_usd_amount = pi_amount * window.rate_pi_to_usd

        if self.state.total_minted + pi_usd_amount > self.state.daily_mint_limit:
            raise ValueError("Daily mint limit exceeded")

        account.pi_balance -= pi_amount
        account.pi_usd_balance += pi_usd_amount

        self.state.total_minted += pi_usd_amount
        self.state.circulating += pi_usd_amount

        log_event("MINT_PI_USD", account.account_id, pi_usd_amount)
        return pi_usd_amount

    # -------------------------
    # Payment: Pi-USD Transfer
    # -------------------------

    @staticmethod
    def pay_merchant(
        payer: Account,
        merchant: Account,
        pi_usd_amount: float
    ):
        assert payer.pi_usd_balance >= pi_usd_amount
        assert merchant.is_merchant

        payer.pi_usd_balance -= pi_usd_amount
        merchant.pi_usd_balance += pi_usd_amount

        log_event(
            "PI_USD_PAYMENT",
            payer.account_id,
            merchant.account_id,
            pi_usd_amount
        )

    # -------------------------
    # Burn: Pi-USD → Pi
    # -------------------------

    def redeem_pi_usd(
        self,
        merchant: Account,
        pi_usd_amount: float,
        window: ConversionWindow
    ) -> float:
        assert merchant.is_merchant
        assert merchant.pi_usd_balance >= pi_usd_amount

        pi_amount = pi_usd_amount / window.rate_pi_to_usd

        merchant.pi_usd_balance -= pi_usd_amount
        merchant.pi_balance += pi_amount

        self.state.total_burned += pi_usd_amount
        self.state.circulating -= pi_usd_amount

        log_event("BURN_PI_USD", merchant.account_id, pi_usd_amount)
        return pi_amount

    # -------------------------
    # Risk & Governance
    # -------------------------

    def pause(self):
        self.state.is_paused = True
        log_event("PI_USD_PAUSED")

    def resume(self):
        self.state.is_paused = False
        log_event("PI_USD_RESUMED")

    def audit(self):
        assert abs(
            self.state.circulating
            - (self.state.total_minted - self.state.total_burned)
        ) < 1e-6
        log_event("PI_USD_AUDIT_OK")


# =========================
# End of Module
# =========================
