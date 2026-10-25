# Popup sizing matched to Menu

## October 23 follow-up — Fit complete text within the Menu height

The owner requested that popups avoid unnecessary scrollbars and clipped text, with the Menu's height as their maximum. Shared layout now measures wrapped content at its usable width and grows each popup only as needed, up to **660 px** before the existing narrow-window fit (**528 physical pixels** at 360×640). Heading/body/action sizes, padding and the approved Menu remain unchanged. Longer guides and lists retain scrolling within that cap, with their action footer fixed at the bottom and text clear of the scrollbar lane.

The reported **New Run replacement confirmation now shows its complete text without scrolling at all three sizes**. At 450×1000 it still fits within its original 480 px height after correcting the text-width and body allocation. A moderate-content confirmation demonstrates growth from 480 to **584 px** at 450×1000 and **506 px** at 720×1600; save recovery grows to **614 px** at 720×1600. Collection details and reward choices no longer repeat cost/effect text already shown completely on their unchanged cards. Native dialog windows use the final fitted content size; extra development Menu actions scroll while Resume and Options remain fixed.

The [configured-root runner](../tests/popup_consistency_capture.gd) passes **889 checks with zero failures**, covering **68 measured surfaces and 96 tagged screenshots plus a resize capture** at 450×1000, 720×1600 and 360×640. It verifies short confirmations without scrolling, content-driven growth, the height cap, footer placement, scrollbar-safe text widths, native input, resizing, real replacement/retry/recovery flows and byte-identical approved Menu pixels. The three intentional missing-content diagnostics remain; there are no engine errors or warnings. [Results](../output/qa/popup-autofit/results.json), [capture log](../output/qa/popup-autofit/capture.log).

Representative captures: [reported confirmation fixed](../output/qa/popup-autofit/replacement-confirmation-450x1000.png), [Map Guide](../output/qa/popup-autofit/map-guide-450x1000.png), and [reward choices](../output/qa/popup-autofit/rewards-450x1000.png).

Regression checks pass: **1,175 UI**, **118 shell**, **32 Collection lifecycle** and **174 reward integration** assertions, all with zero failures. [UI log](../output/qa/popup-autofit/ui-tests.log), [shell log](../output/qa/popup-autofit/shell-tests.log), [Collection log](../output/qa/popup-autofit/collection-shell.log), [rewards log](../output/qa/popup-autofit/reward-integration.log). RC-027 rewards and RC-028 saved-state transactions retain their existing contracts.

The final resource-only export passes **388 policy/integrity checks, 109 isolated payload-decode checks and 32 Python tests**. `builds/popup-autofit-resources/RuneCast.pck` contains **12,346,204 bytes / 375 entries**, SHA-256 **`4619739f85558f35b474e5056c21cb64a179fe336c2380997061c3ea6c40361a`**. The manifest records all **196** runtime source hashes; none is newer than the audited pack. [Audit](../output/qa/popup-autofit/resources/resource-audit.json), [source manifest](../output/qa/popup-autofit/resources/source-manifest.json), [Python log](../output/qa/popup-autofit/resources/python-tests.log). No Git operations, native mobile build, SDK installation or signing were performed.

## Earlier October 23 sizing pass

October 23, 2026 (Australia/Sydney). The owner requested that every popup use the restored gameplay Menu's text and control sizes. All runtime popup owners now share its display sizing: **22 px headings, 16 px body text, 18 px action labels and 68 px minimum action rows**, with 36/40 px horizontal/vertical panel padding. Settings sliders and editable single-line fields have the same 68 px minimum interaction height. Wrapped labels may make a row taller.

Options, Collection/detail, Rewards, Map Guide/room inspection, shell confirmations/results/save recovery, Combat inspection/Pass and native Guide/error/development dialogs use the same policy. Panel height follows its content; overflowing bodies scroll above fixed actions. The Menu itself remains the approved 402×660 panel at (24,170) in a 450×1000 window, and its opaque interior is pixel-identical to the approved capture.

`Ui.prepare_popup_content` resolves the existing theme fonts after tree attachment, makes sharp popup-local copies, and applies shared typography/control sizes. `Ui.fit_popup_overlay` compensates for the configured game canvas stretch without changing gameplay geometry. Native AcceptDialog windows retain their original buttons, callbacks and input handling inside a scaled content panel. Their first-open bounds are seeded before wrapped text layout. Touch scrolling converts viewport displacement to content coordinates so enlarged panels track the finger correctly.

At 720×1600 and 450×1000, popup text/actions use the sizes above. At a 360×640 window, the existing letterboxed content is 288×640; every popup uses the same 0.8 fit as Menu, giving 54.4 px minimum action rows and 28.8/32 px padding. Shared game artwork, board/cards, navigation geometry, rewards and saved-state transactions retain their existing contracts.

## Render and interaction checks

[Configured-root runner](../tests/popup_consistency_capture.gd): **438 checks, zero failures**, covering **48 measured surfaces and 63 screenshots** across 450×1000, 720×1600 and 360×640. These are actual root-window captures with project stretch enabled. Assertions cover typography, padding, action reachability, native taps/swipes, Options sliders/toggles, Collection/detail return, genuine fixture victory/rewards, Guide/error/local-record windows, and unchanged battle/run state during inspection. The three plain missing-encounter diagnostics intentionally exercise startup errors; there are no unexpected engine errors or warnings. [Results](../output/qa/popup-consistency/results.json), [log](../output/qa/popup-consistency/capture.log).

Representative captures: [Options](../output/qa/popup-consistency/options-450x1000.png), [Combat Guide](../output/qa/popup-consistency/combat-guide-450x1000.png), [narrow rewards](../output/qa/popup-consistency/rewards-scrolled-360x640.png), [narrow collection detail](../output/qa/popup-consistency/collection-detail-360x640.png), and [save recovery](../output/qa/popup-consistency/persistence/recovery-confirmation-450x1000.png).

| Regression suite | Result |
| --- | --- |
| Full UI, including new scaled-drag regression | **1,175 / 0 failures** — [log](../output/qa/popup-consistency/ui-tests.log) |
| Application shell | **118 / 0** — [log](../output/qa/popup-consistency/shell-tests.log) |
| Save/recovery and transaction-failure UI, rendered configured root | **133 / 0** — [log](../output/qa/popup-consistency/persistence-render.log) |
| Collection lifecycle | **32 / 0** — [log](../output/qa/popup-consistency/collection-shell.log) |
| Reward integration | **174 / 0** — [log](../output/qa/popup-consistency/reward-integration.log) |
| Options | **33 / 0** — [log](../output/qa/popup-consistency/options.log) |

## Resource package

Fresh resource-only export with pinned Godot 4.7.2 passes **388 policy/integrity checks, 109 isolated payload-decode checks and 32 Python tests**. `builds/popup-consistency-resources/RuneCast.pck` contains **12,346,188 bytes / 375 entries**, SHA-256 **`eaa4ef863cd9aa12eecbc7d46f60e551a432f6208ad3e52e194d26c00a61746d`**. The manifest records all **196** current runtime source hashes; none is newer than the audited pack. [Audit](../output/qa/popup-consistency/resources/resource-audit.json), [source manifest](../output/qa/popup-consistency/resources/source-manifest.json), [Python log](../output/qa/popup-consistency/resources/python-tests.log).

This follow-up performed no Git operations, native mobile build, SDK installation or signing. Desktop input/render verification does not claim physical-device acceptance.
