# AAB Review — Phase 6: Network Installer (ai.incidium.net)

## Decision: CONDITIONAL APPROVAL

The architecture is sound — one PowerShell command, 1.4GB payload, 6-phase orchestration, zero physical media. The distinction between delivery mechanism and configuration is respected. However, two blocking conditions and several hardening items must be addressed before a machine in a conference venue runs code from a remote server.

---

## Blocking Condition 1 — Bootstrap Script Integrity

The bootstrap command fetches a remote script and executes it with full admin privileges. If ai.incidium.net is compromised, every target machine is compromised. The current architecture has no integrity verification.

**Required:**
- The bootstrap script must verify a checksum or digital signature before executing. Options:
  - Embed a SHA256 hash of run.ps1 in the bootstrap script `i` itself
  - Sign the .ps1 scripts with a code signing certificate
  - Use HTTPS with certificate pinning (least preferred, operational burden)
- Without this, the installer is a remote code execution vector

## Blocking Condition 2 — Fallback to USB Must Be Documented and Tested

The proposal says USB is "optional" and "falls back" for machines without internet. This creates an unstated dependency — the installer's mission changes depending on whether the target has network access.

**Required:**
- Define exactly which machines get the USB path and which get the network path
- Document the triage decision: "If target has no internet at Phase 0, use USB for Phase 0 only, then switch to network for Phases 1-5 once SSH is established"
- Test both paths against the VM and document results

## Required Change 1 — Rate Limiting and Concurrent Deployments

1.4GB per machine, 3+ simultaneous deploys at a conference. The VPS has 100GB disk and 8TB monthly bandwidth. 5 machines × 1.4GB = 7GB. Fine. But what about 20 machines during a walkthrough prep?

**Required:**
- Document the maximum simultaneous deployments the VPS can sustain
- Implement a simple rate limiter or queue in the orchestration layer

## Required Change 2 — Resume / Retry Logic

If a download fails at 80% of 1.4GB, does the installer retry or restart from zero?

**Required:**
- Phase scripts must resume partial downloads (curl -C - or equivalent)
- The orchestrator must retry failed phases at least once before marking FAIL

## Required Change 3 — Phase Conversion Must Be a Direct Translation

The existing .bat scripts are the source of truth. The .ps1 versions must be functionally identical, not rewritten with improvements. Improvements belong in a separate change after the network delivery mechanism is validated.

**Required:**
- Each .ps1 phase script must be a direct line-by-line translation of its .bat counterpart
- The ROADMAP already states this correctly — enforce it during implementation

## Required Change 4 — Log Shipping Must Be Best-Effort, Not Blocking

The GAS log shipping should not delay or block phase execution. The VM install should complete correctly even if Google is unreachable.

**Required:**
- Log shipping must be async or fire-and-forget
- Local logs (C:\Argus\) are the source of truth; GAS is a convenience mirror

---

## Summary

| Item | Type | Status |
|------|------|--------|
| Bootstrap integrity verification | **Blocking** | Must implement |
| USB fallback path documented + tested | **Blocking** | Must define |
| Rate limiting / concurrent deployment limits | Required | Must document |
| Resume / retry logic | Required | Must implement |
| .ps1 = direct translation of .bat | Required | Must verify |
| Log shipping non-blocking | Required | Must confirm |
| AAB-PROPOSAL.md already approved | Noted | Carries forward |

**Status:** Conditionally approved.
**Resolve the two blocking conditions, address the four required changes, and proceed with implementation.**