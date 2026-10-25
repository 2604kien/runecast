"""Run retained Store/phase/production suites with fresh isolated RC-035 evidence.

The existing runner copies only the output destination of each test. Source
assertions, production data and the ordinary user's save/settings stay intact.
"""
from verify_rc032_regressions import SUITES, main

SUITES.clear()
SUITES.update({
    "store-state": "rc032_store_state_runner",
    "store-shell": "rc032_store_shell_runner",
    "phase-core": "rc033_core_runner",
    "phase-presentation": "rc033_presentation_runner",
    "phase-touch": "rc033_touch_runner",
    "production-content": "rc034_content_runner",
    "production-route": "rc034_route_runner",
    "production-adversarial": "rc034_adversarial_runner",
    "production-guardian": "rc034_guardian_runner",
    "production-presentation": "rc034_presentation_runner",
    "production-shell": "rc034_shell_runner",
})

if __name__ == "__main__":
    raise SystemExit(main())
